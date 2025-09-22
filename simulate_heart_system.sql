-- Simulate Heart System Testing
-- This script allows you to test the heart system by simulating different scenarios

-- 1. First, let's see the current state
SELECT 
    'CURRENT STATE' as test_name,
    'User' as info_type,
    u.email,
    sm.hearts_available,
    sm.hearts_used,
    sm.current_streak,
    sm.total_points
FROM auth.users u
JOIN sz_streak_members sm ON u.id = sm.user_id
WHERE u.email = 'contact.appsparrow@gmail.com'
AND sm.streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2';

-- 2. Check current check-ins
SELECT 
    'CURRENT CHECKINS' as test_name,
    day_number,
    points_earned,
    created_at
FROM sz_checkins 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND user_id = (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1)
ORDER BY day_number;

-- 3. SIMULATION: Create a fake missed day by inserting a check-in for day 2, then deleting it
-- This simulates what happens when someone misses a day

-- First, let's add some hearts to the user so we can test heart usage
UPDATE sz_streak_members 
SET 
    hearts_available = 2,
    hearts_earned = 2,
    hearts_used = 0
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND user_id = (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1);

-- 4. Check the updated heart status
SELECT 
    'UPDATED HEART STATUS' as test_name,
    hearts_available,
    hearts_earned,
    hearts_used,
    current_streak
FROM sz_streak_members 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND user_id = (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1);

-- 5. SIMULATION: Create a scenario where day 2 is missed
-- We'll simulate this by ensuring there's no check-in for day 2

-- First, let's see what day we're currently on
SELECT 
    'CURRENT DAY CALCULATION' as test_name,
    start_date,
    CURRENT_DATE as today,
    (CURRENT_DATE - start_date) + 1 as current_day
FROM sz_streaks 
WHERE id = '8d249ba2-55bc-4369-8fad-13b171d165a2';

-- 6. Test the heart application function
SELECT 
    'HEART APPLICATION TEST' as test_name,
    *
FROM sz_manual_apply_hearts(
    '8d249ba2-55bc-4369-8fad-13b171d165a2'::uuid,
    (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1)::uuid
);

-- 7. Check heart transactions after application
SELECT 
    'HEART TRANSACTIONS' as test_name,
    day_number,
    transaction_type,
    hearts_amount,
    note,
    created_at
FROM sz_hearts_transactions 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND from_user_id = (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1)
ORDER BY created_at DESC;

-- 8. Final heart status
SELECT 
    'FINAL HEART STATUS' as test_name,
    hearts_available,
    hearts_used,
    current_streak
FROM sz_streak_members 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND user_id = (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1);
