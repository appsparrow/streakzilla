-- =====================================================
-- CHECK ADMIN ACCESS ISSUE
-- =====================================================
-- This script helps debug why the admin section isn't showing
-- =====================================================

-- Check if you have super admin role
SELECT 
    'SUPER ADMIN CHECK' as section,
    ur.user_id,
    u.email,
    ur.role,
    ur.is_active,
    ur.granted_at
FROM public.sz_user_roles ur
JOIN auth.users u ON ur.user_id = u.id
WHERE ur.role = 'super_admin' AND ur.is_active = true;

-- Check all your roles
SELECT 
    'ALL YOUR ROLES' as section,
    ur.user_id,
    u.email,
    ur.role,
    ur.is_active,
    ur.granted_at
FROM public.sz_user_roles ur
JOIN auth.users u ON ur.user_id = u.id
WHERE u.email = 'streakzilla@gmail.com'
ORDER BY ur.role;

-- Check if the table exists and has data
SELECT 
    'TABLE STATUS' as section,
    COUNT(*) as total_roles,
    COUNT(CASE WHEN role = 'super_admin' THEN 1 END) as super_admins,
    COUNT(CASE WHEN role = 'template_creator' THEN 1 END) as template_creators
FROM public.sz_user_roles
WHERE is_active = true;

-- Check recent activity
SELECT 
    'RECENT ROLE GRANTS' as section,
    ur.user_id,
    u.email,
    ur.role,
    ur.granted_by,
    ur.granted_at,
    ur.is_active
FROM public.sz_user_roles ur
JOIN auth.users u ON ur.user_id = u.id
ORDER BY ur.granted_at DESC
LIMIT 10;
