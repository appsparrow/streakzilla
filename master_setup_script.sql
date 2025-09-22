-- Master Setup Script for New Streak with Complete Check-ins
-- This script sets up the new streak with all users and their habits
-- Then generates complete check-ins from start date to today

-- Step 1: Create the new streak
INSERT INTO sz_streaks (
    id,
    name,
    description,
    mode,
    duration_days,
    start_date,
    end_date,
    is_active,
    created_by,
    points_to_hearts_enabled,
    hearts_per_100_points,
    template_id
) VALUES (
    '444efc20-0db3-46a5-86a0-265597be8acd'::uuid,
    '75 Hard Plus Challenge - New Batch',
    'Complete 75 Hard Plus challenge with all core and bonus habits',
    '75_hard_plus',
    75,
    '2025-09-17'::date,
    '2025-12-01'::date,
    true,
    'afc5adfa-553b-4d56-a583-2491b23ec453'::uuid,
    true,
    1,
    '79fb04f6-5f78-44f1-97eb-2563b22da2fe'::uuid
) ON CONFLICT (id) DO NOTHING;

-- Step 2: Add users to the streak
INSERT INTO sz_streak_members (streak_id, user_id, role, status, joined_at, current_streak, total_points, hearts_available, hearts_earned, hearts_used) VALUES
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', 'admin', 'active', NOW(), 0, 0, 0, 0, 0),
('444efc20-0db3-46a5-86a0-265597be8acd', '9bdf34ba-751d-4687-80b5-8f7d9549a635', 'member', 'active', NOW(), 0, 0, 0, 0, 0),
('444efc20-0db3-46a5-86a0-265597be8acd', 'afc5adfa-553b-4d56-a583-2491b23ec453', 'member', 'active', NOW(), 0, 0, 0, 0, 0),
('444efc20-0db3-46a5-86a0-265597be8acd', '8f93d8cb-428f-4f95-a04a-79be2f3e1063', 'member', 'active', NOW(), 0, 0, 0, 0, 0)
ON CONFLICT (streak_id, user_id) DO NOTHING;

-- Step 3: Get habit IDs dynamically and assign them to users
-- User 1: 521dca54-21ee-4815-baf7-9b4213275779 (All habits)
INSERT INTO sz_user_habits (streak_id, user_id, habit_id, points_override)
SELECT '444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', id, points
FROM sz_habits 
WHERE name IN (
    'Take a progress photo', 'No Alcohol', 'Drink 1 gallon of water', 'Two 45-minute workouts', 
    'Read 10 pages of non-fiction', 'Follow a diet', '10 minutes of meditation', 'Ice bath',
    'Wake Up Early', 'Morning Yoga', 'Plank Challenge', 'Meditation', 'Gratitude Journal',
    'No Social Media', 'Learn New Skill', 'Write 500 Words', 'Vitamins/Supplements',
    'No Processed Sugar', 'Green Smoothie', 'Make Your Bed', 'Connect with Friend',
    'Random Act of Kindness', 'No Complaining', 'Intermittent Fasting', 'Take Stairs Only', 'Cook from Scratch'
)
ON CONFLICT (streak_id, user_id, habit_id) DO NOTHING;

-- User 2: 9bdf34ba-751d-4687-80b5-8f7d9549a635 (Balu - Core habits only)
INSERT INTO sz_user_habits (streak_id, user_id, habit_id, points_override)
SELECT '444efc20-0db3-46a5-86a0-265597be8acd', '9bdf34ba-751d-4687-80b5-8f7d9549a635', id, points
FROM sz_habits 
WHERE name IN (
    'Take a progress photo', 'No Alcohol', 'Drink 1 gallon of water', 'Two 45-minute workouts', 
    'Read 10 pages of non-fiction', 'Follow a diet'
)
ON CONFLICT (streak_id, user_id, habit_id) DO NOTHING;

-- User 3: afc5adfa-553b-4d56-a583-2491b23ec453 (Core + some bonus)
INSERT INTO sz_user_habits (streak_id, user_id, habit_id, points_override)
SELECT '444efc20-0db3-46a5-86a0-265597be8acd', 'afc5adfa-553b-4d56-a583-2491b23ec453', id, points
FROM sz_habits 
WHERE name IN (
    'Take a progress photo', 'No Alcohol', 'Drink 1 gallon of water', 'Two 45-minute workouts', 
    'Read 10 pages of non-fiction', 'Follow a diet', '10 minutes of meditation', 'No Rice',
    'Cold Shower', 'Make Your Bed', 'Intermittent Fasting'
)
ON CONFLICT (streak_id, user_id, habit_id) DO NOTHING;

-- User 4: 8f93d8cb-428f-4f95-a04a-79be2f3e1063 (Vijis - Core + some bonus)
INSERT INTO sz_user_habits (streak_id, user_id, habit_id, points_override)
SELECT '444efc20-0db3-46a5-86a0-265597be8acd', '8f93d8cb-428f-4f95-a04a-79be2f3e1063', id, points
FROM sz_habits 
WHERE name IN (
    'Take a progress photo', 'No Alcohol', 'Drink 1 gallon of water', 'Two 45-minute workouts', 
    'Read 10 pages of non-fiction', 'Follow a diet', 'No Soda', 'No Rice',
    'Intermittent Fasting', 'Cook from Scratch'
)
ON CONFLICT (streak_id, user_id, habit_id) DO NOTHING;

-- Step 4: Function to generate complete check-ins
CREATE OR REPLACE FUNCTION generate_complete_checkins(
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
END;
$$ LANGUAGE plpgsql;

-- Step 5: Generate check-ins for all users
SELECT generate_complete_checkins('444efc20-0db3-46a5-86a0-265597be8acd'::uuid, '521dca54-21ee-4815-baf7-9b4213275779'::uuid, '2025-09-17'::date, CURRENT_DATE);
SELECT generate_complete_checkins('444efc20-0db3-46a5-86a0-265597be8acd'::uuid, '9bdf34ba-751d-4687-80b5-8f7d9549a635'::uuid, '2025-09-17'::date, CURRENT_DATE);
SELECT generate_complete_checkins('444efc20-0db3-46a5-86a0-265597be8acd'::uuid, 'afc5adfa-553b-4d56-a583-2491b23ec453'::uuid, '2025-09-17'::date, CURRENT_DATE);
SELECT generate_complete_checkins('444efc20-0db3-46a5-86a0-265597be8acd'::uuid, '8f93d8cb-428f-4f95-a04a-79be2f3e1063'::uuid, '2025-09-17'::date, CURRENT_DATE);

-- Step 6: Verification query
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

-- Clean up
DROP FUNCTION generate_complete_checkins(UUID, UUID, DATE, DATE);
