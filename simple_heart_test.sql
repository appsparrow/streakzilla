-- Simple Heart Protection Test
-- This creates a minimal test scenario

-- 1. Create a test streak
INSERT INTO sz_streaks (
    id, name, mode, duration_days, start_date, 
    created_by, points_to_hearts_enabled, hearts_per_100_points
) VALUES (
    '00000000-0000-0000-0000-000000000001', 
    'Heart Test Streak', 
    '75_hard_plus', 
    75, 
    CURRENT_DATE - INTERVAL '2 days',
    auth.uid(), 
    true, 
    1
);

-- 2. Add yourself as member with hearts
INSERT INTO sz_streak_members (
    streak_id, user_id, display_name, current_streak, total_points,
    hearts_available, hearts_earned, hearts_used
) VALUES (
    '00000000-0000-0000-0000-000000000001',
    auth.uid(),
    'Test User',
    1,
    100, -- Enough for 1 heart
    1,   -- 1 heart available
    1,   -- 1 heart earned
    0    -- 0 hearts used
);

-- 3. Add checkin for Day 1 only (Day 2 will be missed)
INSERT INTO sz_checkins (
    streak_id, user_id, day_number, completed_habit_ids, points_earned
) VALUES (
    '00000000-0000-0000-0000-000000000001',
    auth.uid(),
    1,
    ARRAY[]::uuid[],
    50
);

-- 4. Test the heart protection by checking in for Day 3
SELECT public.sz_checkin(
    '00000000-0000-0000-0000-000000000001',
    3, -- Day 3 (Day 2 was missed)
    ARRAY[]::uuid[],
    'Testing automatic heart protection',
    NULL
);

-- 5. Check if hearts were used
SELECT 
    'Before: 1 heart available' as before_test,
    hearts_available as after_hearts_available,
    hearts_used as after_hearts_used,
    current_streak as after_current_streak,
    CASE 
        WHEN hearts_used > 0 THEN 'SUCCESS: Hearts were automatically used!'
        ELSE 'FAILED: No hearts were used'
    END as test_result
FROM sz_streak_members
WHERE streak_id = '00000000-0000-0000-0000-000000000001' 
AND user_id = auth.uid();
