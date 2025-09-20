-- Add bonus_points column to track bonus points separately from total points
ALTER TABLE sz_streak_members ADD COLUMN bonus_points INTEGER DEFAULT 0;

-- Update the sz_checkin function to handle bonus points tracking
CREATE OR REPLACE FUNCTION public.sz_checkin(p_streak_id uuid, p_day_number integer, p_completed_habit_ids uuid[], p_note text DEFAULT NULL::text, p_photo_url text DEFAULT NULL::text)
 RETURNS TABLE(points_earned integer, current_streak integer, total_points integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_user_id UUID;
    v_points INTEGER := 0;
    v_bonus_points INTEGER := 0;
    v_current_streak INTEGER;
    v_total_points INTEGER;
    v_existing_checkin_id UUID;
    v_existing_points INTEGER := 0;
    v_existing_bonus_points INTEGER := 0;
    v_streak_mode TEXT;
BEGIN
    v_user_id := auth.uid();
    
    -- Get streak mode
    SELECT mode INTO v_streak_mode FROM sz_streaks WHERE id = p_streak_id;
    
    -- Check if there's already a checkin for this day
    SELECT c.id, c.points_earned INTO v_existing_checkin_id, v_existing_points
    FROM sz_checkins c
    WHERE c.streak_id = p_streak_id 
    AND c.user_id = v_user_id 
    AND c.day_number = p_day_number
    ORDER BY c.created_at DESC
    LIMIT 1;
    
    -- Calculate total points and bonus points from completed habits
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
    
    -- Add progress photo bonus points for Hard Plus mode
    IF v_streak_mode = '75_hard_plus' AND p_photo_url IS NOT NULL THEN
        v_points := v_points + 5;
        v_bonus_points := v_bonus_points + 5;
    END IF;
    
    -- Get existing bonus points if updating
    IF v_existing_checkin_id IS NOT NULL THEN
        SELECT COALESCE(SUM(CASE 
            WHEN v_streak_mode = '75_hard_plus' AND h.template_set != '75_hard' THEN h.points 
            WHEN v_streak_mode != '75_hard_plus' THEN h.points
            ELSE 0 
        END), 0)
        INTO v_existing_bonus_points
        FROM sz_habits h, sz_checkins c, unnest(c.completed_habit_ids) AS habit_id
        WHERE c.id = v_existing_checkin_id AND h.id = habit_id;
        
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
            note = COALESCE(p_note, sz_checkins.note),
            photo_url = COALESCE(p_photo_url, sz_checkins.photo_url),
            created_at = now()
        WHERE id = v_existing_checkin_id;
        
        -- Update user's total points and bonus points
        UPDATE sz_streak_members AS sm
        SET 
            total_points = sm.total_points - v_existing_points + v_points,
            bonus_points = sm.bonus_points - v_existing_bonus_points + v_bonus_points
        WHERE sm.streak_id = p_streak_id AND sm.user_id = v_user_id
        RETURNING sm.current_streak, sm.total_points INTO v_current_streak, v_total_points;
    ELSE
        -- Create new checkin record
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

        -- Update user's points, bonus_points and streak
        UPDATE sz_streak_members AS sm
        SET 
            total_points = sm.total_points + v_points,
            bonus_points = sm.bonus_points + v_bonus_points,
            current_streak = sm.current_streak + 1
        WHERE sm.streak_id = p_streak_id AND sm.user_id = v_user_id
        RETURNING sm.current_streak, sm.total_points INTO v_current_streak, v_total_points;
    END IF;

    RETURN QUERY
    SELECT v_points as points_earned, v_current_streak as current_streak, v_total_points as total_points;
END;
$function$;