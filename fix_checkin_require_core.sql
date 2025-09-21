-- =====================================================
-- CHECK-IN FUNCTION: REQUIRE ALL CORE FOR STREAK, UNION COMPLETIONS, INSERT WHEN MISSING
-- =====================================================

DROP FUNCTION IF EXISTS public.sz_checkin(UUID, INTEGER, UUID[], TEXT, TEXT);

CREATE OR REPLACE FUNCTION public.sz_checkin(
    p_streak_id UUID,
    p_day_number INTEGER,
    p_completed_habit_ids UUID[],
    p_note TEXT DEFAULT NULL,
    p_photo_url TEXT DEFAULT NULL
)
RETURNS TABLE(points_earned INTEGER, current_streak INTEGER, total_points INTEGER, hearts_earned INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_user_id UUID := auth.uid();
    v_streak_mode TEXT;
    v_template_id UUID;
    v_existing_checkin_id UUID;
    v_existing_completed UUID[] := ARRAY[]::UUID[];
    v_existing_points INTEGER := 0;
    v_new_completed UUID[] := ARRAY[]::UUID[];
    v_core_habit_ids UUID[] := ARRAY[]::UUID[];
    v_all_core_done_before BOOLEAN := FALSE;
    v_all_core_done_now BOOLEAN := FALSE;
    v_points INTEGER := 0;
    v_bonus_points INTEGER := 0;
    v_prev_total INTEGER := 0;
    v_curr_streak INTEGER := 0;
    v_total_points INTEGER := 0;
    v_hearts_earned INTEGER := 0;
BEGIN
    -- Streak info
    SELECT s.mode, s.template_id INTO v_streak_mode, v_template_id
    FROM sz_streaks s WHERE s.id = p_streak_id;

    -- Existing checkin for this user/day
    SELECT c.id, c.completed_habit_ids, COALESCE(c.points_earned,0)
    INTO v_existing_checkin_id, v_existing_completed, v_existing_points
    FROM sz_checkins c
    WHERE c.streak_id = p_streak_id AND c.user_id = v_user_id AND c.day_number = p_day_number
    ORDER BY c.created_at DESC LIMIT 1;

    -- Core habit ids for template (if any)
    IF v_template_id IS NOT NULL THEN
        SELECT COALESCE(array_agg(th.habit_id), ARRAY[]::UUID[])
        INTO v_core_habit_ids
        FROM sz_template_habits th
        WHERE th.template_id = v_template_id AND th.is_core = TRUE;
    ELSE
        v_core_habit_ids := ARRAY[]::UUID[];
    END IF;

    -- Determine completion set (UNION existing + new)
    v_new_completed := (
        SELECT COALESCE(array_agg(DISTINCT x.hid), ARRAY[]::UUID[])
        FROM (
            SELECT UNNEST(COALESCE(v_existing_completed, ARRAY[]::UUID[])) AS hid
            UNION
            SELECT UNNEST(COALESCE(p_completed_habit_ids, ARRAY[]::UUID[])) AS hid
        ) x
    );

    -- Core completion status (before and now)
    v_all_core_done_before := (
        SELECT COALESCE(
            (SELECT bool_and(hid = ANY(v_existing_completed)) FROM UNNEST(v_core_habit_ids) AS hid),
            FALSE
        )
    );

    v_all_core_done_now := (
        SELECT COALESCE(
            (SELECT bool_and(hid = ANY(v_new_completed)) FROM UNNEST(v_core_habit_ids) AS hid),
            FALSE
        )
    );

    -- Calculate points for v_new_completed
    IF v_template_id IS NOT NULL THEN
        SELECT 
            COALESCE(SUM(CASE WHEN th.is_core = FALSE OR th.is_core IS NULL THEN COALESCE(th.points_override, h.points, 0) ELSE 0 END), 0)
        INTO v_points
        FROM sz_habits h
        LEFT JOIN sz_template_habits th ON th.habit_id = h.id AND th.template_id = v_template_id
        WHERE h.id = ANY(v_new_completed);
    ELSE
        SELECT COALESCE(SUM(h.points), 0) INTO v_points
        FROM sz_habits h WHERE h.id = ANY(v_new_completed);
    END IF;

    -- Photo bonus for hard plus
    IF v_streak_mode = '75_hard_plus' AND p_photo_url IS NOT NULL THEN
        v_points := v_points + 5;
    END IF;

    -- Member previous totals
    SELECT COALESCE(sm.total_points,0), COALESCE(sm.current_streak,0)
    INTO v_prev_total, v_curr_streak
    FROM sz_streak_members sm
    WHERE sm.streak_id = p_streak_id AND sm.user_id = v_user_id;

    -- Insert or update checkin
    IF v_existing_checkin_id IS NULL THEN
        INSERT INTO sz_checkins (id, user_id, streak_id, day_number, completed_habit_ids, points_earned, note, photo_url, created_at)
        VALUES (gen_random_uuid(), v_user_id, p_streak_id, p_day_number, v_new_completed, v_points, p_note, p_photo_url, now())
        RETURNING id INTO v_existing_checkin_id;

        -- Update totals
        UPDATE sz_streak_members
        SET total_points = sz_streak_members.total_points + v_points,
            current_streak = sz_streak_members.current_streak + (CASE WHEN v_all_core_done_now THEN 1 ELSE 0 END)
        WHERE streak_id = p_streak_id AND user_id = v_user_id
        RETURNING sz_streak_members.current_streak, sz_streak_members.total_points INTO v_curr_streak, v_total_points;
    ELSE
        UPDATE sz_checkins
        SET completed_habit_ids = v_new_completed,
            points_earned = v_points,
            note = p_note,
            photo_url = p_photo_url,
            created_at = now()
        WHERE id = v_existing_checkin_id;

        -- Only add delta points; streak increments when changing from not-all-core to all-core
        UPDATE sz_streak_members
        SET total_points = sz_streak_members.total_points + (v_points - v_existing_points),
            current_streak = sz_streak_members.current_streak + (CASE WHEN v_all_core_done_now AND NOT v_all_core_done_before THEN 1 ELSE 0 END)
        WHERE streak_id = p_streak_id AND user_id = v_user_id
        RETURNING sz_streak_members.current_streak, sz_streak_members.total_points INTO v_curr_streak, v_total_points;
    END IF;

    -- Hearts calculation (simple: 1 per 100 bonus points; only for hard_plus)
    IF v_streak_mode = '75_hard_plus' THEN
        v_hearts_earned := GREATEST(0, (v_total_points / 100) - ((v_prev_total) / 100));
        IF v_hearts_earned > 0 THEN
            UPDATE sz_streak_members
            SET lives_remaining = LEAST(lives_remaining + v_hearts_earned, lives_remaining + 3)
            WHERE streak_id = p_streak_id AND user_id = v_user_id;
        END IF;
    END IF;

    RETURN QUERY SELECT v_points, v_curr_streak, v_total_points, v_hearts_earned;
END;
$function$;

SELECT 'Check-in function updated: unions completions, inserts when missing, increments streak only when all core done' AS status;


