-- Generate Complete Check-ins for All Replicated Users
-- This script creates check-ins for all days from start date to today
-- All habits will be marked as completed for each day

-- Function to generate check-ins for a user
CREATE OR REPLACE FUNCTION generate_user_checkins_complete(
    p_streak_id UUID,
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE
) RETURNS VOID AS $$
DECLARE
    current_date DATE := p_start_date;
    habit_record RECORD;
    day_number INTEGER;
    total_points INTEGER := 0;
BEGIN
    -- Loop through each day from start to end
    WHILE current_date <= p_end_date LOOP
        day_number := (current_date - p_start_date) + 1;
        
        -- Get all habits for this user and create check-ins
        FOR habit_record IN 
            SELECT uh.habit_id, uh.points_override
            FROM sz_user_habits uh
            WHERE uh.streak_id = p_streak_id 
            AND uh.user_id = p_user_id
        LOOP
            -- Insert check-in for this habit on this day
            INSERT INTO sz_checkins (
                streak_id,
                user_id,
                habit_id,
                day_number,
                completed_at,
                points_earned,
                notes
            ) VALUES (
                p_streak_id,
                p_user_id,
                habit_record.habit_id,
                day_number,
                current_date + INTERVAL '18 hours', -- Assume completed at 6 PM
                habit_record.points_override,
                'Auto-generated complete check-in'
            ) ON CONFLICT DO NOTHING;
            
            total_points := total_points + habit_record.points_override;
        END LOOP;
        
        current_date := current_date + INTERVAL '1 day';
    END LOOP;
    
    -- Update user's total points and streak
    UPDATE sz_streak_members 
    SET total_points = total_points,
        current_streak = (p_end_date - p_start_date) + 1,
        hearts_earned = FLOOR(total_points / 100),
        hearts_available = FLOOR(total_points / 100)
    WHERE streak_id = p_streak_id 
    AND user_id = p_user_id;
    
    -- Update the streak's bonus_points to reflect total points earned by all users
    UPDATE sz_streaks 
    SET bonus_points = (
        SELECT COALESCE(SUM(sm.total_points), 0)
        FROM sz_streak_members sm
        WHERE sm.streak_id = p_streak_id
    )
    WHERE id = p_streak_id;
END;
$$ LANGUAGE plpgsql;

-- Get the start date from the target streak
DO $$
DECLARE
    streak_start_date DATE;
    current_date DATE := CURRENT_DATE;
    user_record RECORD;
    days_completed INTEGER;
BEGIN
    -- Get the start date of the target streak
    SELECT start_date INTO streak_start_date
    FROM sz_streaks
    WHERE id = '444efc20-0db3-46a5-86a0-265597be8acd'::uuid;
    
    -- Calculate days completed
    days_completed := (current_date - streak_start_date) + 1;
    
    RAISE NOTICE 'Streak start date: %', streak_start_date;
    RAISE NOTICE 'Current date: %', current_date;
    RAISE NOTICE 'Days to complete: %', days_completed;
    
    -- Generate check-ins for all users in the target streak
    FOR user_record IN 
        SELECT sm.user_id, u.email
        FROM sz_streak_members sm
        JOIN auth.users u ON sm.user_id = u.id
        WHERE sm.streak_id = '444efc20-0db3-46a5-86a0-265597be8acd'::uuid
    LOOP
        RAISE NOTICE 'Generating check-ins for user: %', user_record.email;
        
        -- Generate check-ins for this user
        PERFORM generate_user_checkins_complete(
            '444efc20-0db3-46a5-86a0-265597be8acd'::uuid,
            user_record.user_id,
            streak_start_date,
            current_date
        );
    END LOOP;
    
    RAISE NOTICE 'All users completed successfully!';
END $$;

-- Verification query - show results
SELECT 
    'FINAL VERIFICATION' as check_type,
    sm.user_id,
    u.email,
    sm.role,
    sm.current_streak,
    sm.total_points,
    sm.hearts_earned,
    sm.hearts_available,
    COUNT(c.id) as total_checkins,
    COUNT(DISTINCT c.habit_id) as unique_habits_checked,
    COUNT(DISTINCT c.day_number) as days_completed
FROM sz_streak_members sm
JOIN auth.users u ON sm.user_id = u.id
LEFT JOIN sz_checkins c ON sm.streak_id = c.streak_id AND sm.user_id = c.user_id
WHERE sm.streak_id = '444efc20-0db3-46a5-86a0-265597be8acd'::uuid
GROUP BY sm.user_id, u.email, sm.role, sm.current_streak, sm.total_points, sm.hearts_earned, sm.hearts_available
ORDER BY sm.role, u.email;

-- Show bonus points and hearts earned
SELECT 
    'BONUS POINTS & HEARTS' as check_type,
    s.bonus_points,
    FLOOR(s.bonus_points / 100) as bonus_hearts_earned,
    s.points_to_hearts_enabled,
    s.hearts_per_100_points
FROM sz_streaks s
WHERE s.id = '444efc20-0db3-46a5-86a0-265597be8acd'::uuid;

-- Show check-in summary by day
SELECT 
    'CHECK-IN SUMMARY' as check_type,
    c.day_number,
    c.completed_at::date as date,
    COUNT(DISTINCT c.user_id) as users_completed,
    COUNT(c.id) as total_checkins,
    SUM(c.points_earned) as total_points_earned
FROM sz_checkins c
WHERE c.streak_id = '444efc20-0db3-46a5-86a0-265597be8acd'::uuid
GROUP BY c.day_number, c.completed_at::date
ORDER BY c.day_number;

-- Clean up
DROP FUNCTION generate_user_checkins_complete(UUID, UUID, DATE, DATE);
