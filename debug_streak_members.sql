-- Debug script to check streak members and profiles
-- This will help us understand why members aren't showing

-- Check what's in sz_streak_members for the selected streak
SELECT 
    'STREAK MEMBERS' as check_type,
    sm.streak_id,
    sm.user_id,
    sm.role,
    sm.status,
    sm.joined_at,
    sm.current_streak,
    sm.total_points,
    sm.hearts_available
FROM sz_streak_members sm
WHERE sm.streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2'::uuid
ORDER BY sm.joined_at;

-- Check what's in profiles table for these users
SELECT 
    'PROFILES' as check_type,
    p.id,
    p.email
FROM profiles p
WHERE p.id IN (
    SELECT sm.user_id 
    FROM sz_streak_members sm 
    WHERE sm.streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2'::uuid
)
ORDER BY p.email;

-- Check the combined data that should be returned
SELECT 
    'COMBINED DATA' as check_type,
    sm.user_id,
    sm.role,
    sm.status,
    sm.current_streak,
    sm.total_points,
    sm.hearts_available,
    p.email
FROM sz_streak_members sm
LEFT JOIN profiles p ON sm.user_id = p.id
WHERE sm.streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2'::uuid
ORDER BY sm.joined_at;
