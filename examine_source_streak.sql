-- Examine Source Streak Before Replication
-- This script shows what data exists in the source streak

-- 1. Basic streak information
SELECT 
    'STREAK INFO' as check_type,
    s.id,
    s.name,
    s.mode,
    s.duration_days,
    s.start_date,
    (s.start_date + INTERVAL '75 days')::date as calculated_end_date,
    s.is_active,
    s.created_by,
    u.email as created_by_email
FROM sz_streaks s
LEFT JOIN auth.users u ON s.created_by = u.id
WHERE s.id = '55e675ae-6937-4ece-a5b6-156115a797d2'::uuid;

-- 2. Users in the streak
SELECT 
    'STREAK USERS' as check_type,
    sm.user_id,
    u.email,
    sm.role,
    sm.status,
    sm.joined_at,
    sm.current_streak,
    sm.total_points,
    sm.hearts_available,
    sm.hearts_earned,
    sm.hearts_used
FROM sz_streak_members sm
JOIN auth.users u ON sm.user_id = u.id
WHERE sm.streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2'::uuid
ORDER BY sm.role, u.email;

-- 3. Habits assigned to users
SELECT 
    'USER HABITS' as check_type,
    sm.user_id,
    u.email,
    uh.habit_id,
    h.description as habit_description,
    h.points as habit_points,
    h.category,
    uh.points_override
FROM sz_streak_members sm
JOIN auth.users u ON sm.user_id = u.id
JOIN sz_user_habits uh ON sm.streak_id = uh.streak_id AND sm.user_id = uh.user_id
JOIN sz_habits h ON uh.habit_id = h.id
WHERE sm.streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2'::uuid
ORDER BY u.email, h.description;

-- 4. Summary counts
SELECT 
    'SUMMARY' as check_type,
    'Users' as data_type,
    COUNT(DISTINCT sm.user_id) as count
FROM sz_streak_members sm
WHERE sm.streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2'::uuid

UNION ALL

SELECT 
    'SUMMARY' as check_type,
    'User-Habit Assignments' as data_type,
    COUNT(uh.id) as count
FROM sz_streak_members sm
JOIN sz_user_habits uh ON sm.streak_id = uh.streak_id AND sm.user_id = uh.user_id
WHERE sm.streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2'::uuid

UNION ALL

SELECT 
    'SUMMARY' as check_type,
    'Unique Habits' as data_type,
    COUNT(DISTINCT uh.habit_id) as count
FROM sz_streak_members sm
JOIN sz_user_habits uh ON sm.streak_id = uh.streak_id AND sm.user_id = uh.user_id
WHERE sm.streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2'::uuid

UNION ALL

SELECT 
    'SUMMARY' as check_type,
    'Total Check-ins' as data_type,
    COUNT(c.id) as count
FROM sz_streak_members sm
JOIN sz_checkins c ON sm.streak_id = c.streak_id AND sm.user_id = c.user_id
WHERE sm.streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2'::uuid;
