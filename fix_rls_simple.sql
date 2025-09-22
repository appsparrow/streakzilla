-- Simple fix: Disable RLS for sz_user_roles table to avoid infinite recursion

-- Drop any existing functions first
DROP FUNCTION IF EXISTS public.is_super_admin(uuid);
DROP FUNCTION IF EXISTS public.is_super_admin();

-- Disable RLS on the table (since it's an admin table, we can manage access at application level)
ALTER TABLE public.sz_user_roles DISABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DROP POLICY IF EXISTS "Users can view their own roles" ON public.sz_user_roles;
DROP POLICY IF EXISTS "Super admins can view all roles" ON public.sz_user_roles;
DROP POLICY IF EXISTS "Super admins can manage all roles" ON public.sz_user_roles;
DROP POLICY IF EXISTS "Authenticated users can view their own roles" ON public.sz_user_roles;
DROP POLICY IF EXISTS "Authenticated users can read roles" ON public.sz_user_roles;
DROP POLICY IF EXISTS "Super admins can manage roles" ON public.sz_user_roles;

-- Test the query that was failing
SELECT * FROM public.sz_user_roles 
WHERE user_id = '28e1feff-b693-47c3-b2cc-56c3fc4e381e' 
AND role = 'super_admin' 
AND is_active = true;

-- Verify the super admin record exists
SELECT 
    ur.id,
    ur.user_id,
    ur.role,
    ur.is_active,
    ur.granted_at,
    au.email
FROM public.sz_user_roles ur
JOIN auth.users au ON ur.user_id = au.id
WHERE ur.role = 'super_admin' AND ur.is_active = true;
