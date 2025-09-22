-- Diagnose Heart System Issue
-- This will help us figure out why the heart system isn't finding the user

-- 1. Check if the streak exists
SELECT 
    'Streak Exists' as test_name,
    id,
    name,
    start_date,
    points_to_hearts_enabled
FROM sz_streaks 
WHERE id = '8d249ba2-55bc-4369-8fad-13b171d165a2';

-- 2. Check all users in auth.users table
SELECT 
    'All Users' as test_name,
    id,
    email,
    created_at
FROM auth.users 
WHERE email LIKE '%streakzilla%' OR email LIKE '%gmail%'
ORDER BY created_at DESC
LIMIT 10;

-- 3. Check all members of this specific streak
SELECT 
    'Streak Members' as test_name,
    user_id,
    role,
    status,
    hearts_available,
    hearts_used,
    current_streak
FROM sz_streak_members 
WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2';

-- 4. Check if there are any profiles for these users
SELECT 
    'User Profiles' as test_name,
    id,
    full_name,
    email,
    created_at
FROM profiles 
WHERE id IN (
    SELECT user_id FROM sz_streak_members 
    WHERE streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
);

-- 5. Try to find the correct user ID for streakzilla@gmail.com
SELECT 
    'Find User ID' as test_name,
    u.id as user_id,
    u.email,
    p.full_name,
    sm.role,
    sm.hearts_available,
    sm.hearts_used
FROM auth.users u
LEFT JOIN profiles p ON u.id = p.id
LEFT JOIN sz_streak_members sm ON u.id = sm.user_id AND sm.streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'
WHERE u.email = 'streakzilla@gmail.com';

-- 6. Check all streaks this user might be in
SELECT 
    'User Streaks' as test_name,
    s.id as streak_id,
    s.name as streak_name,
    sm.role,
    sm.status,
    sm.hearts_available,
    sm.hearts_used
FROM auth.users u
JOIN sz_streak_members sm ON u.id = sm.user_id
JOIN sz_streaks s ON sm.streak_id = s.id
WHERE u.email = 'streakzilla@gmail.com';
