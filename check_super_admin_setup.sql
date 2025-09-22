-- Check Super Admin Setup
-- This script checks if the super admin system is properly set up

-- 1. Check if sz_user_roles table exists
SELECT 
    'TABLE EXISTS' as check_type,
    table_name,
    table_schema
FROM information_schema.tables 
WHERE table_name = 'sz_user_roles' 
AND table_schema = 'public';

-- 2. Check if the table has data
SELECT 
    'TABLE DATA' as check_type,
    COUNT(*) as row_count
FROM sz_user_roles;

-- 3. Check super admin user
SELECT 
    'SUPER ADMIN USER' as check_type,
    ur.user_id,
    u.email,
    ur.role,
    ur.is_active,
    ur.granted_at
FROM sz_user_roles ur
JOIN auth.users u ON ur.user_id = u.id
WHERE ur.role = 'super_admin' 
AND ur.is_active = true;

-- 4. Check if RLS is enabled on the table
SELECT 
    'RLS STATUS' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'sz_user_roles' 
AND schemaname = 'public';

-- 5. Check policies on the table
SELECT 
    'POLICIES' as check_type,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'sz_user_roles' 
AND schemaname = 'public';
