-- Advanced Heart System Simulation
-- This script creates different test scenarios to verify the heart system

-- SCENARIO 1: User has hearts available and missed day 2
-- Let's set up this scenario

-- Step 1: Give the user some hearts
UPDATE sz_streak_members 
SET 
    hearts_available = 3,
    hearts_earned = 3,
    hearts_used = 0
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND user_id = (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1);

-- Step 2: Check current state
SELECT 
    'SCENARIO SETUP' as test_name,
    hearts_available,
    hearts_used,
    current_streak
FROM sz_streak_members 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND user_id = (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1);

-- Step 3: Check what days we have check-ins for
SELECT 
    'CURRENT CHECKINS' as test_name,
    day_number,
    points_earned
FROM sz_checkins 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND user_id = (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1)
ORDER BY day_number;

-- Step 4: Test heart application (this should use hearts for any missed days)
SELECT 
    'HEART APPLICATION RESULT' as test_name,
    *
FROM sz_manual_apply_hearts(
    '8d249ba2-55bc-4369-8fad-13b171d165a2'::uuid,
    (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1)::uuid
);

-- Step 5: Check heart transactions
SELECT 
    'HEART TRANSACTIONS CREATED' as test_name,
    day_number,
    transaction_type,
    hearts_amount,
    note
FROM sz_hearts_transactions 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND from_user_id = (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1)
ORDER BY day_number;

-- Step 6: Final status
SELECT 
    'FINAL STATUS' as test_name,
    hearts_available,
    hearts_used,
    current_streak
FROM sz_streak_members 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND user_id = (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1);

-- SCENARIO 2: Test what happens when user has no hearts available
-- Let's simulate this by setting hearts_available to 0

UPDATE sz_streak_members 
SET 
    hearts_available = 0,
    hearts_used = 3
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND user_id = (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1);

-- Test heart application with no hearts available
SELECT 
    'NO HEARTS TEST' as test_name,
    *
FROM sz_manual_apply_hearts(
    '8d249ba2-55bc-4369-8fad-13b171d165a2'::uuid,
    (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1)::uuid
);

-- Reset hearts for normal testing
UPDATE sz_streak_members 
SET 
    hearts_available = 2,
    hearts_earned = 2,
    hearts_used = 0
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND user_id = (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1);
