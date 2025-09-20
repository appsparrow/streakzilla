-- Function to recalculate user points when habits are changed
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
BEGIN
    -- Get streak mode
    SELECT mode INTO v_streak_mode FROM sz_streaks WHERE id = p_streak_id;
    
    -- Recalculate points from all checkins
    FOR checkin_record IN 
        SELECT c.completed_habit_ids, c.photo_url
        FROM sz_checkins c
        WHERE c.streak_id = p_streak_id AND c.user_id = p_user_id
    LOOP
        -- Calculate points for this checkin based on current user habits
        SELECT 
            COALESCE(SUM(h.points), 0),
            COALESCE(SUM(CASE 
                WHEN v_streak_mode = '75_hard_plus' AND h.template_set != '75_hard' THEN h.points 
                WHEN v_streak_mode != '75_hard_plus' THEN h.points
                ELSE 0 
            END), 0)
        INTO v_total_points, v_bonus_points
        FROM sz_habits h, sz_user_habits uh, unnest(checkin_record.completed_habit_ids) AS habit_id
        WHERE h.id = habit_id 
        AND uh.streak_id = p_streak_id 
        AND uh.user_id = p_user_id 
        AND uh.habit_id = h.id;
        
        -- Add progress photo bonus points for Hard Plus mode
        IF v_streak_mode = '75_hard_plus' AND checkin_record.photo_url IS NOT NULL THEN
            v_total_points := v_total_points + 5;
            v_bonus_points := v_bonus_points + 5;
        END IF;
    END LOOP;
    
    -- Update user's total points and bonus points
    UPDATE sz_streak_members
    SET 
        total_points = v_total_points,
        bonus_points = v_bonus_points
    WHERE streak_id = p_streak_id AND user_id = p_user_id;
END;
$function$;

-- Function to check if habit modifications are allowed (not frozen after 3 days)
CREATE OR REPLACE FUNCTION public.sz_can_modify_habits(p_streak_id uuid, p_user_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_start_date DATE;
    v_days_since_start INTEGER;
BEGIN
    -- Get streak start date
    SELECT start_date INTO v_start_date 
    FROM sz_streaks 
    WHERE id = p_streak_id;
    
    -- Calculate days since start
    v_days_since_start := CURRENT_DATE - v_start_date + 1;
    
    -- Allow modifications only in first 3 days
    RETURN v_days_since_start <= 3;
END;
$function$;

-- Update the sz_save_user_habits function to include point recalculation and freeze check
CREATE OR REPLACE FUNCTION public.sz_save_user_habits(p_streak_id uuid, p_habit_ids uuid[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_user_id UUID;
    v_can_modify BOOLEAN;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Check if user is a member of the streak
    IF NOT EXISTS(
        SELECT 1 FROM sz_streak_members 
        WHERE streak_id = p_streak_id AND user_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'User is not a member of this streak';
    END IF;
    
    -- Check if habit modifications are allowed (freeze after 3 days)
    SELECT sz_can_modify_habits(p_streak_id, v_user_id) INTO v_can_modify;
    
    IF NOT v_can_modify THEN
        RAISE EXCEPTION 'Habit modifications are frozen after 3 days from streak start';
    END IF;

    -- Delete existing user habits for this streak
    DELETE FROM sz_user_habits 
    WHERE streak_id = p_streak_id AND user_id = v_user_id;

    -- Insert new user habits
    INSERT INTO sz_user_habits (streak_id, user_id, habit_id)
    SELECT p_streak_id, v_user_id, unnest(p_habit_ids);
    
    -- Recalculate user's points based on new habit selection
    PERFORM sz_recalculate_user_points(p_streak_id, v_user_id);
END;
$function$;