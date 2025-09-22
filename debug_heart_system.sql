-- Debug Heart System for specific streak
-- Replace '8d249ba2-55bc-4369-8fad-13b171d165a2' with your actual streak ID

-- Check streak settings
SELECT 
    'STREAK SETTINGS' as section,
    id,
    name,
    mode,
    start_date,
    points_to_hearts_enabled,
    hearts_per_100_points
FROM sz_streaks 
WHERE id = '8d249ba2-55bc-4369-8fad-13b171d165a2';

-- Check user membership and hearts
SELECT 
    'USER MEMBERSHIP' as section,
    user_id,
    current_streak,
    total_points,
    hearts_available,
    hearts_earned,
    hearts_used,
    lives_remaining
FROM sz_streak_members 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2';

-- Check recent check-ins
SELECT 
    'RECENT CHECKINS' as section,
    day_number,
    user_id,
    completed_habit_ids,
    points_earned,
    created_at
FROM sz_checkins 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
ORDER BY day_number DESC
LIMIT 10;

-- Check heart transactions
SELECT 
    'HEART TRANSACTIONS' as section,
    day_number,
    transaction_type,
    hearts_amount,
    note,
    created_at
FROM sz_hearts_transactions 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
ORDER BY created_at DESC
LIMIT 10;

-- Check if triggers exist
SELECT 
    'TRIGGERS CHECK' as section,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
AND trigger_name LIKE '%heart%' OR trigger_name LIKE '%checkin%';

-- Test current day calculation
SELECT 
    'DAY CALCULATION' as section,
    start_date,
    CURRENT_DATE as today,
    CURRENT_DATE - start_date + 1 as calculated_day,
    EXTRACT(days FROM CURRENT_DATE - start_date) + 1 as day_number
FROM sz_streaks 
WHERE id = '8d249ba2-55bc-4369-8fad-13b171d165a2';
