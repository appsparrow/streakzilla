-- Test Heart System for Correct User: contact.appsparrow@gmail.com
-- This will check if hearts are being applied correctly for the right user

-- 1. Check if the correct user exists and is in the streak
SELECT 
    'Correct User in Streak' as test_name,
    u.id as user_id,
    u.email,
    p.full_name,
    sm.role,
    sm.status,
    sm.hearts_available,
    sm.hearts_used,
    sm.current_streak
FROM auth.users u
LEFT JOIN profiles p ON u.id = p.id
LEFT JOIN sz_streak_members sm ON u.id = sm.user_id AND sm.streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
WHERE u.email = 'contact.appsparrow@gmail.com';

-- 2. Check current heart status for correct user
SELECT 
    'Heart Status' as test_name,
    hearts_available,
    hearts_earned,
    hearts_used,
    current_streak,
    total_points
FROM sz_streak_members 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND user_id = (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1);

-- 3. Check check-ins for correct user
SELECT 
    'Check-ins' as test_name,
    day_number,
    points_earned,
    created_at
FROM sz_checkins 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND user_id = (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1)
ORDER BY day_number;

-- 4. Check heart transactions for correct user
SELECT 
    'Heart Transactions' as test_name,
    day_number,
    transaction_type,
    hearts_amount,
    note,
    created_at
FROM sz_hearts_transactions 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND from_user_id = (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1)
ORDER BY created_at DESC;

-- 5. Test manual heart application for correct user
SELECT 
    'Manual Heart Application' as test_name,
    *
FROM sz_manual_apply_hearts(
    '8d249ba2-55bc-4369-8fad-13b171d165a2'::uuid,
    (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1)::uuid
);

-- 6. Check heart status after manual application
SELECT 
    'Heart Status After Application' as test_name,
    hearts_available,
    hearts_used,
    current_streak
FROM sz_streak_members 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND user_id = (SELECT id FROM auth.users WHERE email = 'contact.appsparrow@gmail.com' LIMIT 1);
