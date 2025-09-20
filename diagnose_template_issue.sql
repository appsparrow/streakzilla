-- Diagnose the current template mapping issue

-- Check current templates
SELECT 'TEMPLATES' as section, key, name, allow_custom_habits FROM sz_templates ORDER BY key;

-- Check current template habits mapping
SELECT 
    'TEMPLATE_HABITS' as section,
    t.key as template_key,
    h.title as habit_title,
    th.is_core,
    th.points_override,
    th.sort_order
FROM sz_template_habits th
JOIN sz_templates t ON t.id = th.template_id
JOIN sz_habits h ON h.id = th.habit_id
WHERE t.key IN ('75_hard', '75_hard_plus')
ORDER BY t.key, th.sort_order;

-- Check habits that might be causing the issue
SELECT 
    'PROBLEM_HABITS' as section,
    h.title,
    h.template_set,
    h.points,
    h.category
FROM sz_habits h
WHERE h.title IN ('No Alcohol', 'Take a progress photo')
ORDER BY h.title;

-- Check if habits are properly mapped to templates
SELECT 
    'MAPPING_STATUS' as section,
    h.title,
    h.template_set,
    CASE 
        WHEN th75.id IS NOT NULL THEN 'Mapped to 75 Hard'
        ELSE 'NOT mapped to 75 Hard'
    END as hard_mapping,
    CASE 
        WHEN th75p.id IS NOT NULL THEN 'Mapped to 75 Hard Plus'
        ELSE 'NOT mapped to 75 Hard Plus'
    END as hard_plus_mapping
FROM sz_habits h
LEFT JOIN sz_template_habits th75 ON th75.habit_id = h.id 
    AND th75.template_id = (SELECT id FROM sz_templates WHERE key = '75_hard')
LEFT JOIN sz_template_habits th75p ON th75p.habit_id = h.id 
    AND th75p.template_id = (SELECT id FROM sz_templates WHERE key = '75_hard_plus')
WHERE h.title IN ('No Alcohol', 'Take a progress photo')
ORDER BY h.title;
