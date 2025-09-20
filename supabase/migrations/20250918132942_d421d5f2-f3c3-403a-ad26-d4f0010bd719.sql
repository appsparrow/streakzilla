-- Insert template habits for the streak modes
INSERT INTO public.sz_habits (title, description, category, points, template_set) VALUES
-- 75 Hard habits
('Drink 1 gallon of water', 'Drink a full gallon (128oz) of water throughout the day', 'Health', 10, '75_hard'),
('Two 45-minute workouts', 'Complete two separate 45-minute workout sessions, one must be outdoors', 'Fitness', 15, '75_hard'),
('Read 10 pages of non-fiction', 'Read at least 10 pages of a non-fiction book (no audiobooks)', 'Education', 10, '75_hard'),
('Follow a diet', 'Stick to your chosen diet with zero cheat meals or alcohol', 'Nutrition', 15, '75_hard'),
('Take a progress photo', 'Take a daily progress photo to track your transformation', 'Health', 5, '75_hard'),

-- 75 Hard Plus habits (enhanced version)
('Drink 1 gallon of water', 'Drink a full gallon (128oz) of water throughout the day', 'Health', 10, '75_hard_plus'),
('Two 45-minute workouts', 'Complete two separate 45-minute workout sessions, one must be outdoors', 'Fitness', 15, '75_hard_plus'),
('Read 10 pages of non-fiction', 'Read at least 10 pages of a non-fiction book (no audiobooks)', 'Education', 10, '75_hard_plus'),
('Follow a diet', 'Stick to your chosen diet with zero cheat meals or alcohol', 'Nutrition', 15, '75_hard_plus'),
('Take a progress photo', 'Take a daily progress photo to track your transformation', 'Health', 5, '75_hard_plus'),
('Cold shower/ice bath', 'Take a cold shower for at least 2 minutes or ice bath for 1 minute', 'Mental', 10, '75_hard_plus'),
('10 minutes of meditation', 'Practice mindfulness or meditation for at least 10 minutes', 'Mental', 10, '75_hard_plus'),

-- 75 Custom habits (flexible options)
('Morning routine', 'Complete your established morning routine', 'Lifestyle', 10, '75_custom'),
('Evening routine', 'Complete your established evening routine', 'Lifestyle', 10, '75_custom'),
('Workout session', 'Complete your daily workout or physical activity', 'Fitness', 15, '75_custom'),
('Healthy meal prep', 'Prepare or eat a healthy, planned meal', 'Nutrition', 10, '75_custom'),
('Learning activity', 'Spend time learning something new (reading, course, etc.)', 'Education', 10, '75_custom'),
('Gratitude practice', 'Write down 3 things you are grateful for', 'Mental', 5, '75_custom'),
('No social media', 'Avoid recreational social media usage', 'Digital Wellness', 10, '75_custom'),
('Drink water goal', 'Meet your daily hydration goal', 'Health', 5, '75_custom')
ON CONFLICT (title, template_set) DO NOTHING;