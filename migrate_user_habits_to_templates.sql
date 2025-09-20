-- =====================================================
-- MIGRATE USER HABITS TO NEW TEMPLATE SYSTEM
-- =====================================================
-- 
-- This script analyzes and migrates existing user_habits data
-- to work with the new sz_templates and sz_template_habits system
-- =====================================================

-- =====================================================
-- STEP 1: ANALYSIS OF CURRENT DATA
-- =====================================================

-- Analyze current user habits by streak mode
WITH user_habits_analysis AS (
    SELECT 
        s.mode,
        s.template_id,
        COUNT(DISTINCT s.id) as streak_count,
        COUNT(DISTINCT uh.user_id) as unique_users,
        COUNT(DISTINCT uh.habit_id) as unique_habits,
        COUNT(uh.id) as total_user_habits,
        ARRAY_AGG(DISTINCT h.title ORDER BY h.title) as habit_titles
    FROM public.sz_user_habits uh
    JOIN public.sz_streaks s ON uh.streak_id = s.id
    JOIN public.sz_habits h ON uh.habit_id = h.id
    GROUP BY s.mode, s.template_id
)
SELECT 
    'USER HABITS ANALYSIS' as section,
    mode,
    template_id,
    streak_count,
    unique_users,
    unique_habits,
    total_user_habits,
    habit_titles
FROM user_habits_analysis
ORDER BY mode;

-- =====================================================
-- STEP 2: IDENTIFY HABITS THAT NEED TEMPLATE MAPPING
-- =====================================================

-- Find habits that are used in streaks but not in templates
WITH habits_in_use AS (
    SELECT DISTINCT h.id, h.title, h.template_set
    FROM public.sz_user_habits uh
    JOIN public.sz_habits h ON uh.habit_id = h.id
),
habits_in_templates AS (
    SELECT DISTINCT h.id, h.title
    FROM public.sz_template_habits th
    JOIN public.sz_habits h ON th.habit_id = h.id
)
SELECT 
    'HABITS NOT IN TEMPLATES' as section,
    hiu.title,
    hiu.template_set,
    COUNT(DISTINCT uh.streak_id) as used_in_streaks
FROM habits_in_use hiu
LEFT JOIN habits_in_templates hit ON hiu.id = hit.id
JOIN public.sz_user_habits uh ON hiu.id = uh.habit_id
WHERE hit.id IS NULL
GROUP BY hiu.id, hiu.title, hiu.template_set
ORDER BY used_in_streaks DESC;

-- =====================================================
-- STEP 3: MIGRATE HABITS TO APPROPRIATE TEMPLATES
-- =====================================================

-- Add missing habits to templates based on their template_set
INSERT INTO public.sz_template_habits (template_id, habit_id, is_core, sort_order)
SELECT 
    t.id as template_id,
    h.id as habit_id,
    CASE 
        WHEN h.template_set = '75_hard' THEN true
        WHEN h.template_set = '75_hard_plus' THEN true
        WHEN h.template_set = 'custom' THEN false
        ELSE false
    END as is_core,
    ROW_NUMBER() OVER (PARTITION BY h.template_set ORDER BY h.title) as sort_order
FROM public.sz_habits h
JOIN public.sz_templates t ON t.key = h.template_set
WHERE NOT EXISTS (
    SELECT 1 FROM public.sz_template_habits th 
    WHERE th.template_id = t.id AND th.habit_id = h.id
)
AND h.template_set IN ('75_hard', '75_hard_plus', 'custom');

-- =====================================================
-- STEP 4: UPDATE STREAKS TO USE TEMPLATES
-- =====================================================

-- Update streaks that don't have template_id set
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
-- STEP 5: CREATE CUSTOM TEMPLATES FOR UNIQUE COMBINATIONS
-- =====================================================

-- Find unique habit combinations that don't match standard templates
WITH unique_habit_combinations AS (
    SELECT 
        s.id as streak_id,
        s.mode,
        ARRAY_AGG(h.title ORDER BY h.title) as habit_combination,
        COUNT(*) as habit_count
    FROM public.sz_user_habits uh
    JOIN public.sz_streaks s ON uh.streak_id = s.id
    JOIN public.sz_habits h ON uh.habit_id = h.id
    WHERE s.mode = 'custom' OR s.template_id IS NULL
    GROUP BY s.id, s.mode
    HAVING COUNT(*) > 0
)
SELECT 
    'UNIQUE HABIT COMBINATIONS' as section,
    mode,
    habit_combination,
    COUNT(*) as streak_count,
    habit_count
FROM unique_habit_combinations
GROUP BY mode, habit_combination, habit_count
ORDER BY streak_count DESC, habit_count DESC;

-- =====================================================
-- STEP 6: MIGRATION VERIFICATION
-- =====================================================

-- Check what was migrated
SELECT 
    'MIGRATION VERIFICATION' as section,
    'Templates' as type,
    COUNT(*) as count
FROM public.sz_templates

UNION ALL

SELECT 
    'MIGRATION VERIFICATION' as section,
    'Template Habits' as type,
    COUNT(*) as count
FROM public.sz_template_habits

UNION ALL

SELECT 
    'MIGRATION VERIFICATION' as section,
    'Streaks with Templates' as type,
    COUNT(*) as count
FROM public.sz_streaks
WHERE template_id IS NOT NULL

UNION ALL

SELECT 
    'MIGRATION VERIFICATION' as section,
    'User Habits' as type,
    COUNT(*) as count
FROM public.sz_user_habits;

-- =====================================================
-- STEP 7: DETAILED TEMPLATE ANALYSIS
-- =====================================================

-- Show detailed template mappings
SELECT 
    'DETAILED TEMPLATE MAPPINGS' as section,
    t.name as template_name,
    t.key,
    h.title as habit_title,
    th.is_core,
    th.points_override,
    th.sort_order,
    h.points as default_points,
    h.template_set
FROM public.sz_templates t
JOIN public.sz_template_habits th ON t.id = th.template_id
JOIN public.sz_habits h ON th.habit_id = h.id
ORDER BY t.name, th.sort_order, h.title;

-- =====================================================
-- STEP 8: USER HABITS COMPATIBILITY CHECK
-- =====================================================

-- Check if user habits are compatible with new template system
WITH user_habits_by_template AS (
    SELECT 
        s.template_id,
        t.name as template_name,
        COUNT(DISTINCT uh.user_id) as users_with_habits,
        COUNT(DISTINCT uh.habit_id) as unique_habits_used,
        ARRAY_AGG(DISTINCT h.title ORDER BY h.title) as habit_titles
    FROM public.sz_user_habits uh
    JOIN public.sz_streaks s ON uh.streak_id = s.id
    JOIN public.sz_templates t ON s.template_id = t.id
    JOIN public.sz_habits h ON uh.habit_id = h.id
    WHERE s.template_id IS NOT NULL
    GROUP BY s.template_id, t.name
)
SELECT 
    'USER HABITS BY TEMPLATE' as section,
    template_name,
    users_with_habits,
    unique_habits_used,
    habit_titles
FROM user_habits_by_template
ORDER BY template_name;

-- =====================================================
-- STEP 9: RECOMMENDATIONS
-- =====================================================

-- Generate recommendations for template improvements
WITH template_usage AS (
    SELECT 
        t.id as template_id,
        t.name as template_name,
        COUNT(DISTINCT s.id) as streak_count,
        COUNT(DISTINCT uh.user_id) as user_count,
        COUNT(DISTINCT uh.habit_id) as habit_count
    FROM public.sz_templates t
    LEFT JOIN public.sz_streaks s ON t.id = s.template_id
    LEFT JOIN public.sz_user_habits uh ON s.id = uh.streak_id
    GROUP BY t.id, t.name
)
SELECT 
    'TEMPLATE USAGE RECOMMENDATIONS' as section,
    template_name,
    streak_count,
    user_count,
    habit_count,
    CASE 
        WHEN streak_count = 0 THEN 'Consider removing or updating template'
        WHEN habit_count = 0 THEN 'No habits assigned - needs setup'
        WHEN user_count > 0 THEN 'Active template - consider optimizing'
        ELSE 'Template ready for use'
    END as recommendation
FROM template_usage
ORDER BY streak_count DESC;

-- =====================================================
-- STEP 10: CLEANUP SUGGESTIONS
-- =====================================================

-- Identify potential cleanup opportunities
SELECT 
    'CLEANUP SUGGESTIONS' as section,
    'Orphaned User Habits' as type,
    COUNT(*) as count
FROM public.sz_user_habits uh
WHERE NOT EXISTS (
    SELECT 1 FROM public.sz_streaks s WHERE s.id = uh.streak_id
)

UNION ALL

SELECT 
    'CLEANUP SUGGESTIONS' as section,
    'Streaks without Templates' as type,
    COUNT(*) as count
FROM public.sz_streaks s
WHERE s.template_id IS NULL

UNION ALL

SELECT 
    'CLEANUP SUGGESTIONS' as section,
    'Unused Habits' as type,
    COUNT(*) as count
FROM public.sz_habits h
WHERE NOT EXISTS (
    SELECT 1 FROM public.sz_user_habits uh WHERE uh.habit_id = h.id
    UNION
    SELECT 1 FROM public.sz_template_habits th WHERE th.habit_id = h.id
);
