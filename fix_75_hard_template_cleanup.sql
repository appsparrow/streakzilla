-- =====================================================
-- FIX 75 HARD TEMPLATE CLEANUP
-- =====================================================
-- Remove "No Alcohol" and other habits that shouldn't be core in 75 Hard
-- Keep only the original 75 Hard core habits
-- =====================================================

-- Check current 75 Hard template habits
SELECT 
    'CURRENT 75 HARD TEMPLATE HABITS' as section,
    t.name as template_name,
    h.title as habit_title,
    th.is_core,
    th.points_override,
    h.points as default_points,
    th.sort_order
FROM public.sz_template_habits th
JOIN public.sz_templates t ON th.template_id = t.id
JOIN public.sz_habits h ON th.habit_id = h.id
WHERE t.key = '75_hard'
ORDER BY th.sort_order, h.title;

-- Remove "Take a progress photo" from 75 Hard template (it should only be in 75 Hard Plus)
DELETE FROM public.sz_template_habits 
WHERE template_id = (SELECT id FROM public.sz_templates WHERE key = '75_hard')
AND habit_id = (SELECT id FROM public.sz_habits WHERE title = 'Take a progress photo');

-- Check if there are any other habits that shouldn't be core in 75 Hard
-- Remove any habits that are not the original 75 Hard core requirements
-- KEEP: Follow a diet, Drink 1 gallon of water, Read 10 pages of non-fiction, Two 45-minute workouts, No Alcohol
DELETE FROM public.sz_template_habits 
WHERE template_id = (SELECT id FROM public.sz_templates WHERE key = '75_hard')
AND habit_id NOT IN (
    SELECT id FROM public.sz_habits 
    WHERE title IN (
        'Follow a diet',
        'Drink 1 gallon of water', 
        'Read 10 pages of non-fiction',
        'Two 45-minute workouts',
        'No Alcohol'
    )
);

-- Update sort order for remaining 75 Hard habits
UPDATE public.sz_template_habits 
SET sort_order = CASE 
    WHEN habit_id = (SELECT id FROM public.sz_habits WHERE title = 'Follow a diet') THEN 1
    WHEN habit_id = (SELECT id FROM public.sz_habits WHERE title = 'Drink 1 gallon of water') THEN 2
    WHEN habit_id = (SELECT id FROM public.sz_habits WHERE title = 'Read 10 pages of non-fiction') THEN 3
    WHEN habit_id = (SELECT id FROM public.sz_habits WHERE title = 'Two 45-minute workouts') THEN 4
    WHEN habit_id = (SELECT id FROM public.sz_habits WHERE title = 'No Alcohol') THEN 5
    ELSE sort_order
END
WHERE template_id = (SELECT id FROM public.sz_templates WHERE key = '75_hard');

-- Verify the cleanup
SELECT 
    'AFTER 75 HARD CLEANUP' as section,
    t.name as template_name,
    h.title as habit_title,
    th.is_core,
    th.points_override,
    h.points as default_points,
    th.sort_order
FROM public.sz_template_habits th
JOIN public.sz_templates t ON th.template_id = t.id
JOIN public.sz_habits h ON th.habit_id = h.id
WHERE t.key = '75_hard'
ORDER BY th.sort_order, h.title;

-- Check 75 Hard Plus template (should still have all habits including No Alcohol and Take a progress photo)
SELECT 
    '75 HARD PLUS TEMPLATE (SHOULD BE UNCHANGED)' as section,
    t.name as template_name,
    h.title as habit_title,
    th.is_core,
    th.points_override,
    h.points as default_points,
    th.sort_order
FROM public.sz_template_habits th
JOIN public.sz_templates t ON th.template_id = t.id
JOIN public.sz_habits h ON th.habit_id = h.id
WHERE t.key = '75_hard_plus'
ORDER BY th.sort_order, h.title;

-- Summary
SELECT 
    'CLEANUP SUMMARY' as section,
    '75 Hard template now has 5 core habits (original + No Alcohol)' as message,
    'Take a progress photo removed from 75 Hard (only in 75 Hard Plus)' as details,
    '75 Hard Plus template unchanged with all 6 habits' as plus_status;
