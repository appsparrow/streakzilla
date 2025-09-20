-- =====================================================
-- FIX DUPLICATE "FOLLOW A DIET" HABIT
-- =====================================================
-- This script removes the duplicate "Follow a diet" habit
-- =====================================================

-- Check current duplicates
SELECT 
    'DUPLICATE HABITS CHECK' as section,
    h.title,
    h.id,
    h.points,
    h.template_set,
    COUNT(*) as count
FROM public.sz_habits h
WHERE h.title = 'Follow a diet'
GROUP BY h.id, h.title, h.points, h.template_set
ORDER BY h.points DESC;

-- Check template mappings for "Follow a diet"
SELECT 
    'TEMPLATE MAPPINGS FOR FOLLOW A DIET' as section,
    t.name as template_name,
    h.title,
    h.id,
    h.points,
    th.is_core,
    th.points_override,
    th.sort_order
FROM public.sz_template_habits th
JOIN public.sz_templates t ON th.template_id = t.id
JOIN public.sz_habits h ON th.habit_id = h.id
WHERE h.title = 'Follow a diet'
ORDER BY t.name, th.sort_order;

-- Find the habit with 0 points (this is likely the duplicate)
SELECT 
    'HABIT TO REMOVE' as section,
    h.id,
    h.title,
    h.points,
    h.template_set,
    'This habit has 0 points and should be removed' as action
FROM public.sz_habits h
WHERE h.title = 'Follow a diet' AND h.points = 0;

-- Remove the duplicate habit with 0 points
DELETE FROM public.sz_habits 
WHERE title = 'Follow a diet' AND points = 0;

-- Verify the fix
SELECT 
    'AFTER CLEANUP' as section,
    h.title,
    h.id,
    h.points,
    h.template_set
FROM public.sz_habits h
WHERE h.title = 'Follow a diet'
ORDER BY h.points DESC;

-- Check template mappings after cleanup
SELECT 
    'TEMPLATE MAPPINGS AFTER CLEANUP' as section,
    t.name as template_name,
    h.title,
    h.id,
    h.points,
    th.is_core,
    th.points_override,
    th.sort_order
FROM public.sz_template_habits th
JOIN public.sz_templates t ON th.template_id = t.id
JOIN public.sz_habits h ON th.habit_id = h.id
WHERE h.title = 'Follow a diet'
ORDER BY t.name, th.sort_order;
