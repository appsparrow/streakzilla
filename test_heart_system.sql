-- Test Heart System Functionality
-- Run this script to verify the heart system is working correctly

-- 1. Check if heart system is enabled for the streak
SELECT 
    'Heart System Status' as test_name,
    id,
    name,
    points_to_hearts_enabled,
    hearts_per_100_points
FROM sz_streaks 
WHERE id = '8d249ba2-55bc-4369-8fad-13b171d165a2';

-- 2. Check user's current heart status
SELECT 
    'User Heart Status' as test_name,
    user_id,
    hearts_available,
    hearts_earned,
    hearts_used,
    current_streak,
    total_points
FROM sz_streak_members 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND user_id = (SELECT id FROM auth.users WHERE email = 'streakzilla@gmail.com' LIMIT 1);

-- 3. Check recent check-ins
SELECT 
    'Recent Check-ins' as test_name,
    day_number,
    points_earned,
    created_at
FROM sz_checkins 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
AND user_id = (SELECT id FROM auth.users WHERE email = 'streakzilla@gmail.com' LIMIT 1)
ORDER BY day_number DESC
LIMIT 10;

-- 4. Check heart transactions
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
ORDER BY created_at DESC
LIMIT 10;

-- 5. Test the manual heart application function
SELECT 
    'Manual Heart Application Test' as test_name,
    *
FROM sz_manual_apply_hearts(
    '8d249ba2-55bc-4369-8fad-13b171d165a2'::uuid,
    (SELECT id FROM auth.users WHERE email = 'streakzilla@gmail.com' LIMIT 1)::uuid
);

-- 6. Check if triggers exist
SELECT 
    'Trigger Check' as test_name,
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
AND (trigger_name LIKE '%heart%' OR trigger_name LIKE '%checkin%')
ORDER BY trigger_name;
