-- Pull all existing users from the specific streak
-- This will help us see what users are actually in the streak

-- Check if the streak exists
SELECT 
    'STREAK EXISTS' as check_type,
    id,
    name,
    mode,
    start_date,
    duration_days,
    is_active
FROM sz_streaks 
WHERE id = '444efc20-0db3-46a5-86a0-265597be8acd'::uuid;

-- Get all members from this streak
SELECT 
    'STREAK MEMBERS' as check_type,
    sm.user_id,
    sm.role,
    sm.status,
    sm.joined_at,
    sm.current_streak,
    sm.total_points,
    sm.hearts_available,
    sm.hearts_earned,
    sm.hearts_used
FROM sz_streak_members sm
WHERE sm.streak_id = '444efc20-0db3-46a5-86a0-265597be8acd'::uuid
ORDER BY sm.joined_at;

-- Get user profiles for these members
SELECT 
    'USER PROFILES' as check_type,
    p.id,
    p.email
FROM profiles p
WHERE p.id IN (
    SELECT sm.user_id 
    FROM sz_streak_members sm 
    WHERE sm.streak_id = '444efc20-0db3-46a5-86a0-265597be8acd'::uuid
)
ORDER BY p.email;

-- Combined view (what the frontend should see)
SELECT 
    'COMBINED VIEW' as check_type,
    sm.user_id,
    sm.role,
    sm.status,
    sm.current_streak,
    sm.total_points,
    sm.hearts_available,
    p.email,
    sm.joined_at
FROM sz_streak_members sm
LEFT JOIN profiles p ON sm.user_id = p.id
WHERE sm.streak_id = '444efc20-0db3-46a5-86a0-265597be8acd'::uuid
ORDER BY sm.joined_at;

-- Count summary
SELECT 
    'SUMMARY' as check_type,
    'Total Members' as metric,
    COUNT(*) as count
FROM sz_streak_members 
WHERE streak_id = '444efc20-0db3-46a5-86a0-265597be8acd'::uuid

UNION ALL

SELECT 
    'SUMMARY' as check_type,
    'Members with Profiles' as metric,
    COUNT(*) as count
FROM sz_streak_members sm
JOIN profiles p ON sm.user_id = p.id
WHERE sm.streak_id = '444efc20-0db3-46a5-86a0-265597be8acd'::uuid;
