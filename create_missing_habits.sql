-- Create Missing Habits for the New Streak
-- This script creates all the bonus habits that don't exist in the system yet

-- First, let's check what habits already exist
SELECT 
    'EXISTING HABITS' as check_type,
    id,
    name,
    description,
    points,
    category
FROM sz_habits 
WHERE name IN (
    'Take a progress photo',
    'No Alcohol', 
    'Drink 1 gallon of water',
    'Two 45-minute workouts',
    'Read 10 pages of non-fiction',
    'Follow a diet',
    '10 minutes of meditation',
    'Ice bath',
    'Wake Up Early',
    'Morning Yoga',
    'Plank Challenge',
    'Meditation',
    'Gratitude Journal',
    'No Social Media',
    'Learn New Skill',
    'Write 500 Words',
    'Vitamins/Supplements',
    'No Processed Sugar',
    'Green Smoothie',
    'Make Your Bed',
    'Connect with Friend',
    'Random Act of Kindness',
    'No Complaining',
    'Intermittent Fasting',
    'Take Stairs Only',
    'Cook from Scratch',
    'No Rice',
    'Cold Shower',
    'No Soda'
)
ORDER BY name;

-- Create missing habits
INSERT INTO sz_habits (id, name, description, points, category) VALUES
-- Meditation habits
(gen_random_uuid(), '10 minutes of meditation', 'Practice mindfulness or meditation for at least 10 minutes', 10, 'Health'),
(gen_random_uuid(), 'Meditation', '10 minutes of mindfulness or meditation', 8, 'Mental Health'),

-- Physical challenges
(gen_random_uuid(), 'Ice bath', 'Take a cold shower for at least 2 minutes or ice bath for 1 minute', 10, 'Health'),
(gen_random_uuid(), 'Cold Shower', 'Take a cold shower for at least 2 minutes', 5, 'Health'),
(gen_random_uuid(), 'Wake Up Early', 'Wake up at 5:00 AM or earlier', 10, 'Lifestyle'),
(gen_random_uuid(), 'Morning Yoga', '20 minutes of yoga or stretching', 8, 'Fitness'),
(gen_random_uuid(), 'Plank Challenge', 'Hold a plank for 3 minutes total', 5, 'Fitness'),
(gen_random_uuid(), 'Take Stairs Only', 'Only use stairs, never elevators/escalators', 6, 'Fitness'),

-- Mental health habits
(gen_random_uuid(), 'Gratitude Journal', 'Write 3 things you are grateful for', 6, 'Mental Health'),
(gen_random_uuid(), 'No Social Media', 'Avoid social media for the entire day', 10, 'Mental Health'),
(gen_random_uuid(), 'No Complaining', 'Go the entire day without complaining', 10, 'Mental Health'),

-- Learning habits
(gen_random_uuid(), 'Learn New Skill', '30 minutes learning something new', 10, 'Education'),
(gen_random_uuid(), 'Write 500 Words', 'Write at least 500 words (journal, blog, etc.)', 8, 'Education'),

-- Health habits
(gen_random_uuid(), 'Vitamins/Supplements', 'Take your daily vitamins or supplements', 3, 'Health'),
(gen_random_uuid(), 'No Processed Sugar', 'Avoid all processed sugar for the day', 8, 'Nutrition'),
(gen_random_uuid(), 'Green Smoothie', 'Drink a green smoothie with vegetables', 6, 'Nutrition'),
(gen_random_uuid(), 'Intermittent Fasting', 'Complete a 16:8 intermittent fast', 10, 'Health'),

-- Personal development
(gen_random_uuid(), 'Make Your Bed', 'Make your bed within 30 minutes of waking', 3, 'Personal Development'),
(gen_random_uuid(), 'Connect with Friend', 'Reach out to a friend or family member', 6, 'Personal Development'),
(gen_random_uuid(), 'Random Act of Kindness', 'Do something nice for someone else', 8, 'Personal Development'),

-- Nutrition habits
(gen_random_uuid(), 'Cook from Scratch', 'Prepare one meal completely from scratch', 7, 'Nutrition'),
(gen_random_uuid(), 'No Rice', 'Avoid eating rice for the entire day', 7, 'Nutrition'),
(gen_random_uuid(), 'No Soda', 'Do not drink soda or sugary soft drinks', 8, 'Nutrition')
ON CONFLICT (name) DO NOTHING;

-- Get the habit IDs for the setup script
SELECT 
    'HABIT IDS FOR SETUP' as check_type,
    id,
    name,
    points
FROM sz_habits 
WHERE name IN (
    '10 minutes of meditation',
    'Ice bath',
    'Wake Up Early',
    'Morning Yoga',
    'Plank Challenge',
    'Meditation',
    'Gratitude Journal',
    'No Social Media',
    'Learn New Skill',
    'Write 500 Words',
    'Vitamins/Supplements',
    'No Processed Sugar',
    'Green Smoothie',
    'Make Your Bed',
    'Connect with Friend',
    'Random Act of Kindness',
    'No Complaining',
    'Intermittent Fasting',
    'Take Stairs Only',
    'Cook from Scratch',
    'No Rice',
    'Cold Shower',
    'No Soda'
)
ORDER BY name;
