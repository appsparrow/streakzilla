-- Generate Complete Check-ins for All Users
-- This script creates check-ins for all days from start date (9/17) to today
-- All habits will be marked as completed for each day

-- Function to generate check-ins for a user
CREATE OR REPLACE FUNCTION generate_user_checkins(
    p_streak_id UUID,
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE
) RETURNS VOID AS $$
DECLARE
    current_date DATE := p_start_date;
    habit_record RECORD;
    day_number INTEGER;
BEGIN
    -- Loop through each day from start to end
    WHILE current_date <= p_end_date LOOP
        day_number := (current_date - p_start_date) + 1;
        
        -- Get all habits for this user
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
            );
        END LOOP;
        
        current_date := current_date + INTERVAL '1 day';
    END LOOP;
    
    -- Update user's total points
    UPDATE sz_streak_members 
    SET total_points = (
        SELECT COALESCE(SUM(points_earned), 0)
        FROM sz_checkins 
        WHERE streak_id = p_streak_id 
        AND user_id = p_user_id
    ),
    current_streak = (p_end_date - p_start_date) + 1
    WHERE streak_id = p_streak_id 
    AND user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- Generate check-ins for all users
-- User 1: 521dca54-21ee-4815-baf7-9b4213275779
SELECT generate_user_checkins(
    '444efc20-0db3-46a5-86a0-265597be8acd'::uuid,
    '521dca54-21ee-4815-baf7-9b4213275779'::uuid,
    '2025-09-17'::date,
    CURRENT_DATE
);

-- User 2: 9bdf34ba-751d-4687-80b5-8f7d9549a635 (Balu)
SELECT generate_user_checkins(
    '444efc20-0db3-46a5-86a0-265597be8acd'::uuid,
    '9bdf34ba-751d-4687-80b5-8f7d9549a635'::uuid,
    '2025-09-17'::date,
    CURRENT_DATE
);

-- User 3: afc5adfa-553b-4d56-a583-2491b23ec453
SELECT generate_user_checkins(
    '444efc20-0db3-46a5-86a0-265597be8acd'::uuid,
    'afc5adfa-553b-4d56-a583-2491b23ec453'::uuid,
    '2025-09-17'::date,
    CURRENT_DATE
);

-- User 4: 8f93d8cb-428f-4f95-a04a-79be2f3e1063 (Vijis)
SELECT generate_user_checkins(
    '444efc20-0db3-46a5-86a0-265597be8acd'::uuid,
    '8f93d8cb-428f-4f95-a04a-79be2f3e1063'::uuid,
    '2025-09-17'::date,
    CURRENT_DATE
);

-- Update hearts based on points earned
UPDATE sz_streak_members 
SET hearts_earned = FLOOR(total_points / 100),
    hearts_available = FLOOR(total_points / 100)
WHERE streak_id = '444efc20-0db3-46a5-86a0-265597be8acd'::uuid;

-- Verify the setup
SELECT 
    'VERIFICATION' as check_type,
    sm.user_id,
    u.email,
    sm.role,
    sm.current_streak,
    sm.total_points,
    sm.hearts_earned,
    sm.hearts_available,
    COUNT(c.id) as total_checkins,
    COUNT(DISTINCT c.habit_id) as unique_habits_checked
FROM sz_streak_members sm
JOIN auth.users u ON sm.user_id = u.id
LEFT JOIN sz_checkins c ON sm.streak_id = c.streak_id AND sm.user_id = c.user_id
WHERE sm.streak_id = '444efc20-0db3-46a5-86a0-265597be8acd'::uuid
GROUP BY sm.user_id, u.email, sm.role, sm.current_streak, sm.total_points, sm.hearts_earned, sm.hearts_available
ORDER BY sm.role, u.email;

-- Clean up the function
DROP FUNCTION generate_user_checkins(UUID, UUID, DATE, DATE);
