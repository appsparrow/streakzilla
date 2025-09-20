-- =====================================================
-- DEBUG AUTHENTICATION ISSUES
-- =====================================================

-- 1. Check user table structure
SELECT 
    'USER TABLE STRUCTURE' as section,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'auth' AND table_name = 'users'
ORDER BY ordinal_position;

-- 2. Check if streakzilla@gmail.com exists
SELECT 
    'USER LOOKUP' as section,
    id,
    email,
    created_at,
    email_confirmed_at,
    raw_user_meta_data
FROM auth.users 
WHERE email = 'streakzilla@gmail.com';

-- 3. Check recent authentication events
SELECT 
    'RECENT AUTH EVENTS' as section,
    id,
    email,
    created_at,
    email_confirmed_at,
    last_sign_in_at,
    raw_user_meta_data->>'display_name' as display_name
FROM auth.users 
ORDER BY created_at DESC
LIMIT 10;

-- 4. Check for any authentication errors in logs
SELECT 
    'AUTH ERROR CHECK' as section,
    'No direct access to auth logs via SQL' as note,
    'Check Supabase Dashboard > Logs for detailed error information' as recommendation;

-- 5. Check RLS policies on auth tables
SELECT 
    'RLS POLICIES' as section,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'auth' OR schemaname = 'public'
ORDER BY schemaname, tablename, policyname;

-- 6. Check if super admin role exists
SELECT 
    'SUPER ADMIN CHECK' as section,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sz_user_roles') 
        THEN 'sz_user_roles table exists'
        ELSE 'sz_user_roles table does not exist'
    END as table_status;

-- 7. Check super admin users if table exists
SELECT 
    'SUPER ADMIN USERS' as section,
    ur.user_id,
    u.email,
    ur.role,
    ur.is_active,
    ur.granted_at
FROM public.sz_user_roles ur
JOIN auth.users u ON ur.user_id = u.id
WHERE ur.role = 'super_admin'
ORDER BY ur.granted_at DESC;

-- 8. Check template system status
SELECT 
    'TEMPLATE SYSTEM' as section,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sz_templates') 
        THEN 'Templates table exists'
        ELSE 'Templates table does not exist'
    END as templates_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sz_template_habits') 
        THEN 'Template habits table exists'
        ELSE 'Template habits table does not exist'
    END as template_habits_status;

-- 9. Check existing templates
SELECT 
    'EXISTING TEMPLATES' as section,
    t.id,
    t.key,
    t.name,
    t.description,
    COUNT(th.id) as habit_count
FROM public.sz_templates t
LEFT JOIN public.sz_template_habits th ON t.id = th.template_id
GROUP BY t.id, t.key, t.name, t.description
ORDER BY t.name;
