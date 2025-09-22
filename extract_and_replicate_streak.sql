-- Extract and Replicate Streak Data
-- This script extracts users and their habits from an existing streak
-- and replicates them to a new streak

-- Step 1: Extract data from existing streak (55e675ae-6937-4ece-a5b6-156115a797d2)
-- Let's first examine what we're working with
SELECT 
    'EXISTING STREAK INFO' as check_type,
    s.id,
    s.name,
    s.mode,
    s.duration_days,
    s.start_date,
    (s.start_date + INTERVAL '75 days')::date as calculated_end_date,
    s.is_active,
    s.created_by,
    s.points_to_hearts_enabled,
    s.hearts_per_100_points
FROM sz_streaks s
WHERE s.id = '55e675ae-6937-4ece-a5b6-156115a797d2'::uuid;

-- Step 2: Get all users from existing streak
SELECT 
    'EXISTING USERS' as check_type,
    sm.user_id,
    u.email,
    sm.role,
    sm.status,
    sm.joined_at,
    sm.current_streak,
    sm.total_points,
    sm.hearts_available,
    sm.hearts_earned,
    sm.hearts_used
FROM sz_streak_members sm
JOIN auth.users u ON sm.user_id = u.id
WHERE sm.streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2'::uuid
ORDER BY sm.role, u.email;

-- Step 3: Get all habits assigned to users in existing streak
SELECT 
    'EXISTING USER HABITS' as check_type,
    sm.user_id,
    u.email,
    uh.habit_id,
    h.description as habit_description,
    h.points as habit_points,
    h.category,
    uh.points_override
FROM sz_streak_members sm
JOIN auth.users u ON sm.user_id = u.id
JOIN sz_user_habits uh ON sm.streak_id = uh.streak_id AND sm.user_id = uh.user_id
JOIN sz_habits h ON uh.habit_id = h.id
WHERE sm.streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2'::uuid
ORDER BY u.email, h.description;

-- Step 4: Function to replicate users and their habits to new streak
CREATE OR REPLACE FUNCTION replicate_streak_users(
    p_source_streak_id UUID,
    p_target_streak_id UUID
) RETURNS TABLE(
    user_id UUID,
    email TEXT,
    role TEXT,
    habits_count INTEGER,
    status TEXT
) AS $$
DECLARE
    user_record RECORD;
    habit_record RECORD;
    habits_count INTEGER;
BEGIN
    -- Loop through each user in the source streak
    FOR user_record IN 
        SELECT sm.user_id, sm.role, sm.status, sm.joined_at, sm.current_streak, 
               sm.total_points, sm.hearts_available, sm.hearts_earned, sm.hearts_used,
               u.email
        FROM sz_streak_members sm
        JOIN auth.users u ON sm.user_id = u.id
        WHERE sm.streak_id = p_source_streak_id
    LOOP
        -- Add user to target streak
        INSERT INTO sz_streak_members (
            streak_id, user_id, role, status, joined_at, 
            current_streak, total_points, hearts_available, hearts_earned, hearts_used
        ) VALUES (
            p_target_streak_id,
            user_record.user_id,
            user_record.role,
            user_record.status,
            NOW(), -- Use current time for new streak
            user_record.current_streak,
            user_record.total_points,
            user_record.hearts_available,
            user_record.hearts_earned,
            user_record.hearts_used
        ) ON CONFLICT (streak_id, user_id) DO UPDATE SET
            role = EXCLUDED.role,
            status = EXCLUDED.status,
            current_streak = EXCLUDED.current_streak,
            total_points = EXCLUDED.total_points,
            hearts_available = EXCLUDED.hearts_available,
            hearts_earned = EXCLUDED.hearts_earned,
            hearts_used = EXCLUDED.hearts_used;
        
        habits_count := 0;
        
        -- Copy all habits for this user
        FOR habit_record IN 
            SELECT uh.habit_id, uh.points_override
            FROM sz_user_habits uh
            WHERE uh.streak_id = p_source_streak_id 
            AND uh.user_id = user_record.user_id
        LOOP
            -- Add habit to target streak
            INSERT INTO sz_user_habits (
                streak_id, user_id, habit_id, points_override
            ) VALUES (
                p_target_streak_id,
                user_record.user_id,
                habit_record.habit_id,
                habit_record.points_override
            ) ON CONFLICT (streak_id, user_id, habit_id) DO UPDATE SET
                points_override = EXCLUDED.points_override;
            
            habits_count := habits_count + 1;
        END LOOP;
        
        -- Return the result
        RETURN QUERY SELECT 
            user_record.user_id,
            user_record.email,
            user_record.role,
            habits_count,
            user_record.status;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Step 5: Execute the replication
SELECT * FROM replicate_streak_users(
    '55e675ae-6937-4ece-a5b6-156115a797d2'::uuid,
    '444efc20-0db3-46a5-86a0-265597be8acd'::uuid
);

-- Step 6: Verify the replication
SELECT 
    'REPLICATED USERS' as check_type,
    sm.user_id,
    u.email,
    sm.role,
    sm.status,
    sm.joined_at,
    sm.current_streak,
    sm.total_points,
    sm.hearts_available,
    sm.hearts_earned,
    sm.hearts_used
FROM sz_streak_members sm
JOIN auth.users u ON sm.user_id = u.id
WHERE sm.streak_id = '444efc20-0db3-46a5-86a0-265597be8acd'::uuid
ORDER BY sm.role, u.email;

-- Step 7: Verify replicated habits
SELECT 
    'REPLICATED USER HABITS' as check_type,
    sm.user_id,
    u.email,
    uh.habit_id,
    h.description as habit_description,
    h.points as habit_points,
    h.category,
    uh.points_override
FROM sz_streak_members sm
JOIN auth.users u ON sm.user_id = u.id
JOIN sz_user_habits uh ON sm.streak_id = uh.streak_id AND sm.user_id = uh.user_id
JOIN sz_habits h ON uh.habit_id = h.id
WHERE sm.streak_id = '444efc20-0db3-46a5-86a0-265597be8acd'::uuid
ORDER BY u.email, h.description;

-- Step 8: Summary comparison
SELECT 
    'SUMMARY COMPARISON' as check_type,
    'Source Streak' as streak_type,
    COUNT(DISTINCT sm.user_id) as user_count,
    COUNT(DISTINCT uh.habit_id) as unique_habits,
    COUNT(uh.id) as total_user_habits
FROM sz_streak_members sm
LEFT JOIN sz_user_habits uh ON sm.streak_id = uh.streak_id AND sm.user_id = uh.user_id
WHERE sm.streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2'::uuid

UNION ALL

SELECT 
    'SUMMARY COMPARISON' as check_type,
    'Target Streak' as streak_type,
    COUNT(DISTINCT sm.user_id) as user_count,
    COUNT(DISTINCT uh.habit_id) as unique_habits,
    COUNT(uh.id) as total_user_habits
FROM sz_streak_members sm
LEFT JOIN sz_user_habits uh ON sm.streak_id = uh.streak_id AND sm.user_id = uh.user_id
WHERE sm.streak_id = '444efc20-0db3-46a5-86a0-265597be8acd'::uuid;

-- Clean up
DROP FUNCTION replicate_streak_users(UUID, UUID);
