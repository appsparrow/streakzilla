-- =====================================================
-- SETUP SUPER ADMIN SYSTEM
-- =====================================================
-- This script creates the super admin system from scratch
-- Run this BEFORE running the migration scripts
-- =====================================================

-- =====================================================
-- STEP 1: CREATE SUPER ADMIN ROLES TABLE
-- =====================================================

-- Create super-admin roles tablea
CREATE TABLE IF NOT EXISTS public.sz_user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'user', -- 'user', 'super_admin', 'template_creator'
  granted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  granted_at TIMESTAMPTZ DEFAULT now(),
  is_active BOOLEAN DEFAULT true,
  UNIQUE(user_id, role)
);

-- =====================================================
-- STEP 2: ENABLE RLS ON NEW TABLE
-- =====================================================

-- Enable RLS on new tables
ALTER TABLE public.sz_user_roles ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 3: CREATE RLS POLICIES
-- =====================================================

-- RLS Policies for sz_user_roles
DROP POLICY IF EXISTS "Users can view their own roles" ON public.sz_user_roles;
CREATE POLICY "Users can view their own roles" ON public.sz_user_roles
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Super admins can manage all roles" ON public.sz_user_roles;
CREATE POLICY "Super admins can manage all roles" ON public.sz_user_roles
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.sz_user_roles ur
      WHERE ur.user_id = auth.uid() 
      AND ur.role = 'super_admin' 
      AND ur.is_active = true
    )
  );

-- =====================================================
-- STEP 4: CREATE HELPER FUNCTIONS
-- =====================================================

-- Function to check if user is super admin
CREATE OR REPLACE FUNCTION public.is_super_admin(user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.sz_user_roles ur
        WHERE ur.user_id = user_id 
        AND ur.role = 'super_admin' 
        AND ur.is_active = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to grant super admin role
CREATE OR REPLACE FUNCTION public.grant_super_admin(target_user_id UUID, granted_by_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if current user is super admin
    IF NOT public.is_super_admin(granted_by_user_id) THEN
        RAISE EXCEPTION 'Only super admins can grant super admin role';
    END IF;
    
    -- Grant the role
    INSERT INTO public.sz_user_roles (user_id, role, granted_by, is_active)
    VALUES (target_user_id, 'super_admin', granted_by_user_id, true)
    ON CONFLICT (user_id, role) 
    DO UPDATE SET is_active = true, granted_at = now();
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 5: CREATE FIRST SUPER ADMIN
-- =====================================================

-- Create the first super admin (you)
DO $$
DECLARE
    admin_user_id UUID;
BEGIN
    -- Get your user ID by email (replace with your email)
    SELECT id INTO admin_user_id 
    FROM auth.users 
    WHERE email = 'streakzilla@gmail.com';
    
    IF admin_user_id IS NOT NULL THEN
        -- Insert super admin role
        INSERT INTO public.sz_user_roles (user_id, role, is_active)
        VALUES (admin_user_id, 'super_admin', true)
        ON CONFLICT (user_id, role) 
        DO UPDATE SET is_active = true, granted_at = now();
        
        RAISE NOTICE 'Super admin role granted to user: %', admin_user_id;
    ELSE
        RAISE NOTICE 'User streakzilla@gmail.com not found. Please create an account first.';
    END IF;
END $$;

-- =====================================================
-- STEP 6: VERIFICATION
-- =====================================================

-- Check if super admin system is working
SELECT 
    'SUPER ADMIN SYSTEM STATUS' as section,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sz_user_roles') 
        THEN 'sz_user_roles table created successfully'
        ELSE 'sz_user_roles table creation failed'
    END as table_status;

-- Check super admin users
SELECT 
    'SUPER ADMIN USERS' as section,
    ur.user_id,
    u.email,
    ur.role,
    ur.granted_at,
    ur.is_active
FROM public.sz_user_roles ur
JOIN auth.users u ON ur.user_id = u.id
WHERE ur.role = 'super_admin' AND ur.is_active = true;

-- Test the helper function
SELECT 
    'HELPER FUNCTION TEST' as section,
    public.is_super_admin() as is_current_user_super_admin;

-- =====================================================
-- STEP 7: NEXT STEPS
-- =====================================================

SELECT 
    'NEXT STEPS' as section,
    'Super admin system is now ready!' as message,
    'You can now run the template migration scripts.' as instruction;
