-- =====================================================
-- COMPLETE SYSTEM SETUP
-- =====================================================
-- This script sets up the entire super admin and template system
-- Run this script in Supabase SQL Editor
-- =====================================================

-- =====================================================
-- STEP 1: CREATE SUPER ADMIN SYSTEM
-- =====================================================

-- Create super-admin roles table
CREATE TABLE IF NOT EXISTS public.sz_user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'user', -- 'user', 'super_admin', 'template_creator'
  granted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  granted_at TIMESTAMPTZ DEFAULT now(),
  is_active BOOLEAN DEFAULT true,
  UNIQUE(user_id, role)
);

-- Enable RLS
ALTER TABLE public.sz_user_roles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
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
-- STEP 2: CREATE TEMPLATE SYSTEM
-- =====================================================

-- Create templates table
CREATE TABLE IF NOT EXISTS public.sz_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT NULL,
  allow_custom_habits BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create template habits mapping table
CREATE TABLE IF NOT EXISTS public.sz_template_habits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID NOT NULL REFERENCES public.sz_templates(id) ON DELETE CASCADE,
  habit_id UUID NOT NULL REFERENCES public.sz_habits(id) ON DELETE CASCADE,
  is_core BOOLEAN NOT NULL DEFAULT true,
  points_override INTEGER NULL,
  sort_order INTEGER NULL,
  CONSTRAINT sz_template_habits_unique UNIQUE (template_id, habit_id)
);

-- Add template_id to streaks
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'sz_streaks' AND column_name = 'template_id'
  ) THEN
    ALTER TABLE public.sz_streaks
      ADD COLUMN template_id UUID NULL REFERENCES public.sz_templates(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Enable RLS on template tables
ALTER TABLE public.sz_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sz_template_habits ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for templates
DROP POLICY IF EXISTS "Everyone can read templates" ON public.sz_templates;
CREATE POLICY "Everyone can read templates" ON public.sz_templates
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Templates: insert by authenticated" ON public.sz_templates;
CREATE POLICY "Templates: insert by authenticated" ON public.sz_templates
  FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Templates: update by authenticated" ON public.sz_templates;
CREATE POLICY "Templates: update by authenticated" ON public.sz_templates
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Templates: delete by authenticated" ON public.sz_templates;
CREATE POLICY "Templates: delete by authenticated" ON public.sz_templates
  FOR DELETE TO authenticated USING (true);

-- Create RLS policies for template habits
DROP POLICY IF EXISTS "Everyone can read template_habits" ON public.sz_template_habits;
CREATE POLICY "Everyone can read template_habits" ON public.sz_template_habits
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "TemplateHabits: insert by authenticated" ON public.sz_template_habits;
CREATE POLICY "TemplateHabits: insert by authenticated" ON public.sz_template_habits
  FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "TemplateHabits: update by authenticated" ON public.sz_template_habits;
CREATE POLICY "TemplateHabits: update by authenticated" ON public.sz_template_habits
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "TemplateHabits: delete by authenticated" ON public.sz_template_habits;
CREATE POLICY "TemplateHabits: delete by authenticated" ON public.sz_template_habits
  FOR DELETE TO authenticated USING (true);

-- =====================================================
-- STEP 3: SEED TEMPLATES
-- =====================================================

-- Seed basic templates
INSERT INTO public.sz_templates (key, name, description, allow_custom_habits)
VALUES
  ('75_hard', '75 Hard', 'The original 75 Hard challenge with 5 core habits', false),
  ('75_hard_plus', '75 Hard Plus', '75 Hard Plus with additional habits and no lives', true),
  ('custom', 'Custom', 'Create your own custom challenge', true)
ON CONFLICT (key) DO NOTHING;

-- =====================================================
-- STEP 4: MIGRATE HABITS TO TEMPLATES
-- =====================================================

-- Map 75 Hard habits
INSERT INTO public.sz_template_habits (template_id, habit_id, is_core, sort_order)
SELECT 
    t.id as template_id,
    h.id as habit_id,
    true as is_core,
    ROW_NUMBER() OVER (ORDER BY h.title) as sort_order
FROM public.sz_templates t
CROSS JOIN public.sz_habits h
WHERE t.key = '75_hard' 
  AND h.template_set = '75_hard'
ON CONFLICT (template_id, habit_id) DO NOTHING;

-- Map 75 Hard Plus habits (core habits)
INSERT INTO public.sz_template_habits (template_id, habit_id, is_core, sort_order)
SELECT 
    t.id as template_id,
    h.id as habit_id,
    true as is_core,
    ROW_NUMBER() OVER (ORDER BY h.title) as sort_order
FROM public.sz_templates t
CROSS JOIN public.sz_habits h
WHERE t.key = '75_hard_plus' 
  AND h.template_set = '75_hard'
ON CONFLICT (template_id, habit_id) DO NOTHING;

-- Map 75 Hard Plus habits (optional habits)
INSERT INTO public.sz_template_habits (template_id, habit_id, is_core, sort_order)
SELECT 
    t.id as template_id,
    h.id as habit_id,
    false as is_core,
    ROW_NUMBER() OVER (ORDER BY h.title) + 10 as sort_order
FROM public.sz_templates t
CROSS JOIN public.sz_habits h
WHERE t.key = '75_hard_plus' 
  AND h.template_set = '75_hard_plus'
ON CONFLICT (template_id, habit_id) DO NOTHING;

-- =====================================================
-- STEP 5: UPDATE EXISTING STREAKS
-- =====================================================

-- Update streaks to use template_id
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
-- STEP 6: CREATE SUPER ADMIN USER
-- =====================================================

-- Create the first super admin (you)
DO $$
DECLARE
    admin_user_id UUID;
BEGIN
    -- Get your user ID by email
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
-- STEP 7: CREATE HELPER FUNCTIONS
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

-- =====================================================
-- STEP 8: VERIFICATION
-- =====================================================

-- Check system status
SELECT 
    'SYSTEM SETUP COMPLETE' as section,
    'All tables and policies created successfully' as status;

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

-- Check templates
SELECT 
    'TEMPLATES CREATED' as section,
    t.key,
    t.name,
    t.description,
    COUNT(th.id) as habit_count
FROM public.sz_templates t
LEFT JOIN public.sz_template_habits th ON t.id = th.template_id
GROUP BY t.id, t.key, t.name, t.description
ORDER BY t.name;

-- Check streaks with templates
SELECT 
    'STREAKS MIGRATION' as section,
    COUNT(*) as total_streaks,
    COUNT(CASE WHEN template_id IS NOT NULL THEN 1 END) as streaks_with_templates,
    COUNT(CASE WHEN template_id IS NULL THEN 1 END) as streaks_without_templates
FROM public.sz_streaks;

-- =====================================================
-- STEP 9: SUCCESS MESSAGE
-- =====================================================

SELECT 
    'SUCCESS' as section,
    'Super admin and template system is now ready!' as message,
    'You can now access the TemplateManager page in the app.' as instruction;
