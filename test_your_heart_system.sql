-- Test Heart System for Your Specific Streak
-- This will check if hearts are being applied correctly

-- 1. Check your current heart status
SELECT 
    'Your Heart Status' as test_name,
    hearts_available,
    hearts_earned,
    hearts_used,
    current_streak,
    total_points
FROM sz_streak_members 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND user_id = (SELECT id FROM auth.users WHERE email = 'streakzilla@gmail.com' LIMIT 1);

-- 2. Check your check-ins so far
SELECT 
    'Your Check-ins' as test_name,
    day_number,
    points_earned,
    created_at
FROM sz_checkins 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND user_id = (SELECT id FROM auth.users WHERE email = 'streakzilla@gmail.com' LIMIT 1)
ORDER BY day_number;

-- 3. Check if you have any heart transactions
SELECT 
    'Heart Transactions' as test_name,
    day_number,
    transaction_type,
    hearts_amount,
    note,
    created_at
FROM sz_hearts_transactions 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND from_user_id = (SELECT id FROM auth.users WHERE email = 'streakzilla@gmail.com' LIMIT 1)
ORDER BY created_at DESC;

-- 4. Test manual heart application (this will apply hearts for any missed days)
SELECT 
    'Manual Heart Application' as test_name,
    *
FROM sz_manual_apply_hearts(
    '8d249ba2-55bc-4369-8fad-13b171d165a2'::uuid,
    (SELECT id FROM auth.users WHERE email = 'streakzilla@gmail.com' LIMIT 1)::uuid
);

-- 5. Check your heart status again after manual application
SELECT 
    'Heart Status After Manual Application' as test_name,
    hearts_available,
    hearts_used,
    current_streak
FROM sz_streak_members 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND user_id = (SELECT id FROM auth.users WHERE email = 'streakzilla@gmail.com' LIMIT 1);
