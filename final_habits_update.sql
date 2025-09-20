-- Final comprehensive update for habits and template sets
-- This approach creates separate entries for habits that need to be in multiple template sets

-- Step 1: Insert new custom habits
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

-- Step 2: Create hard template set entries for specified habits
-- First, get the existing habits and create hard template versions
INSERT INTO sz_habits (
    id,
    title,
    description,
    category,
    points,
    frequency,
    template_set,
    created_at
)
SELECT 
    gen_random_uuid() as id,
    title,
    description,
    category,
    points,
    frequency,
    'hard' as template_set,
    NOW() as created_at
FROM sz_habits 
WHERE title IN (
    'Drink 1 gallon of water',
    'Follow a diet',
    'Read 10 pages of non-fiction',
    'Take a progress photo',
    'Two 45-minute workouts',
    'No Alcohol'
)
AND template_set != 'hard'
ON CONFLICT DO NOTHING;

-- Step 3: Create hard_plus template set entries for specified habits
INSERT INTO sz_habits (
    id,
    title,
    description,
    category,
    points,
    frequency,
    template_set,
    created_at
)
SELECT 
    gen_random_uuid() as id,
    title,
    description,
    category,
    points,
    frequency,
    'hard_plus' as template_set,
    NOW() as created_at
FROM sz_habits 
WHERE title IN (
    'Drink 1 gallon of water',
    'Follow a diet',
    'Read 10 pages of non-fiction',
    'Take a progress photo',
    'Two 45-minute workouts',
    'No Alcohol'
)
AND template_set NOT IN ('hard_plus')
ON CONFLICT DO NOTHING;

-- Step 4: Handle Daily Picture - find and add to hard and hard_plus
INSERT INTO sz_habits (
    id,
    title,
    description,
    category,
    points,
    frequency,
    template_set,
    created_at
)
SELECT 
    gen_random_uuid() as id,
    title,
    description,
    category,
    points,
    frequency,
    'hard' as template_set,
    NOW() as created_at
FROM sz_habits 
WHERE (title ILIKE '%picture%' OR title ILIKE '%photo%' OR title ILIKE '%progress%')
AND template_set != 'hard'
ON CONFLICT DO NOTHING;

INSERT INTO sz_habits (
    id,
    title,
    description,
    category,
    points,
    frequency,
    template_set,
    created_at
)
SELECT 
    gen_random_uuid() as id,
    title,
    description,
    category,
    points,
    frequency,
    'hard_plus' as template_set,
    NOW() as created_at
FROM sz_habits 
WHERE (title ILIKE '%picture%' OR title ILIKE '%photo%' OR title ILIKE '%progress%')
AND template_set != 'hard_plus'
ON CONFLICT DO NOTHING;

-- Step 5: Show final results
SELECT 
    id,
    title,
    template_set,
    category,
    points,
    frequency
FROM sz_habits 
WHERE template_set IN ('hard', 'hard_plus')
ORDER BY template_set, title;
