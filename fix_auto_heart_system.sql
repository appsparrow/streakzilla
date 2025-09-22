-- Fix Automatic Heart Application System
-- This script ensures hearts are automatically used when users miss check-ins

-- First, let's ensure the heart system is properly set up for all streaks
UPDATE sz_streaks 
SET 
    points_to_hearts_enabled = true,
    hearts_per_100_points = 1
WHERE points_to_hearts_enabled IS NULL OR hearts_per_100_points IS NULL;

-- Create a comprehensive function to check and apply hearts for missed days
CREATE OR REPLACE FUNCTION public.sz_auto_apply_hearts_for_missed_days(
    p_streak_id uuid,
    p_user_id uuid
)
RETURNS TABLE(
    days_checked integer,
    hearts_used integer,
    message text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_streak_info RECORD;
    v_membership_info RECORD;
    v_current_day INTEGER;
    v_day_to_check INTEGER;
    v_has_checkin BOOLEAN;
    v_hearts_used_count INTEGER := 0;
    v_days_checked_count INTEGER := 0;
    v_points_to_hearts_enabled BOOLEAN;
BEGIN
    -- Get streak information
    SELECT 
        start_date,
        points_to_hearts_enabled,
        hearts_per_100_points
    INTO v_streak_info
    FROM sz_streaks 
    WHERE id = p_streak_id;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT 0, 0, 'Streak not found'::text;
        RETURN;
    END IF;
    
    -- Check if heart system is enabled
    IF NOT v_streak_info.points_to_hearts_enabled THEN
        RETURN QUERY SELECT 0, 0, 'Heart system disabled for this streak'::text;
        RETURN;
    END IF;
    
    -- Get user membership info
    SELECT 
        hearts_available,
        hearts_used
    INTO v_membership_info
    FROM sz_streak_members
    WHERE streak_id = p_streak_id AND user_id = p_user_id;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT 0, 0, 'User not found in streak'::text;
        RETURN;
    END IF;
    
    -- Calculate current day
    v_current_day := EXTRACT(days FROM (CURRENT_DATE - v_streak_info.start_date)::interval) + 1;
    
    -- Check each day from day 1 to current day - 1
    FOR v_day_to_check IN 1..(v_current_day - 1) LOOP
        v_days_checked_count := v_days_checked_count + 1;
        
        -- Check if user has a checkin for this day
        SELECT EXISTS(
            SELECT 1 FROM sz_checkins 
            WHERE streak_id = p_streak_id 
            AND user_id = p_user_id 
            AND day_number = v_day_to_check
        ) INTO v_has_checkin;
        
        -- If no checkin and hearts available, use a heart
        IF NOT v_has_checkin AND v_membership_info.hearts_available > 0 THEN
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
                'auto_use', v_day_to_check, 'Automatically used heart to protect streak on missed day'
            );
            
            v_hearts_used_count := v_hearts_used_count + 1;
            
            -- Update the membership info for next iteration
            v_membership_info.hearts_available := v_membership_info.hearts_available - 1;
        END IF;
        
        -- If no hearts left, break
        IF v_membership_info.hearts_available <= 0 THEN
            EXIT;
        END IF;
    END LOOP;
    
    RETURN QUERY SELECT 
        v_days_checked_count, 
        v_hearts_used_count, 
        format('Checked %s days, used %s hearts', v_days_checked_count, v_hearts_used_count)::text;
END;
$function$;

-- Create a trigger function that runs on every check-in
CREATE OR REPLACE FUNCTION public.sz_trigger_auto_apply_hearts()
RETURNS TRIGGER AS $$
BEGIN
    -- Auto-apply hearts for any missed days when user checks in
    PERFORM public.sz_auto_apply_hearts_for_missed_days(NEW.streak_id, NEW.user_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS sz_checkin_auto_hearts_trigger ON public.sz_checkins;

-- Create the trigger
CREATE TRIGGER sz_checkin_auto_hearts_trigger
    AFTER INSERT ON public.sz_checkins
    FOR EACH ROW
    EXECUTE FUNCTION public.sz_trigger_auto_apply_hearts();

-- Create a function to manually trigger heart application (for testing)
CREATE OR REPLACE FUNCTION public.sz_manual_apply_hearts(
    p_streak_id uuid,
    p_user_id uuid
)
RETURNS TABLE(
    days_checked integer,
    hearts_used integer,
    message text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
    RETURN QUERY 
    SELECT * FROM public.sz_auto_apply_hearts_for_missed_days(p_streak_id, p_user_id);
END;
$function$;

-- Test the function for your specific streak
-- Replace with your actual user ID from auth.users
SELECT * FROM public.sz_manual_apply_hearts(
    '8d249ba2-55bc-4369-8fad-13b171d165a2'::uuid,
    (SELECT id FROM auth.users WHERE email = 'streakzilla@gmail.com' LIMIT 1)::uuid
);
