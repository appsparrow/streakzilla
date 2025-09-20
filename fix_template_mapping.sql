-- Fix template mapping for new habits
-- This script properly adds habits to the new template-based system

-- Step 1: Add the new custom habits to sz_habits
INSERT INTO sz_habits (
    id,
    title,
    description,
    category,
    points,
    frequency,
    template_set,
    created_at
) VALUES 
(
    '9e123f4c-1bcd-42f6-83a2-72aa0cce8881',
    'No Alcohol',
    'Avoid consuming any alcoholic beverages',
    'Nutrition',
    12,
    'daily',
    'custom',
    '2025-09-18 18:40:00+00'
),
(
    '2f987d6a-0acd-42b2-9f8f-11f72ad777f1',
    'No Soda',
    'Do not drink soda or sugary soft drinks',
    'Nutrition',
    8,
    'daily',
    'custom',
    '2025-09-18 18:40:00+00'
),
(
    '8f64c2b0-3d4d-4bb2-97b8-61ea74e6ad91',
    'No Rice',
    'Avoid eating rice for the entire day',
    'Nutrition',
    7,
    'daily',
    'custom',
    '2025-09-18 18:40:00+00'
),
(
    'c26ff31d-8a13-41e4-96e1-0b3e05631f02',
    'Sleep Early',
    'Go to bed before 10:00 PM',
    'Lifestyle',
    10,
    'daily',
    'custom',
    '2025-09-18 18:40:00+00'
),
(
    '91f0030e-79a2-4d32-9f1a-46c2c843f6e4',
    'Wake Up Early',
    'Wake up at 5:00 AM or earlier',
    'Lifestyle',
    12,
    'daily',
    'custom',
    '2025-09-18 18:40:00+00'
)
ON CONFLICT (id) DO NOTHING;

-- Step 2: Add "No Alcohol" and "Take a progress photo" as CORE habits to 75 Hard template
INSERT INTO sz_template_habits (template_id, habit_id, is_core, sort_order, points_override)
SELECT 
    t.id as template_id,
    h.id as habit_id,
    true as is_core,
    6 as sort_order,  -- After the existing 5 core habits
    0 as points_override  -- Core habits should have 0 points
FROM sz_templates t
CROSS JOIN sz_habits h
WHERE t.key = '75_hard'
AND h.title IN ('No Alcohol', 'Take a progress photo')
ON CONFLICT (template_id, habit_id) DO UPDATE SET
    is_core = EXCLUDED.is_core,
    points_override = EXCLUDED.points_override;

-- Step 3: Add "No Alcohol" and "Take a progress photo" as CORE habits to 75 Hard Plus template
INSERT INTO sz_template_habits (template_id, habit_id, is_core, sort_order, points_override)
SELECT 
    t.id as template_id,
    h.id as habit_id,
    true as is_core,
    6 as sort_order,  -- After the existing 5 core habits
    0 as points_override  -- Core habits should have 0 points
FROM sz_templates t
CROSS JOIN sz_habits h
WHERE t.key = '75_hard_plus'
AND h.title IN ('No Alcohol', 'Take a progress photo')
ON CONFLICT (template_id, habit_id) DO UPDATE SET
    is_core = EXCLUDED.is_core,
    points_override = EXCLUDED.points_override;

-- Step 4: Ensure existing core habits are properly marked as CORE (not bonus)
UPDATE sz_template_habits 
SET is_core = true, points_override = 0
WHERE template_id IN (
    SELECT id FROM sz_templates WHERE key IN ('75_hard', '75_hard_plus')
)
AND habit_id IN (
    SELECT id FROM sz_habits 
    WHERE title IN (
        'Drink 1 gallon of water',
        'Follow a diet',
        'Read 10 pages of non-fiction',
        'Take a progress photo',
        'Two 45-minute workouts',
        'No Alcohol'
    )
);

-- Step 5: Verify the results
SELECT 
    t.name as template_name,
    h.title as habit_title,
    th.is_core,
    th.points_override,
    th.sort_order
FROM sz_template_habits th
JOIN sz_templates t ON t.id = th.template_id
JOIN sz_habits h ON h.id = th.habit_id
WHERE t.key IN ('75_hard', '75_hard_plus')
ORDER BY t.key, th.sort_order, h.title;
