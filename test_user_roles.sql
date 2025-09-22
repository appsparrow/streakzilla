-- Test script to verify sz_user_roles table and super admin setup

-- Check if table exists
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'sz_user_roles' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check super admin records
SELECT 
    ur.id,
    ur.user_id,
    au.email,
    ur.role,
    ur.is_active,
    ur.created_at
FROM public.sz_user_roles ur
JOIN auth.users au ON ur.user_id = au.id
WHERE ur.role = 'super_admin' AND ur.is_active = true;

-- Check if streakzilla@gmail.com user exists
SELECT 
    id,
    email,
    created_at
FROM auth.users 
WHERE email = 'streakzilla@gmail.com';

-- Test query that the frontend will use
SELECT 
    ur.*
FROM public.sz_user_roles ur
WHERE ur.user_id = (
    SELECT id FROM auth.users WHERE email = 'streakzilla@gmail.com'
)
AND ur.role = 'super_admin' 
AND ur.is_active = true;
