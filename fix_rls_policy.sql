-- Fix infinite recursion in RLS policy for sz_user_roles

-- Drop the problematic policies that cause infinite recursion
DROP POLICY IF EXISTS "Users can view their own roles" ON public.sz_user_roles;
DROP POLICY IF EXISTS "Super admins can view all roles" ON public.sz_user_roles;
DROP POLICY IF EXISTS "Super admins can manage all roles" ON public.sz_user_roles;

-- Create a simple policy that allows authenticated users to read their own roles
CREATE POLICY "Authenticated users can view their own roles" ON public.sz_user_roles
    FOR SELECT USING (auth.uid() = user_id);

-- Create a policy that allows super admins to manage roles (without recursion)
-- We'll use a function to check super admin status
CREATE OR REPLACE FUNCTION public.is_super_admin(user_uuid UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.sz_user_roles 
        WHERE user_id = user_uuid 
        AND role = 'super_admin' 
        AND is_active = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create policy for super admin management (using the function)
CREATE POLICY "Super admins can manage roles" ON public.sz_user_roles
    FOR ALL USING (public.is_super_admin());

-- Alternative: Create a simple policy that allows all authenticated users to read
-- (for now, we can restrict this later if needed)
-- DROP POLICY IF EXISTS "Authenticated users can view their own roles" ON public.sz_user_roles;
-- CREATE POLICY "Authenticated users can read roles" ON public.sz_user_roles
--     FOR SELECT USING (auth.role() = 'authenticated');

-- Test the function
SELECT public.is_super_admin('28e1feff-b693-47c3-b2cc-56c3fc4e381e');

-- Test direct query
SELECT * FROM public.sz_user_roles 
WHERE user_id = '28e1feff-b693-47c3-b2cc-56c3fc4e381e' 
AND role = 'super_admin' 
AND is_active = true;
