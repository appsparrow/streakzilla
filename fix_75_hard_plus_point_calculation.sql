-- =====================================================
-- FIX 75 HARD PLUS POINT CALCULATION
-- =====================================================
-- The issue: Core habits are giving points when they shouldn't in 75 Hard Plus
-- The fix: Update point calculation to use new template system (is_core) instead of template_set
-- =====================================================

-- =====================================================
-- STEP 1: UPDATE CHECK-IN FUNCTION TO USE TEMPLATE SYSTEM
-- =====================================================

-- Drop existing function first
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
    v_user_id UUID;
    v_points INTEGER := 0;
    v_bonus_points INTEGER := 0;
    v_existing_checkin_id UUID;
    v_existing_points INTEGER := 0;
    v_existing_bonus_points INTEGER := 0;
    v_previous_total INTEGER := 0;
    v_current_streak INTEGER;
    v_total_points INTEGER;
    v_hearts_earned INTEGER := 0;
    v_mode TEXT;
    v_streak_mode TEXT;
BEGIN
    v_user_id := auth.uid();
    
    -- Get streak mode and template info
    SELECT s.mode, s.template_id INTO v_streak_mode, v_mode
    FROM sz_streaks s WHERE s.id = p_streak_id;
    
    -- Check if there's already a checkin for this day
    SELECT c.id, c.points_earned INTO v_existing_checkin_id, v_existing_points
    FROM sz_checkins c
    WHERE c.streak_id = p_streak_id 
    AND c.user_id = v_user_id 
    AND c.day_number = p_day_number
    ORDER BY c.created_at DESC
    LIMIT 1;
    
    -- Get previous total points
    SELECT COALESCE(total_points, 0) INTO v_previous_total
    FROM sz_streak_members 
    WHERE streak_id = p_streak_id AND user_id = v_user_id;
    
    -- Calculate total points and bonus points from completed habits
    -- NEW LOGIC: Use template system (is_core) instead of template_set
    IF v_mode IS NOT NULL THEN
        -- Use new template system
        SELECT 
            COALESCE(SUM(
                CASE 
                    WHEN th.is_core = false OR th.is_core IS NULL THEN 
                        COALESCE(th.points_override, h.points, 0)
                    ELSE 0 
                END
            ), 0),
            COALESCE(SUM(
                CASE 
                    WHEN th.is_core = false OR th.is_core IS NULL THEN 
                        COALESCE(th.points_override, h.points, 0)
                    ELSE 0 
                END
            ), 0)
        INTO v_points, v_bonus_points
        FROM sz_habits h
        LEFT JOIN sz_template_habits th ON th.habit_id = h.id AND th.template_id = v_mode
        WHERE h.id = ANY(p_completed_habit_ids);
    ELSE
        -- Fallback to old template_set logic
        SELECT 
            COALESCE(SUM(h.points), 0),
            COALESCE(SUM(CASE 
                WHEN v_streak_mode = '75_hard_plus' AND h.template_set != '75_hard' THEN h.points 
                WHEN v_streak_mode != '75_hard_plus' THEN h.points
                ELSE 0 
            END), 0)
        INTO v_points, v_bonus_points
        FROM sz_habits h
        WHERE h.id = ANY(p_completed_habit_ids);
    END IF;
    
    -- Add progress photo bonus points for Hard Plus mode
    IF v_streak_mode = '75_hard_plus' AND p_photo_url IS NOT NULL THEN
        v_points := v_points + 5;
        v_bonus_points := v_bonus_points + 5;
    END IF;
    
    -- Get existing bonus points if updating
    IF v_existing_checkin_id IS NOT NULL THEN
        IF v_mode IS NOT NULL THEN
            -- Use new template system for existing checkin
            SELECT COALESCE(SUM(
                CASE 
                    WHEN th.is_core = false OR th.is_core IS NULL THEN 
                        COALESCE(th.points_override, h.points, 0)
                    ELSE 0 
                END
            ), 0)
            INTO v_existing_bonus_points
            FROM sz_habits h
            LEFT JOIN sz_template_habits th ON th.habit_id = h.id AND th.template_id = v_mode
            INNER JOIN sz_checkins c ON c.id = v_existing_checkin_id
            INNER JOIN unnest(c.completed_habit_ids) AS habit_id ON habit_id = h.id;
        ELSE
            -- Fallback to old logic
            SELECT COALESCE(SUM(CASE 
                WHEN v_streak_mode = '75_hard_plus' AND h.template_set != '75_hard' THEN h.points 
                WHEN v_streak_mode != '75_hard_plus' THEN h.points
                ELSE 0 
            END), 0)
            INTO v_existing_bonus_points
            FROM sz_habits h, sz_checkins c, unnest(c.completed_habit_ids) AS habit_id
            WHERE c.id = v_existing_checkin_id AND h.id = habit_id;
        END IF;
        
        -- Add existing photo bonus if applicable
        IF v_existing_checkin_id IS NOT NULL AND EXISTS(
            SELECT 1 FROM sz_checkins WHERE id = v_existing_checkin_id AND photo_url IS NOT NULL
        ) AND v_streak_mode = '75_hard_plus' THEN
            v_existing_bonus_points := v_existing_bonus_points + 5;
        END IF;
    END IF;

    IF v_existing_checkin_id IS NOT NULL THEN
        -- Update existing checkin
        UPDATE sz_checkins
        SET 
            completed_habit_ids = p_completed_habit_ids,
            points_earned = v_points,
            note = p_note,
            photo_url = p_photo_url,
            created_at = now()
        WHERE id = v_existing_checkin_id;
        
        -- Update user's total points (subtract old bonus, add new bonus)
        UPDATE sz_streak_members
        SET total_points = total_points - v_existing_bonus_points + v_bonus_points
        WHERE streak_id = p_streak_id AND user_id = v_user_id
        RETURNING current_streak, total_points INTO v_current_streak, v_total_points;
    ELSE
        -- First checkin of the day - increment streak
        UPDATE sz_streak_members
        SET 
            total_points = total_points + v_points,
            current_streak = current_streak + 1
        WHERE streak_id = p_streak_id AND user_id = v_user_id
        RETURNING current_streak, total_points INTO v_current_streak, v_total_points;
    END IF;

    -- Calculate hearts earned for 75_hard modes
    IF v_streak_mode IN ('75_hard', '75_hard_plus') THEN
        -- Base points per day for 75 hard (0 points for core habits in plus mode)
        DECLARE
            v_base_points_per_day INTEGER := CASE WHEN v_streak_mode = '75_hard_plus' THEN 0 ELSE 55 END;
            v_expected_base_points INTEGER;
            v_previous_extra_points INTEGER;
            v_current_extra_points INTEGER;
            v_previous_hearts INTEGER;
            v_current_hearts INTEGER;
        BEGIN
            v_expected_base_points := v_base_points_per_day * p_day_number;
            
            -- Calculate extra points before and after this checkin
            v_previous_extra_points := GREATEST(0, v_previous_total - (v_base_points_per_day * (p_day_number - 1)));
            v_current_extra_points := GREATEST(0, v_total_points - v_expected_base_points);
            
            -- Calculate hearts (1 per 500 extra points, max 3)
            v_previous_hearts := LEAST(3, v_previous_extra_points / 500);
            v_current_hearts := LEAST(3, v_current_extra_points / 500);
            
            v_hearts_earned := v_current_hearts - v_previous_hearts;
            
            -- Update lives if hearts were earned
            IF v_hearts_earned > 0 THEN
                UPDATE sz_streak_members
                SET lives_remaining = LEAST(lives_remaining + v_hearts_earned, lives_remaining + 3)
                WHERE streak_id = p_streak_id AND user_id = v_user_id;
            END IF;
        END;
    END IF;

    RETURN QUERY
    SELECT v_points as points_earned, v_current_streak as current_streak, v_total_points as total_points, v_hearts_earned as hearts_earned;
END;
$function$;

-- =====================================================
-- STEP 2: UPDATE RECALCULATION FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION public.sz_recalculate_user_points(p_streak_id UUID, p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_total_points INTEGER := 0;
    v_bonus_points INTEGER := 0;
    v_streak_mode TEXT;
    v_template_id UUID;
    checkin_record RECORD;
    checkin_points INTEGER;
    checkin_bonus INTEGER;
BEGIN
    -- Get streak mode and template
    SELECT s.mode, s.template_id INTO v_streak_mode, v_template_id 
    FROM sz_streaks s WHERE s.id = p_streak_id;
    
    -- Recalculate points from all checkins
    FOR checkin_record IN 
        SELECT c.completed_habit_ids, c.photo_url
        FROM sz_checkins c
        WHERE c.streak_id = p_streak_id AND c.user_id = p_user_id
    LOOP
        -- Initialize points for this checkin
        checkin_points := 0;
        checkin_bonus := 0;
        
        -- Calculate points for this checkin based on current user habits
        -- NEW LOGIC: Use template system (is_core) instead of template_set
        IF v_template_id IS NOT NULL THEN
            -- Use new template system
            SELECT 
                COALESCE(SUM(
                    CASE 
                        WHEN th.is_core = false OR th.is_core IS NULL THEN 
                            COALESCE(th.points_override, h.points, 0)
                        ELSE 0 
                    END
                ), 0),
                COALESCE(SUM(
                    CASE 
                        WHEN th.is_core = false OR th.is_core IS NULL THEN 
                            COALESCE(th.points_override, h.points, 0)
                        ELSE 0 
                    END
                ), 0)
            INTO checkin_points, checkin_bonus
            FROM sz_habits h
            LEFT JOIN sz_template_habits th ON th.habit_id = h.id AND th.template_id = v_template_id
            INNER JOIN sz_user_habits uh ON uh.habit_id = h.id
            INNER JOIN unnest(checkin_record.completed_habit_ids) AS completed_habit(habit_id) ON completed_habit.habit_id = h.id
            WHERE uh.streak_id = p_streak_id 
            AND uh.user_id = p_user_id;
        ELSE
            -- Fallback to old template_set logic
            SELECT 
                COALESCE(SUM(h.points), 0),
                COALESCE(SUM(CASE 
                    WHEN v_streak_mode = '75_hard_plus' AND h.template_set != '75_hard' THEN h.points 
                    WHEN v_streak_mode != '75_hard_plus' THEN h.points
                    ELSE 0 
                END), 0)
            INTO checkin_points, checkin_bonus
            FROM sz_habits h
            INNER JOIN sz_user_habits uh ON uh.habit_id = h.id
            INNER JOIN unnest(checkin_record.completed_habit_ids) AS completed_habit(habit_id) ON completed_habit.habit_id = h.id
            WHERE uh.streak_id = p_streak_id 
            AND uh.user_id = p_user_id;
        END IF;
        
        -- Add progress photo bonus points for Hard Plus mode
        IF v_streak_mode = '75_hard_plus' AND checkin_record.photo_url IS NOT NULL THEN
            checkin_points := checkin_points + 5;
            checkin_bonus := checkin_bonus + 5;
        END IF;
        
        -- Add to totals
        v_total_points := v_total_points + checkin_points;
        v_bonus_points := v_bonus_points + checkin_bonus;
    END LOOP;
    
    -- Update user's total points and bonus points
    UPDATE sz_streak_members
    SET 
        total_points = v_total_points,
        bonus_points = v_bonus_points
    WHERE streak_id = p_streak_id AND user_id = p_user_id;
END;
$function$;

-- =====================================================
-- STEP 3: RECALCULATE POINTS FOR EXISTING 75 HARD PLUS STREAKS
-- =====================================================

-- Recalculate points for all 75 Hard Plus streaks
DO $$
DECLARE
    streak_record RECORD;
    user_record RECORD;
BEGIN
    FOR streak_record IN 
        SELECT id, name FROM sz_streaks WHERE mode = '75_hard_plus'
    LOOP
        FOR user_record IN 
            SELECT user_id FROM sz_streak_members WHERE streak_id = streak_record.id
        LOOP
            PERFORM public.sz_recalculate_user_points(streak_record.id, user_record.user_id);
            RAISE NOTICE 'Recalculated points for user % in streak %', user_record.user_id, streak_record.name;
        END LOOP;
    END LOOP;
END $$;

-- =====================================================
-- STEP 4: VERIFICATION
-- =====================================================

-- Check the fix
SELECT 
    'POINT CALCULATION FIX APPLIED' as section,
    'Core habits should now give 0 points in 75 Hard Plus' as message;

-- Check updated points
SELECT 
    'UPDATED STREAK MEMBER POINTS' as section,
    s.name as streak_name,
    u.email,
    sm.total_points,
    sm.current_streak,
    s.mode
FROM public.sz_streak_members sm
JOIN public.sz_streaks s ON sm.streak_id = s.id
JOIN auth.users u ON sm.user_id = u.id
WHERE s.mode = '75_hard_plus'
ORDER BY s.name, sm.total_points DESC;

-- Check template mappings
SELECT 
    '75 HARD PLUS TEMPLATE MAPPINGS' as section,
    h.title as habit_title,
    th.is_core,
    th.points_override,
    h.points as default_points,
    CASE 
        WHEN th.is_core = true THEN 'NO POINTS (Core)'
        WHEN th.is_core = false THEN 'POINTS (Bonus)'
        ELSE 'POINTS (Unknown)'
    END as point_status
FROM public.sz_template_habits th
JOIN public.sz_templates t ON th.template_id = t.id
JOIN public.sz_habits h ON th.habit_id = h.id
WHERE t.key = '75_hard_plus'
ORDER BY th.sort_order, h.title;
