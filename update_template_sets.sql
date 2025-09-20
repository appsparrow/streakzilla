-- Update template sets to include new habits

-- First, let's see what habits are currently in hard and hard_plus templates
-- SELECT id, title, template_set FROM sz_habits WHERE template_set IN ('hard', 'hard_plus') ORDER BY template_set, title;

-- Update existing habits to include in hard template set
-- Add "No Alcohol" to hard template set
UPDATE sz_habits 
SET template_set = CASE 
    WHEN template_set = 'hard' THEN 'hard'
    WHEN template_set = 'hard_plus' THEN 'hard_plus'
    WHEN template_set = 'custom' AND id = '9e123f4c-1bcd-42f6-83a2-72aa0cce8881' THEN 'hard'
    ELSE template_set
END
WHERE id = '9e123f4c-1bcd-42f6-83a2-72aa0cce8881' OR template_set IN ('hard', 'hard_plus');

-- Add "Daily Picture" to hard template set
-- Assuming there's a habit with title containing "picture" or "photo"
UPDATE sz_habits 
SET template_set = 'hard'
WHERE (title ILIKE '%picture%' OR title ILIKE '%photo%' OR title ILIKE '%progress%')
AND template_set = 'custom';

-- Add specific habits to hard template set
UPDATE sz_habits 
SET template_set = 'hard'
WHERE title IN (
    'Drink 1 gallon of water',
    'Follow a diet',
    'Read 10 pages of non-fiction',
    'Take a progress photo',
    'Two 45-minute workouts'
);

-- Add the same habits to hard_plus template set as well
UPDATE sz_habits 
SET template_set = 'hard_plus'
WHERE title IN (
    'Drink 1 gallon of water',
    'Follow a diet',
    'Read 10 pages of non-fiction',
    'Take a progress photo',
    'Two 45-minute workouts',
    'No Alcohol'
);

-- Add "Daily Picture" to hard_plus as well
UPDATE sz_habits 
SET template_set = 'hard_plus'
WHERE (title ILIKE '%picture%' OR title ILIKE '%photo%' OR title ILIKE '%progress%')
AND template_set = 'hard';

-- Verify the changes
SELECT id, title, template_set, category, points 
FROM sz_habits 
WHERE template_set IN ('hard', 'hard_plus') 
ORDER BY template_set, title;
