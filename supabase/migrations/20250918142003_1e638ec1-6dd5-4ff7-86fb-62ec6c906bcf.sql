-- Add more variety of habits for hard_plus mode and custom selection
INSERT INTO sz_habits (title, description, category, points, frequency, template_set) VALUES
-- Fitness variants
('Morning Yoga', '20 minutes of yoga or stretching', 'Fitness', 8, 'daily', 'custom'),
('Cold Shower', 'Take a cold shower for at least 2 minutes', 'Health', 5, 'daily', 'custom'),
('10,000 Steps', 'Walk or get 10,000 steps in a day', 'Fitness', 7, 'daily', 'custom'),
('Push-ups', 'Do 50 push-ups (can be broken into sets)', 'Fitness', 6, 'daily', 'custom'),
('Plank Challenge', 'Hold a plank for 3 minutes total', 'Fitness', 5, 'daily', 'custom'),

-- Mental Health & Mindfulness
('Meditation', '10 minutes of mindfulness or meditation', 'Mental Health', 8, 'daily', 'custom'),
('Gratitude Journal', 'Write 3 things you are grateful for', 'Mental Health', 6, 'daily', 'custom'),
('No Social Media', 'Avoid social media for the entire day', 'Mental Health', 10, 'daily', 'custom'),
('Deep Breathing', '5 minutes of focused breathing exercises', 'Mental Health', 4, 'daily', 'custom'),

-- Productivity & Learning
('Learn New Skill', '30 minutes learning something new', 'Education', 10, 'daily', 'custom'),
('Write 500 Words', 'Write at least 500 words (journal, blog, etc.)', 'Education', 8, 'daily', 'custom'),
('Practice Instrument', '20 minutes of musical instrument practice', 'Education', 7, 'daily', 'custom'),
('Language Learning', '15 minutes of foreign language study', 'Education', 6, 'daily', 'custom'),

-- Health & Wellness  
('Vitamins/Supplements', 'Take your daily vitamins or supplements', 'Health', 3, 'daily', 'custom'),
('Skincare Routine', 'Complete morning and evening skincare routine', 'Health', 4, 'daily', 'custom'),
('Healthy Breakfast', 'Eat a nutritious breakfast', 'Nutrition', 5, 'daily', 'custom'),
('No Processed Sugar', 'Avoid all processed sugar for the day', 'Nutrition', 8, 'daily', 'custom'),
('Green Smoothie', 'Drink a green smoothie with vegetables', 'Nutrition', 6, 'daily', 'custom'),

-- Personal Development
('Make Your Bed', 'Make your bed within 30 minutes of waking', 'Personal Development', 3, 'daily', 'custom'),
('Plan Tomorrow', 'Spend 10 minutes planning tomorrow', 'Personal Development', 5, 'daily', 'custom'),
('Connect with Friend', 'Reach out to a friend or family member', 'Personal Development', 6, 'daily', 'custom'),
('Random Act of Kindness', 'Do something nice for someone else', 'Personal Development', 8, 'daily', 'custom'),

-- Challenging Habits (Higher Points)
('Wake Up 5 AM', 'Wake up at 5:00 AM or earlier', 'Personal Development', 12, 'daily', 'custom'),
('No Complaining', 'Go the entire day without complaining', 'Mental Health', 10, 'daily', 'custom'),
('Digital Detox Evening', 'No screens after 8 PM', 'Mental Health', 9, 'daily', 'custom'),
('Intermittent Fasting', 'Complete a 16:8 intermittent fast', 'Health', 10, 'daily', 'custom'),
('Take Stairs Only', 'Only use stairs, never elevators/escalators', 'Fitness', 6, 'daily', 'custom'),

-- Creative & Fun
('Creative Time', '30 minutes of creative work (art, music, writing)', 'Personal Development', 8, 'daily', 'custom'),
('Photo Challenge', 'Take and edit one meaningful photo', 'Personal Development', 5, 'daily', 'custom'),
('Cook from Scratch', 'Prepare one meal completely from scratch', 'Nutrition', 7, 'daily', 'custom');