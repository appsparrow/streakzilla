-- Fix auto heart function to match frontend expectations
-- This migration creates the sz_auto_use_heart_on_miss function that the frontend is calling

-- Create the function that the frontend is expecting
CREATE OR REPLACE FUNCTION public.sz_auto_use_heart_on_miss(
    p_day_number integer,
    p_streak_id uuid,
    p_user_id uuid
)
RETURNS TABLE(success boolean, hearts_remaining integer, message text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_hearts_available INTEGER;
    v_points_to_hearts_enabled BOOLEAN;
    v_has_checkin BOOLEAN;
BEGIN
    -- Check if points-to-hearts is enabled for this streak
    SELECT points_to_hearts_enabled 
    INTO v_points_to_hearts_enabled
    FROM sz_streaks 
    WHERE id = p_streak_id;
    
    -- If heart system is disabled, return failure
    IF NOT v_points_to_hearts_enabled THEN
        RETURN QUERY SELECT FALSE, 0, 'Heart system is disabled for this streak'::text;
        RETURN;
    END IF;
    
    -- Get current hearts available
    SELECT hearts_available 
    INTO v_hearts_available
    FROM sz_streak_members
    WHERE streak_id = p_streak_id AND user_id = p_user_id;
    
    -- Check if user already has a checkin for this day
    SELECT EXISTS(
        SELECT 1 FROM sz_checkins 
        WHERE streak_id = p_streak_id 
        AND user_id = p_user_id 
        AND day_number = p_day_number
    ) INTO v_has_checkin;
    
    -- If user already checked in, no need to use heart
    IF v_has_checkin THEN
        RETURN QUERY SELECT FALSE, v_hearts_available, 'Already checked in for this day'::text;
        RETURN;
    END IF;
    
    -- If no hearts available, return failure
    IF v_hearts_available <= 0 THEN
        RETURN QUERY SELECT FALSE, 0, 'No hearts available to protect streak'::text;
        RETURN;
    END IF;
    
    -- Use one heart to protect the streak
    UPDATE sz_streak_members
    SET 
        hearts_used = hearts_used + 1,
        hearts_available = hearts_available - 1
    WHERE streak_id = p_streak_id AND user_id = p_user_id;
    
    -- Record the transaction
    INSERT INTO sz_hearts_transactions (
        streak_id, from_user_id, to_user_id, hearts_amount, 
        transaction_type, day_number, note
    ) VALUES (
        p_streak_id, p_user_id, p_user_id, 1,
        'auto_use', p_day_number, 'Manually used heart to protect streak'
    );
    
    -- Return success with remaining hearts
    RETURN QUERY SELECT TRUE, (v_hearts_available - 1), 'Heart used successfully to protect streak'::text;
END;
$function$;

-- Create a function to automatically check and use hearts when user checks in
-- This will be called automatically when a user checks in
CREATE OR REPLACE FUNCTION public.sz_auto_protect_streak_on_checkin(
    p_streak_id uuid,
    p_user_id uuid,
    p_day_number integer
)
RETURNS BOOLEAN AS $$
DECLARE
    v_current_day INTEGER;
    v_start_date DATE;
    v_points_to_hearts_enabled BOOLEAN;
    v_hearts_available INTEGER;
    v_day_to_check INTEGER;
    v_has_checkin BOOLEAN;
    v_hearts_used_count INTEGER := 0;
BEGIN
    -- Get streak info
    SELECT start_date, points_to_hearts_enabled 
    INTO v_start_date, v_points_to_hearts_enabled
    FROM sz_streaks WHERE id = p_streak_id;
    
    -- Only check if points-to-hearts is enabled
    IF NOT v_points_to_hearts_enabled THEN
        RETURN FALSE;
    END IF;
    
    -- Get current hearts available
    SELECT hearts_available INTO v_hearts_available
    FROM sz_streak_members
    WHERE streak_id = p_streak_id AND user_id = p_user_id;
    
    -- Check each day from yesterday backwards until we find a missed day or run out of hearts
    FOR v_day_to_check IN (p_day_number - 1)..1 LOOP
        -- Skip if we've already checked this day
        IF v_day_to_check >= p_day_number THEN
            CONTINUE;
        END IF;
        
        -- Check if user has a checkin for this day
        SELECT EXISTS(
            SELECT 1 FROM sz_checkins 
            WHERE streak_id = p_streak_id 
            AND user_id = p_user_id 
            AND day_number = v_day_to_check
        ) INTO v_has_checkin;
        
        -- If no checkin and we have hearts available, use a heart
        IF NOT v_has_checkin AND v_hearts_available > 0 THEN
            -- Use one heart
            UPDATE sz_streak_members
            SET 
                hearts_used = hearts_used + 1,
                hearts_available = hearts_available - 1
            WHERE streak_id = p_streak_id AND user_id = p_user_id;
            
            -- Record the transaction
            INSERT INTO sz_hearts_transactions (
                streak_id, from_user_id, to_user_id, hearts_amount, 
                transaction_type, day_number, note
            ) VALUES (
                p_streak_id, p_user_id, p_user_id, 1,
                'auto_use', v_day_to_check, 'Automatically used heart to protect streak'
            );
            
            v_hearts_available := v_hearts_available - 1;
            v_hearts_used_count := v_hearts_used_count + 1;
        END IF;
        
        -- If we've used all hearts, break
        IF v_hearts_available <= 0 THEN
            EXIT;
        END IF;
    END LOOP;
    
    RETURN v_hearts_used_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update the checkin function to automatically protect streaks
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
        UPDATE sz_streak_members
        SET 
            hearts_earned = v_hearts_earned,
            hearts_available = GREATEST(0, v_hearts_earned - hearts_used)
        WHERE streak_id = p_streak_id AND user_id = v_user_id;
    END IF;

    RETURN QUERY
    SELECT v_points as points_earned, v_current_streak as current_streak, v_total_points as total_points, v_hearts_used as hearts_used, v_hearts_used_count as hearts_used_count;
END;
$function$;
