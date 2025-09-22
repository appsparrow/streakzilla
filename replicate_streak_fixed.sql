-- Fixed Streak Replication Script
-- Extracts users and habits from source streak and replicates to target streak

-- Function to replicate users and their habits (fixed ambiguous column references)
CREATE OR REPLACE FUNCTION replicate_streak_data_fixed(
    p_source_streak_id UUID,
    p_target_streak_id UUID
) RETURNS VOID AS $$
DECLARE
    user_record RECORD;
    habit_record RECORD;
BEGIN
    -- Loop through each user in the source streak
    FOR user_record IN 
        SELECT sm.user_id, sm.role, sm.status, sm.joined_at, sm.current_streak, 
               sm.total_points, sm.hearts_available, sm.hearts_earned, sm.hearts_used
        FROM sz_streak_members sm
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
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Execute the replication
SELECT replicate_streak_data_fixed(
    '55e675ae-6937-4ece-a5b6-156115a797d2'::uuid,
    '444efc20-0db3-46a5-86a0-265597be8acd'::uuid
);

-- Verification query
SELECT 
    'REPLICATION COMPLETE' as status,
    COUNT(DISTINCT sm.user_id) as users_replicated,
    COUNT(DISTINCT uh.habit_id) as unique_habits,
    COUNT(uh.id) as total_user_habit_assignments
FROM sz_streak_members sm
LEFT JOIN sz_user_habits uh ON sm.streak_id = uh.streak_id AND sm.user_id = uh.user_id
WHERE sm.streak_id = '444efc20-0db3-46a5-86a0-265597be8acd'::uuid;

-- Show the replicated users and their habits
SELECT 
    u.email,
    sm.role,
    sm.status,
    sm.current_streak,
    sm.total_points,
    sm.hearts_available,
    COUNT(uh.habit_id) as habits_count
FROM sz_streak_members sm
JOIN auth.users u ON sm.user_id = u.id
LEFT JOIN sz_user_habits uh ON sm.streak_id = uh.streak_id AND sm.user_id = uh.user_id
WHERE sm.streak_id = '444efc20-0db3-46a5-86a0-265597be8acd'::uuid
GROUP BY u.email, sm.role, sm.status, sm.current_streak, sm.total_points, sm.hearts_available
ORDER BY sm.role, u.email;

-- Clean up
DROP FUNCTION replicate_streak_data_fixed(UUID, UUID);
