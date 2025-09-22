-- Test the Fixed Heart System
-- This script tests the corrected heart application function

-- 1. Set up test scenario - give user some hearts
UPDATE sz_streak_members 
SET 
    hearts_available = 2,
    hearts_earned = 2,
    hearts_used = 0
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND user_id = (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1);

-- 2. Check initial state
SELECT 
    'INITIAL STATE' as test_name,
    hearts_available,
    hearts_used,
    current_streak
FROM sz_streak_members 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND user_id = (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1);

-- 3. Test the fixed heart application function
SELECT 
    'HEART APPLICATION TEST' as test_name,
    *
FROM sz_manual_apply_hearts(
    '8d249ba2-55bc-4369-8fad-13b171d165a2'::uuid,
    (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1)::uuid
);

-- 4. Check final state
SELECT 
    'FINAL STATE' as test_name,
    hearts_available,
    hearts_used,
    current_streak
FROM sz_streak_members 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND user_id = (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1);

-- 5. Check heart transactions
SELECT 
    'HEART TRANSACTIONS' as test_name,
    day_number,
    transaction_type,
    hearts_amount,
    note
FROM sz_hearts_transactions 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND from_user_id = (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1)
ORDER BY created_at DESC;
