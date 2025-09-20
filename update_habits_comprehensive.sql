-- Comprehensive update for habits and template sets

-- Step 1: Add custom habits (if they don't exist)
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

-- Step 2: Create/Update template sets
-- For habits that should be in both 'hard' and 'hard_plus', we'll use a comma-separated approach
-- or create separate entries for each template set

-- Update existing habits to be in hard template set
UPDATE sz_habits 
SET template_set = 'hard'
WHERE title IN (
    'Drink 1 gallon of water',
    'Follow a diet',
    'Read 10 pages of non-fiction',
    'Take a progress photo',
    'Two 45-minute workouts',
    'No Alcohol'
)
OR (title ILIKE '%picture%' OR title ILIKE '%photo%' OR title ILIKE '%progress%');

-- Update existing habits to be in hard_plus template set
UPDATE sz_habits 
SET template_set = 'hard_plus'
WHERE title IN (
    'Drink 1 gallon of water',
    'Follow a diet',
    'Read 10 pages of non-fiction',
    'Take a progress photo',
    'Two 45-minute workouts',
    'No Alcohol'
)
OR (title ILIKE '%picture%' OR title ILIKE '%photo%' OR title ILIKE '%progress%');

-- Step 3: Handle habits that need to be in multiple template sets
-- If a habit needs to be in both 'hard' and 'hard_plus', we might need to:
-- Option A: Use a different approach (like a junction table)
-- Option B: Duplicate the habit for each template set
-- Option C: Use comma-separated values in template_set

-- For now, let's use Option C - comma-separated values
UPDATE sz_habits 
SET template_set = CASE 
    WHEN template_set = 'hard' AND title IN ('Drink 1 gallon of water', 'Follow a diet', 'Read 10 pages of non-fiction', 'Take a progress photo', 'Two 45-minute workouts', 'No Alcohol') THEN 'hard,hard_plus'
    WHEN template_set = 'hard_plus' AND title IN ('Drink 1 gallon of water', 'Follow a diet', 'Read 10 pages of non-fiction', 'Take a progress photo', 'Two 45-minute workouts', 'No Alcohol') THEN 'hard,hard_plus'
    ELSE template_set
END
WHERE title IN ('Drink 1 gallon of water', 'Follow a diet', 'Read 10 pages of non-fiction', 'Take a progress photo', 'Two 45-minute workouts', 'No Alcohol');

-- Step 4: Verify results
SELECT 
    id,
    title,
    template_set,
    category,
    points,
    frequency
FROM sz_habits 
WHERE template_set ILIKE '%hard%' 
ORDER BY 
    CASE 
        WHEN template_set ILIKE '%hard_plus%' THEN 2
        WHEN template_set ILIKE '%hard%' THEN 1
        ELSE 0
    END,
    title;
