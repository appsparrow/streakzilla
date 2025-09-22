-- Comprehensive streak debugging
-- This will help us understand what's really happening with the streaks

-- 1. Check all streaks and their creators
SELECT 
    'ALL STREAKS' as check_type,
    s.id,
    s.name,
    s.mode,
    s.created_by,
    u.email as created_by_email,
    s.start_date,
    s.is_active
FROM sz_streaks s
LEFT JOIN profiles u ON s.created_by = u.id
ORDER BY s.created_at DESC;

-- 2. Check the specific streak from the frontend
SELECT 
    'SPECIFIC STREAK' as check_type,
    s.id,
    s.name,
    s.mode,
    s.created_by,
    u.email as created_by_email,
    s.start_date,
    s.is_active
FROM sz_streaks s
LEFT JOIN profiles u ON s.created_by = u.id
WHERE s.id = '8d249ba2-55bc-4369-8fad-13b171d165a2'::uuid;

-- 3. Check ALL members for this streak (ignore RLS)
SELECT 
    'ALL MEMBERS FOR STREAK' as check_type,
    sm.streak_id,
    sm.user_id,
    sm.role,
    sm.status,
    sm.joined_at,
    p.email
FROM sz_streak_members sm
LEFT JOIN profiles p ON sm.user_id = p.id
WHERE sm.streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'::uuid
ORDER BY sm.joined_at;

-- 4. Check if the creator is a member
SELECT 
    'CREATOR AS MEMBER' as check_type,
    s.id as streak_id,
    s.created_by as creator_id,
    p.email as creator_email,
    sm.user_id as member_id,
    sm.role,
    sm.status,
    CASE 
        WHEN sm.user_id IS NOT NULL THEN 'YES - Creator is member'
        ELSE 'NO - Creator is NOT a member!'
    END as creator_member_status
FROM sz_streaks s
LEFT JOIN profiles p ON s.created_by = p.id
LEFT JOIN sz_streak_members sm ON s.id = sm.streak_id AND s.created_by = sm.user_id
WHERE s.id = '8d249ba2-55bc-4369-8fad-13b171d165a2'::uuid;

-- 5. Check RLS policies on sz_streak_members
SELECT 
    'RLS POLICIES' as check_type,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'sz_streak_members' 
AND schemaname = 'public';

-- 6. Check if RLS is enabled
SELECT 
    'RLS STATUS' as check_type,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'sz_streak_members' 
AND schemaname = 'public';

-- 7. Try to manually add the creator as a member
INSERT INTO sz_streak_members (
    streak_id, user_id, role, status, joined_at, 
    current_streak, total_points, hearts_available, hearts_earned, hearts_used
)
SELECT 
    s.id,
    s.created_by,
    'admin',
    'active',
    s.created_at,
    0, 0, 0, 0, 0
FROM sz_streaks s
WHERE s.id = '8d249ba2-55bc-4369-8fad-13b171d165a2'::uuid
AND NOT EXISTS (
    SELECT 1 FROM sz_streak_members sm 
    WHERE sm.streak_id = s.id AND sm.user_id = s.created_by
);

-- 8. Check again after adding creator
SELECT 
    'AFTER ADDING CREATOR' as check_type,
    sm.user_id,
    sm.role,
    sm.status,
    p.email
FROM sz_streak_members sm
LEFT JOIN profiles p ON sm.user_id = p.id
WHERE sm.streak_id = '8d249ba2-55bc-4369-8fad-13b171d165a2'::uuid
ORDER BY sm.joined_at;
