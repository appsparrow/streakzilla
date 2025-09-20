-- Test Heart Protection System
-- Run this script to test the automatic heart protection

-- Step 1: Create a test streak with heart system enabled
INSERT INTO sz_streaks (
    id, name, description, mode, duration_days, start_date, 
    created_by, points_to_hearts_enabled, hearts_per_100_points
) VALUES (
    gen_random_uuid(), 
    'Test Heart Protection', 
    'Testing automatic heart protection', 
    '75_hard_plus', 
    75, 
    CURRENT_DATE - INTERVAL '2 days', -- Started 2 days ago
    auth.uid(), 
    true, 
    1
);

-- Step 2: Add yourself as a member with some hearts
INSERT INTO sz_streak_members (
    streak_id, user_id, display_name, current_streak, total_points,
    hearts_available, hearts_earned, hearts_used
) VALUES (
    (SELECT id FROM sz_streaks WHERE name = 'Test Heart Protection' LIMIT 1),
    auth.uid(),
    'Test User',
    1, -- Current streak
    150, -- Total points (enough for 1 heart)
    1, -- 1 heart available
    1, -- 1 heart earned
    0  -- 0 hearts used
);

-- Step 3: Add a checkin for Day 1 (yesterday)
INSERT INTO sz_checkins (
    streak_id, user_id, day_number, completed_habit_ids, points_earned
) VALUES (
    (SELECT id FROM sz_streaks WHERE name = 'Test Heart Protection' LIMIT 1),
    auth.uid(),
    1,
    ARRAY[]::uuid[], -- Empty array for now
    50
);

-- Step 4: Now check in for Day 3 (skipping Day 2) to test heart protection
-- This should automatically use a heart to protect the streak
SELECT public.sz_checkin(
    (SELECT id FROM sz_streaks WHERE name = 'Test Heart Protection' LIMIT 1),
    3, -- Day 3 (skipping Day 2)
    ARRAY[]::uuid[], -- No habits for simplicity
    'Testing heart protection',
    NULL
);

-- Step 5: Check the results
SELECT 
    sm.current_streak,
    sm.total_points,
    sm.hearts_available,
    sm.hearts_used,
    'Hearts should have been automatically used!' as test_result
FROM sz_streak_members sm
JOIN sz_streaks s ON sm.streak_id = s.id
WHERE s.name = 'Test Heart Protection' AND sm.user_id = auth.uid();

-- Step 6: Check heart transactions
SELECT 
    transaction_type,
    day_number,
    note,
    hearts_amount
FROM sz_hearts_transactions
WHERE streak_id = (SELECT id FROM sz_streaks WHERE name = 'Test Heart Protection' LIMIT 1)
ORDER BY created_at DESC;
