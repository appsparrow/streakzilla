-- Fix ambiguous current_streak column reference
-- This addresses the error: column reference "current_streak" is ambiguous

-- Drop the existing function first
DROP FUNCTION IF EXISTS public.sz_checkin(uuid, integer, uuid[], text, text);

-- Create the function with explicit table aliases to avoid ambiguous column references
CREATE OR REPLACE FUNCTION public.sz_checkin(
    p_streak_id uuid,
    p_day_number integer,
    p_completed_habit_ids uuid[],
    p_note text DEFAULT NULL,
    p_photo_url text DEFAULT NULL
)
RETURNS TABLE(points_earned integer, current_streak integer, total_points integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_user_id UUID;
    v_points INTEGER := 0;
    v_current_streak INTEGER;
    v_total_points INTEGER;
BEGIN
    v_user_id := auth.uid();
    
    -- Calculate points from completed habits
    SELECT COALESCE(SUM(h.points), 0)
    INTO v_points
    FROM sz_habits h
    WHERE h.id = ANY(p_completed_habit_ids);

    -- Create checkin record
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

    -- Update user's points and streak with explicit table alias
    UPDATE sz_streak_members AS sm
    SET 
        total_points = sm.total_points + v_points,
        current_streak = sm.current_streak + 1
    WHERE sm.streak_id = p_streak_id AND sm.user_id = v_user_id
    RETURNING sm.current_streak, sm.total_points INTO v_current_streak, v_total_points;

    RETURN QUERY
    SELECT v_points as points_earned, v_current_streak as current_streak, v_total_points as total_points;
END;
$function$;
