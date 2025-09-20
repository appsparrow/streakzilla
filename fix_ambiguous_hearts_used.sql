-- Fix ambiguous hearts_used column reference in sz_checkin function
-- This fixes the error: column reference "hearts_used" is ambiguous

DROP FUNCTION IF EXISTS public.sz_checkin(uuid, integer, uuid[], text, text);

CREATE OR REPLACE FUNCTION public.sz_checkin(
    p_streak_id uuid,
    p_day_number integer,
    p_completed_habit_ids uuid[],
    p_note text DEFAULT NULL,
    p_photo_url text DEFAULT NULL
)
RETURNS TABLE(points_earned integer, current_streak integer, total_points integer, hearts_used boolean, hearts_used_count integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_user_id UUID;
    v_points INTEGER := 0;
    v_current_streak INTEGER;
    v_total_points INTEGER;
    v_previous_total INTEGER;
    v_hearts_earned INTEGER := 0;
    v_mode TEXT;
    v_existing_checkin BOOLEAN := FALSE;
    v_hearts_used BOOLEAN := FALSE;
    v_hearts_used_count INTEGER := 0;
    v_points_to_hearts_enabled BOOLEAN;
    v_hearts_per_100_points INTEGER;
BEGIN
    v_user_id := auth.uid();
    
    -- Get streak mode and heart settings
    SELECT mode, points_to_hearts_enabled, hearts_per_100_points 
    INTO v_mode, v_points_to_hearts_enabled, v_hearts_per_100_points
    FROM sz_streaks WHERE id = p_streak_id;
    
    -- Get previous total points
    SELECT total_points INTO v_previous_total
    FROM sz_streak_members
    WHERE streak_id = p_streak_id AND user_id = v_user_id;
    
    -- Check if user already checked in today
    SELECT EXISTS(
        SELECT 1 FROM sz_checkins 
        WHERE streak_id = p_streak_id AND user_id = v_user_id AND day_number = p_day_number
    ) INTO v_existing_checkin;
    
    -- Calculate points from completed habits
    SELECT COALESCE(SUM(h.points), 0)
    INTO v_points
    FROM sz_habits h
    WHERE h.id = ANY(p_completed_habit_ids);

    -- Create checkin record (allow multiple per day for bonus habits)
    INSERT INTO sz_checkins (
        streak_id,
        user_id,
        day_number,
        completed_habit_ids,
        points_earned,
        note,
        photo_url
    ) VALUES (
        p_streak_id,
        v_user_id,
        p_day_number,
        p_completed_habit_ids,
        v_points,
        p_note,
        p_photo_url
    );

    -- Update user's points and streak (only increment streak on first checkin of the day)
    IF v_existing_checkin THEN
        -- Just add points for bonus habits
        UPDATE sz_streak_members
        SET total_points = total_points + v_points
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
        
        -- Automatically protect streak by using hearts for missed days
        SELECT public.sz_auto_protect_streak_on_checkin(p_streak_id, v_user_id, p_day_number) INTO v_hearts_used;
        IF v_hearts_used THEN
            v_hearts_used_count := 1; -- We used hearts to protect the streak
        END IF;
    END IF;

    -- Calculate hearts earned from points (if enabled)
    IF v_points_to_hearts_enabled THEN
        v_hearts_earned := (v_total_points / 100) * v_hearts_per_100_points;
        
        -- Update hearts_earned and hearts_available
        -- FIXED: Use table alias to avoid ambiguous column reference
        UPDATE sz_streak_members AS sm
        SET 
            hearts_earned = v_hearts_earned,
            hearts_available = GREATEST(0, v_hearts_earned - sm.hearts_used)
        WHERE sm.streak_id = p_streak_id AND sm.user_id = v_user_id;
    END IF;

    RETURN QUERY
    SELECT v_points as points_earned, v_current_streak as current_streak, v_total_points as total_points, v_hearts_used as hearts_used, v_hearts_used_count as hearts_used_count;
END;
$function$;
