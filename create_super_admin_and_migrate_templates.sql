-- =====================================================
-- CREATE SUPER ADMIN AND MIGRATE TEMPLATE DATA
-- =====================================================

-- =====================================================
-- STEP 1: CREATE SUPER ADMIN USER
-- =====================================================

-- First, let's check if you want to make yourself a super admin
-- Replace 'YOUR_EMAIL_HERE' with your actual email address
DO $$
DECLARE
    admin_user_id UUID;
BEGIN
    -- Get your user ID by email (replace with your email)
    SELECT id INTO admin_user_id 
    FROM auth.users 
    WHERE email = 'streakzilla@gmail.com';  -- REPLACE THIS WITH YOUR EMAIL
    
    IF admin_user_id IS NOT NULL THEN
        -- Insert super admin role
        INSERT INTO public.sz_user_roles (user_id, role, is_active)
        VALUES (admin_user_id, 'super_admin', true)
        ON CONFLICT (user_id, role) 
        DO UPDATE SET is_active = true, granted_at = now();
        
        RAISE NOTICE 'Super admin role granted to user: %', admin_user_id;
    ELSE
        RAISE NOTICE 'User not found. Please replace YOUR_EMAIL_HERE with your actual email address.';
    END IF;
END $$;

-- =====================================================
-- STEP 2: MIGRATE EXISTING HABITS TO TEMPLATE SYSTEM
-- =====================================================

-- Create template habits from existing sz_habits data
INSERT INTO public.sz_template_habits (template_id, habit_id, is_core, sort_order)
SELECT 
    t.id as template_id,
    h.id as habit_id,
    CASE 
        WHEN h.template_set = '75_hard' THEN true
        WHEN h.template_set = '75_hard_plus' THEN true
        ELSE false
    END as is_core,
    ROW_NUMBER() OVER (PARTITION BY h.template_set ORDER BY h.title) as sort_order
FROM public.sz_habits h
JOIN public.sz_templates t ON t.key = h.template_set
WHERE h.template_set IN ('75_hard', '75_hard_plus', 'custom')
ON CONFLICT (template_id, habit_id) DO NOTHING;

-- =====================================================
-- STEP 3: MIGRATE EXISTING STREAKS TO USE TEMPLATES
-- =====================================================

-- Update streaks to use template_id instead of mode
UPDATE public.sz_streaks s
SET template_id = t.id
FROM public.sz_templates t
WHERE s.template_id IS NULL 
  AND t.key = CASE 
    WHEN s.mode = '75_hard' THEN '75_hard'
    WHEN s.mode = '75_hard_plus' THEN '75_hard_plus'
    WHEN s.mode = 'custom' THEN 'custom'
    ELSE 'custom'
  END;

-- =====================================================
-- STEP 4: MIGRATE USER HABITS TO NEW SYSTEM
-- =====================================================

-- This will help identify user habits that should be migrated
-- The new system uses sz_template_habits to determine which habits are core
-- and sz_user_habits to track which habits each user selected

-- First, let's see what we're working with
SELECT 
    'MIGRATION ANALYSIS' as section,
    s.mode,
    s.template_id,
    COUNT(DISTINCT s.id) as streak_count,
    COUNT(DISTINCT uh.id) as user_habit_count,
    COUNT(DISTINCT h.id) as unique_habits
FROM public.sz_streaks s
LEFT JOIN public.sz_user_habits uh ON s.id = uh.streak_id
LEFT JOIN public.sz_habits h ON uh.habit_id = h.id
GROUP BY s.mode, s.template_id
ORDER BY s.mode;

-- =====================================================
-- STEP 5: CREATE MIGRATION REPORT
-- =====================================================

-- Report on what was migrated
SELECT 
    'MIGRATION SUMMARY' as section,
    'Templates' as type,
    COUNT(*) as count
FROM public.sz_templates

UNION ALL

SELECT 
    'MIGRATION SUMMARY' as section,
    'Template Habits' as type,
    COUNT(*) as count
FROM public.sz_template_habits

UNION ALL

SELECT 
    'MIGRATION SUMMARY' as section,
    'Streaks with Templates' as type,
    COUNT(*) as count
FROM public.sz_streaks
WHERE template_id IS NOT NULL

UNION ALL

SELECT 
    'MIGRATION SUMMARY' as section,
    'User Habits' as type,
    COUNT(*) as count
FROM public.sz_user_habits;

-- =====================================================
-- STEP 6: VERIFICATION QUERIES
-- =====================================================

-- Check super admin status
SELECT 
    'SUPER ADMIN VERIFICATION' as section,
    u.email,
    ur.role,
    ur.is_active,
    ur.granted_at
FROM public.sz_user_roles ur
JOIN auth.users u ON ur.user_id = u.id
WHERE ur.role = 'super_admin' AND ur.is_active = true;

-- Check template system
SELECT 
    'TEMPLATE SYSTEM VERIFICATION' as section,
    t.name as template_name,
    t.key,
    COUNT(th.id) as habit_count,
    COUNT(CASE WHEN th.is_core = true THEN 1 END) as core_habits,
    COUNT(CASE WHEN th.is_core = false THEN 1 END) as optional_habits
FROM public.sz_templates t
LEFT JOIN public.sz_template_habits th ON t.id = th.template_id
GROUP BY t.id, t.name, t.key
ORDER BY t.name;

-- Check streaks with templates
SELECT 
    'STREAKS WITH TEMPLATES' as section,
    s.name as streak_name,
    s.mode,
    t.name as template_name,
    s.template_id,
    s.created_at
FROM public.sz_streaks s
LEFT JOIN public.sz_templates t ON s.template_id = t.id
ORDER BY s.created_at DESC
LIMIT 10;

-- =====================================================
-- STEP 7: HELPER FUNCTIONS FOR SUPER ADMIN
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
-- INSTRUCTIONS FOR USE
-- =====================================================

/*
TO USE THIS SCRIPT:

1. REPLACE 'YOUR_EMAIL_HERE' with your actual email address
2. Run this script in Supabase SQL Editor
3. Check the verification queries to confirm everything worked
4. You should now have super admin access to the template system

SUPER ADMIN CAPABILITIES:
- Access to TemplateManager page in the app
- Ability to create, edit, and delete templates
- Ability to manage template habits
- Ability to grant super admin roles to other users

NEXT STEPS:
- Use the TemplateManager page to refine template configurations
- Migrate any remaining user habits as needed
- Set up proper template mappings for new streaks
*/
