-- Setup Users with New Streak and Complete Check-ins
-- This script creates a new streak and assigns users with their specific habits
-- All users will have complete check-ins from start date to today

-- First, let's create the new streak
INSERT INTO sz_streaks (
    id,
    name,
    description,
    mode,
    duration_days,
    start_date,
    end_date,
    is_active,
    created_by,
    points_to_hearts_enabled,
    hearts_per_100_points,
    template_id
) VALUES (
    '444efc20-0db3-46a5-86a0-265597be8acd'::uuid,
    '75 Hard Plus Challenge - New Batch',
    'Complete 75 Hard Plus challenge with all core and bonus habits',
    '75_hard_plus',
    75,
    '2025-09-17'::date,
    '2025-12-01'::date,
    true,
    'afc5adfa-553b-4d56-a583-2491b23ec453'::uuid, -- Using one of the users as creator
    true,
    1,
    '79fb04f6-5f78-44f1-97eb-2563b22da2fe'::uuid -- Template ID from your logs
);

-- User 1: 521dca54-21ee-4815-baf7-9b4213275779
-- Add user to streak
INSERT INTO sz_streak_members (
    streak_id,
    user_id,
    role,
    status,
    joined_at,
    current_streak,
    total_points,
    hearts_available,
    hearts_earned,
    hearts_used
) VALUES (
    '444efc20-0db3-46a5-86a0-265597be8acd'::uuid,
    '521dca54-21ee-4815-baf7-9b4213275779'::uuid,
    'admin',
    'active',
    NOW(),
    0,
    0,
    0,
    0,
    0
);

-- Add user's habits (all habits with their points)
INSERT INTO sz_user_habits (streak_id, user_id, habit_id, points_override) VALUES
-- Core habits (from template)
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', '41c02541-c1ea-416e-8029-453f2a3fd17e', 5),  -- Take a progress photo
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', '9e123f4c-1bcd-42f6-83a2-72aa0cce8881', 10), -- No Alcohol
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', 'c4dc94a9-b5df-4c73-bcdb-4045b200d08e', 10), -- Drink 1 gallon of water
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', 'aaf10bd6-c648-4040-aa79-bdb8e0d457fd', 15), -- Two 45-minute workouts
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', 'd3635f7a-02e2-4d59-82d3-a782766d691c', 10), -- Read 10 pages of non-fiction
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', '29fc3f19-83c9-4090-a2a7-57b036c0b5de', 15), -- Follow a diet
-- Bonus habits (need to find/create habit IDs)
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', 'meditation-habit-id', 10),  -- 10 minutes of meditation
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', 'ice-bath-habit-id', 10),    -- Ice bath
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', 'wake-early-habit-id', 10),  -- Wake Up Early
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', 'morning-yoga-habit-id', 8),  -- Morning Yoga
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', 'plank-challenge-habit-id', 5), -- Plank Challenge
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', 'meditation-2-habit-id', 8),   -- Meditation
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', 'gratitude-journal-habit-id', 6), -- Gratitude Journal
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', 'no-social-media-habit-id', 10), -- No Social Media
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', 'learn-new-skill-habit-id', 10), -- Learn New Skill
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', 'write-500-words-habit-id', 8), -- Write 500 Words
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', 'vitamins-habit-id', 3),       -- Vitamins/Supplements
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', 'no-processed-sugar-habit-id', 8), -- No Processed Sugar
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', 'green-smoothie-habit-id', 6),   -- Green Smoothie
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', 'make-bed-habit-id', 3),        -- Make Your Bed
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', 'connect-friend-habit-id', 6),   -- Connect with Friend
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', 'random-kindness-habit-id', 8),  -- Random Act of Kindness
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', 'no-complaining-habit-id', 10), -- No Complaining
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', 'intermittent-fasting-habit-id', 10), -- Intermittent Fasting
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', 'take-stairs-habit-id', 6),     -- Take Stairs Only
('444efc20-0db3-46a5-86a0-265597be8acd', '521dca54-21ee-4815-baf7-9b4213275779', 'cook-scratch-habit-id', 7);    -- Cook from Scratch

-- User 2: 9bdf34ba-751d-4687-80b5-8f7d9549a635 (Balu)
INSERT INTO sz_streak_members (
    streak_id,
    user_id,
    role,
    status,
    joined_at,
    current_streak,
    total_points,
    hearts_available,
    hearts_earned,
    hearts_used
) VALUES (
    '444efc20-0db3-46a5-86a0-265597be8acd'::uuid,
    '9bdf34ba-751d-4687-80b5-8f7d9549a635'::uuid,
    'member',
    'active',
    NOW(),
    0,
    0,
    0,
    0,
    0
);

-- Add Balu's habits (core habits only)
INSERT INTO sz_user_habits (streak_id, user_id, habit_id, points_override) VALUES
('444efc20-0db3-46a5-86a0-265597be8acd', '9bdf34ba-751d-4687-80b5-8f7d9549a635', '41c02541-c1ea-416e-8029-453f2a3fd17e', 5),  -- Take a progress photo
('444efc20-0db3-46a5-86a0-265597be8acd', '9bdf34ba-751d-4687-80b5-8f7d9549a635', '9e123f4c-1bcd-42f6-83a2-72aa0cce8881', 10), -- No Alcohol
('444efc20-0db3-46a5-86a0-265597be8acd', '9bdf34ba-751d-4687-80b5-8f7d9549a635', 'c4dc94a9-b5df-4c73-bcdb-4045b200d08e', 10), -- Drink 1 gallon of water
('444efc20-0db3-46a5-86a0-265597be8acd', '9bdf34ba-751d-4687-80b5-8f7d9549a635', 'aaf10bd6-c648-4040-aa79-bdb8e0d457fd', 15), -- Two 45-minute workouts
('444efc20-0db3-46a5-86a0-265597be8acd', '9bdf34ba-751d-4687-80b5-8f7d9549a635', 'd3635f7a-02e2-4d59-82d3-a782766d691c', 10), -- Read 10 pages of non-fiction
('444efc20-0db3-46a5-86a0-265597be8acd', '9bdf34ba-751d-4687-80b5-8f7d9549a635', '29fc3f19-83c9-4090-a2a7-57b036c0b5de', 15); -- Follow a diet

-- User 3: afc5adfa-553b-4d56-a583-2491b23ec453
INSERT INTO sz_streak_members (
    streak_id,
    user_id,
    role,
    status,
    joined_at,
    current_streak,
    total_points,
    hearts_available,
    hearts_earned,
    hearts_used
) VALUES (
    '444efc20-0db3-46a5-86a0-265597be8acd'::uuid,
    'afc5adfa-553b-4d56-a583-2491b23ec453'::uuid,
    'member',
    'active',
    NOW(),
    0,
    0,
    0,
    0,
    0
);

-- Add User 3's habits
INSERT INTO sz_user_habits (streak_id, user_id, habit_id, points_override) VALUES
-- Core habits
('444efc20-0db3-46a5-86a0-265597be8acd', 'afc5adfa-553b-4d56-a583-2491b23ec453', '41c02541-c1ea-416e-8029-453f2a3fd17e', 5),  -- Take a progress photo
('444efc20-0db3-46a5-86a0-265597be8acd', 'afc5adfa-553b-4d56-a583-2491b23ec453', '9e123f4c-1bcd-42f6-83a2-72aa0cce8881', 10), -- No Alcohol
('444efc20-0db3-46a5-86a0-265597be8acd', 'afc5adfa-553b-4d56-a583-2491b23ec453', 'c4dc94a9-b5df-4c73-bcdb-4045b200d08e', 10), -- Drink 1 gallon of water
('444efc20-0db3-46a5-86a0-265597be8acd', 'afc5adfa-553b-4d56-a583-2491b23ec453', 'aaf10bd6-c648-4040-aa79-bdb8e0d457fd', 15), -- Two 45-minute workouts
('444efc20-0db3-46a5-86a0-265597be8acd', 'afc5adfa-553b-4d56-a583-2491b23ec453', 'd3635f7a-02e2-4d59-82d3-a782766d691c', 10), -- Read 10 pages of non-fiction
('444efc20-0db3-46a5-86a0-265597be8acd', 'afc5adfa-553b-4d56-a583-2491b23ec453', '29fc3f19-83c9-4090-a2a7-57b036c0b5de', 15), -- Follow a diet
-- Bonus habits
('444efc20-0db3-46a5-86a0-265597be8acd', 'afc5adfa-553b-4d56-a583-2491b23ec453', 'meditation-habit-id', 10),  -- 10 minutes of meditation
('444efc20-0db3-46a5-86a0-265597be8acd', 'afc5adfa-553b-4d56-a583-2491b23ec453', 'no-rice-habit-id', 7),     -- No Rice
('444efc20-0db3-46a5-86a0-265597be8acd', 'afc5adfa-553b-4d56-a583-2491b23ec453', 'cold-shower-habit-id', 5),  -- Cold Shower
('444efc20-0db3-46a5-86a0-265597be8acd', 'afc5adfa-553b-4d56-a583-2491b23ec453', 'make-bed-habit-id', 3),     -- Make Your Bed
('444efc20-0db3-46a5-86a0-265597be8acd', 'afc5adfa-553b-4d56-a583-2491b23ec453', 'intermittent-fasting-habit-id', 10); -- Intermittent Fasting

-- User 4: 8f93d8cb-428f-4f95-a04a-79be2f3e1063 (Vijis)
INSERT INTO sz_streak_members (
    streak_id,
    user_id,
    role,
    status,
    joined_at,
    current_streak,
    total_points,
    hearts_available,
    hearts_earned,
    hearts_used
) VALUES (
    '444efc20-0db3-46a5-86a0-265597be8acd'::uuid,
    '8f93d8cb-428f-4f95-a04a-79be2f3e1063'::uuid,
    'member',
    'active',
    NOW(),
    0,
    0,
    0,
    0,
    0
);

-- Add Vijis's habits
INSERT INTO sz_user_habits (streak_id, user_id, habit_id, points_override) VALUES
-- Core habits
('444efc20-0db3-46a5-86a0-265597be8acd', '8f93d8cb-428f-4f95-a04a-79be2f3e1063', '41c02541-c1ea-416e-8029-453f2a3fd17e', 5),  -- Take a progress photo
('444efc20-0db3-46a5-86a0-265597be8acd', '8f93d8cb-428f-4f95-a04a-79be2f3e1063', '9e123f4c-1bcd-42f6-83a2-72aa0cce8881', 10), -- No Alcohol
('444efc20-0db3-46a5-86a0-265597be8acd', '8f93d8cb-428f-4f95-a04a-79be2f3e1063', 'c4dc94a9-b5df-4c73-bcdb-4045b200d08e', 10), -- Drink 1 gallon of water
('444efc20-0db3-46a5-86a0-265597be8acd', '8f93d8cb-428f-4f95-a04a-79be2f3e1063', 'aaf10bd6-c648-4040-aa79-bdb8e0d457fd', 15), -- Two 45-minute workouts
('444efc20-0db3-46a5-86a0-265597be8acd', '8f93d8cb-428f-4f95-a04a-79be2f3e1063', 'd3635f7a-02e2-4d59-82d3-a782766d691c', 10), -- Read 10 pages of non-fiction
('444efc20-0db3-46a5-86a0-265597be8acd', '8f93d8cb-428f-4f95-a04a-79be2f3e1063', '29fc3f19-83c9-4090-a2a7-57b036c0b5de', 15), -- Follow a diet
-- Bonus habits
('444efc20-0db3-46a5-86a0-265597be8acd', '8f93d8cb-428f-4f95-a04a-79be2f3e1063', 'no-soda-habit-id', 8),     -- No Soda
('444efc20-0db3-46a5-86a0-265597be8acd', '8f93d8cb-428f-4f95-a04a-79be2f3e1063', 'no-rice-habit-id', 7),     -- No Rice
('444efc20-0db3-46a5-86a0-265597be8acd', '8f93d8cb-428f-4f95-a04a-79be2f3e1063', 'intermittent-fasting-habit-id', 10), -- Intermittent Fasting
('444efc20-0db3-46a5-86a0-265597be8acd', '8f93d8cb-428f-4f95-a04a-79be2f3e1063', 'cook-scratch-habit-id', 7);  -- Cook from Scratch
