-- Fix the ambiguous column reference in sz_recalculate_user_points function
CREATE OR REPLACE FUNCTION public.sz_recalculate_user_points(p_streak_id uuid, p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_total_points INTEGER := 0;
    v_bonus_points INTEGER := 0;
    v_streak_mode TEXT;
    checkin_record RECORD;
    checkin_points INTEGER;
    checkin_bonus INTEGER;
BEGIN
    -- Get streak mode
    SELECT mode INTO v_streak_mode FROM sz_streaks WHERE id = p_streak_id;
    
    -- Reset totals
    v_total_points := 0;
    v_bonus_points := 0;
    
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
        -- Only include habits that the user currently has selected
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