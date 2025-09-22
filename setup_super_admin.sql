-- Setup super admin role for streakzilla@gmail.com
-- This will create the super admin role and grant access

-- First, let's find the user ID for streakzilla@gmail.com
SELECT 
    'FIND_USER' as action,
    id,
    email,
    created_at
FROM auth.users 
WHERE email = 'streakzilla@gmail.com';

-- Create super admin role (replace USER_ID with actual ID from above query)
INSERT INTO public.sz_user_roles (
    user_id,
    role,
    granted_by,
    granted_at,
    is_active
)
SELECT 
    u.id,
    'super_admin',
    u.id, -- Self-granted
    now(),
    true
FROM auth.users u
WHERE u.email = 'streakzilla@gmail.com'
ON CONFLICT (user_id, role) 
DO UPDATE SET 
    is_active = true,
    granted_at = now();

-- Verify the role was created
SELECT 
    'VERIFY_ROLE' as action,
    ur.user_id,
    u.email,
    ur.role,
    ur.is_active,
    ur.granted_at
FROM public.sz_user_roles ur
JOIN auth.users u ON u.id = ur.user_id
WHERE u.email = 'streakzilla@gmail.com';
