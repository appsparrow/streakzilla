-- Debug Second Heart Issue
-- This script will help us understand why the second heart isn't being applied

-- 1. Check current heart status
SELECT 
    'CURRENT HEART STATUS' as test_name,
    hearts_available,
    hearts_earned,
    hearts_used,
    current_streak,
    total_points
FROM sz_streak_members 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND user_id = (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1);

-- 2. Check current day calculation
SELECT 
    'DAY CALCULATION' as test_name,
    start_date,
    CURRENT_DATE as today,
    (CURRENT_DATE - start_date) + 1 as current_day
FROM sz_streaks 
WHERE id = '8d249ba2-55bc-4369-8fad-13b171d165a2';

-- 3. Check all check-ins
SELECT 
    'ALL CHECK-INS' as test_name,
    day_number,
    points_earned,
    created_at
FROM sz_checkins 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND user_id = (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1)
ORDER BY day_number;

-- 4. Check heart transactions
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
ORDER BY day_number;

-- 5. Check which days are missing check-ins (this is what should trigger heart usage)
SELECT 
    'MISSING CHECK-INS' as test_name,
    day_number,
    'Missing check-in' as status
FROM generate_series(1, (CURRENT_DATE - (SELECT start_date FROM sz_streaks WHERE id = '8d249ba2-55bc-4369-8fad-13b171d165a2'))::integer) as day_number
WHERE day_number NOT IN (
    SELECT day_number 
    FROM sz_checkins 
    WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
    AND user_id = (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1)
)
AND day_number NOT IN (
    SELECT day_number 
    FROM sz_hearts_transactions 
    WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
    AND from_user_id = (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1)
    AND transaction_type = 'auto_use'
);

-- 6. Test manual heart application again
SELECT 
    'MANUAL HEART APPLICATION' as test_name,
    *
FROM sz_manual_apply_hearts(
    '8d249ba2-55bc-4369-8fad-13b171d165a2'::uuid,
    (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1)::uuid
);

-- 7. Check heart status after manual application
SELECT 
    'HEART STATUS AFTER APPLICATION' as test_name,
    hearts_available,
    hearts_used,
    current_streak
FROM sz_streak_members 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND user_id = (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1);
