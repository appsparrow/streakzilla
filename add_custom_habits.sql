-- Add custom habits to sz_habits table
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
);
