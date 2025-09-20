-- =====================================================
-- SETUP TEMPLATE SYSTEM
-- =====================================================
-- This script creates the template system from scratch
-- Run this AFTER running setup_super_admin_system.sql
-- =====================================================

-- =====================================================
-- STEP 1: CREATE TEMPLATES TABLE
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

-- =====================================================
-- STEP 2: CREATE TEMPLATE HABITS TABLE
-- =====================================================

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

-- =====================================================
-- STEP 3: ADD TEMPLATE_ID TO STREAKS
-- =====================================================

-- Add template_id column to streaks table
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

-- =====================================================
-- STEP 4: ENABLE RLS ON NEW TABLES
-- =====================================================

-- Enable RLS on new tables
ALTER TABLE public.sz_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sz_template_habits ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 5: CREATE RLS POLICIES
-- =====================================================

-- RLS Policies for templates (allow read-only for everyone)
DROP POLICY IF EXISTS "Everyone can read templates" ON public.sz_templates;
CREATE POLICY "Everyone can read templates" ON public.sz_templates
  FOR SELECT USING (true);

-- Allow authenticated users to manage templates
DROP POLICY IF EXISTS "Templates: insert by authenticated" ON public.sz_templates;
CREATE POLICY "Templates: insert by authenticated" ON public.sz_templates
  FOR INSERT TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Templates: update by authenticated" ON public.sz_templates;
CREATE POLICY "Templates: update by authenticated" ON public.sz_templates
  FOR UPDATE TO authenticated
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Templates: delete by authenticated" ON public.sz_templates;
CREATE POLICY "Templates: delete by authenticated" ON public.sz_templates
  FOR DELETE TO authenticated
  USING (true);

-- RLS Policies for template habits
DROP POLICY IF EXISTS "Everyone can read template_habits" ON public.sz_template_habits;
CREATE POLICY "Everyone can read template_habits" ON public.sz_template_habits
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "TemplateHabits: insert by authenticated" ON public.sz_template_habits;
CREATE POLICY "TemplateHabits: insert by authenticated" ON public.sz_template_habits
  FOR INSERT TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "TemplateHabits: update by authenticated" ON public.sz_template_habits;
CREATE POLICY "TemplateHabits: update by authenticated" ON public.sz_template_habits
  FOR UPDATE TO authenticated
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "TemplateHabits: delete by authenticated" ON public.sz_template_habits;
CREATE POLICY "TemplateHabits: delete by authenticated" ON public.sz_template_habits
  FOR DELETE TO authenticated
  USING (true);

-- =====================================================
-- STEP 6: SEED BASIC TEMPLATES
-- =====================================================

-- Seed basic templates (idempotent)
INSERT INTO public.sz_templates (key, name, description, allow_custom_habits)
VALUES
  ('75_hard', '75 Hard', 'The original 75 Hard challenge with 5 core habits', false),
  ('75_hard_plus', '75 Hard Plus', '75 Hard Plus with additional habits and no lives', true),
  ('custom', 'Custom', 'Create your own custom challenge', true)
ON CONFLICT (key) DO NOTHING;

-- =====================================================
-- STEP 7: MIGRATE EXISTING HABITS TO TEMPLATES
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
-- STEP 8: UPDATE EXISTING STREAKS TO USE TEMPLATES
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
-- STEP 9: VERIFICATION
-- =====================================================

-- Check template system status
SELECT 
    'TEMPLATE SYSTEM STATUS' as section,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sz_templates') 
        THEN 'Templates table created successfully'
        ELSE 'Templates table creation failed'
    END as templates_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sz_template_habits') 
        THEN 'Template habits table created successfully'
        ELSE 'Template habits table creation failed'
    END as template_habits_status;

-- Check existing templates
SELECT 
    'EXISTING TEMPLATES' as section,
    t.id,
    t.key,
    t.name,
    t.description,
    t.allow_custom_habits,
    COUNT(th.id) as habit_count
FROM public.sz_templates t
LEFT JOIN public.sz_template_habits th ON t.id = th.template_id
GROUP BY t.id, t.key, t.name, t.description, t.allow_custom_habits
ORDER BY t.name;

-- Check template habits mapping
SELECT 
    'TEMPLATE HABITS MAPPING' as section,
    t.name as template_name,
    h.title as habit_title,
    th.is_core,
    th.points_override,
    th.sort_order
FROM public.sz_template_habits th
JOIN public.sz_templates t ON th.template_id = t.id
JOIN public.sz_habits h ON th.habit_id = h.id
ORDER BY t.name, th.sort_order, h.title;

-- Check streaks with templates
SELECT 
    'STREAKS WITH TEMPLATES' as section,
    COUNT(*) as total_streaks,
    COUNT(CASE WHEN template_id IS NOT NULL THEN 1 END) as streaks_with_templates,
    COUNT(CASE WHEN template_id IS NULL THEN 1 END) as streaks_without_templates
FROM public.sz_streaks;

-- =====================================================
-- STEP 10: NEXT STEPS
-- =====================================================

SELECT 
    'NEXT STEPS' as section,
    'Template system is now ready!' as message,
    'You can now use the TemplateManager page in the app.' as instruction;
