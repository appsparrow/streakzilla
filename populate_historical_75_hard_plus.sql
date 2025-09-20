-- =====================================================
-- POPULATE HISTORICAL 75 HARD PLUS DATA
-- =====================================================
-- This script populates historical data for users who completed 75 Hard Plus streaks
-- 
-- USAGE:
-- 1. Replace the user_data section with actual user data
-- 2. Run this script in Supabase SQL Editor
-- 3. The script will create streaks, user habits, and backdated check-ins
-- =====================================================

-- =====================================================
-- USER DATA SECTION - REPLACE WITH ACTUAL DATA
-- =====================================================
-- Format: 
-- - user_id: UUID of the user
-- - user_name: Display name for the user
-- - streak_name: Name of their 75 Hard Plus streak
-- - start_date: When they started (YYYY-MM-DD format)
-- - end_date: When they completed (YYYY-MM-DD format)
-- - selected_habits: Array of habit titles they completed
-- =====================================================

-- Example data structure (replace with actual data):
/*
WITH user_data AS (
  SELECT 
    'user-uuid-1'::uuid as user_id,
    'John Doe'::text as user_name,
    'My 75 Hard Plus Journey'::text as streak_name,
    '2024-01-01'::date as start_date,
    '2024-03-16'::date as end_date,
    ARRAY[
      'Drink 1 gallon of water',
      'Two 45-minute workouts', 
      'Read 10 pages of non-fiction',
      'Follow a diet',
      'Take a progress photo',
      'No Alcohol'
    ]::text[] as selected_habits
  UNION ALL
  SELECT 
    'user-uuid-2'::uuid as user_id,
    'Jane Smith'::text as user_name,
    '75 Hard Plus Challenge'::text as streak_name,
    '2024-02-01'::date as start_date,
    '2024-04-16'::date as end_date,
    ARRAY[
      'Drink 1 gallon of water',
      'Two 45-minute workouts',
      'Read 10 pages of non-fiction', 
      'Follow a diet',
      'Take a progress photo',
      'No Alcohol'
    ]::text[] as selected_habits
  -- Add more users here...
)
*/

-- =====================================================
-- MAIN POPULATION SCRIPT
-- =====================================================

DO $$
DECLARE
    user_record RECORD;
    streak_id UUID;
    habit_record RECORD;
    day_counter INTEGER;
    current_date DATE;
    habit_ids UUID[];
    total_points INTEGER;
    checkin_id UUID;
    post_id UUID;
BEGIN
    -- Loop through each user in the data
    FOR user_record IN 
        -- REPLACE THIS WITH YOUR ACTUAL USER DATA
        SELECT 
            'user-uuid-1'::uuid as user_id,
            'John Doe'::text as user_name,
            'My 75 Hard Plus Journey'::text as streak_name,
            '2024-01-01'::date as start_date,
            '2024-03-16'::date as end_date,
            ARRAY[
                'Drink 1 gallon of water',
                'Two 45-minute workouts', 
                'Read 10 pages of non-fiction',
                'Follow a diet',
                'Take a progress photo',
                'No Alcohol'
            ]::text[] as selected_habits
        -- Add more users here by adding UNION ALL with more SELECT statements
    LOOP
        RAISE NOTICE 'Processing user: % (%)', user_record.user_name, user_record.user_id;
        
        -- =====================================================
        -- 1. CREATE STREAK
        -- =====================================================
        INSERT INTO public.sz_streaks (
            name,
            code,
            mode,
            start_date,
            duration_days,
            created_by,
            is_active
        ) VALUES (
            user_record.streak_name,
            'HIST-' || substring(user_record.user_id::text, 1, 8) || '-' || extract(epoch from user_record.start_date)::integer,
            '75_hard_plus',
            user_record.start_date,
            75,
            user_record.user_id,
            false  -- Mark as completed/inactive
        ) RETURNING id INTO streak_id;
        
        RAISE NOTICE 'Created streak: % (ID: %)', user_record.streak_name, streak_id;
        
        -- =====================================================
        -- 2. ADD USER TO STREAK MEMBERS
        -- =====================================================
        INSERT INTO public.sz_streak_members (
            streak_id,
            user_id,
            role,
            current_streak,
            total_points,
            lives_remaining,
            is_out
        ) VALUES (
            streak_id,
            user_record.user_id,
            'admin',
            75,  -- Completed all 75 days
            0,   -- Will be calculated
            3,   -- Started with 3 lives
            false -- Completed successfully
        );
        
        -- =====================================================
        -- 3. ADD USER HABITS
        -- =====================================================
        habit_ids := ARRAY[]::uuid[];
        
        -- Loop through selected habits and find their IDs
        FOR i IN 1..array_length(user_record.selected_habits, 1) LOOP
            SELECT id INTO habit_record.id
            FROM public.sz_habits 
            WHERE title = user_record.selected_habits[i];
            
            IF habit_record.id IS NOT NULL THEN
                -- Add to user habits
                INSERT INTO public.sz_user_habits (
                    streak_id,
                    user_id,
                    habit_id
                ) VALUES (
                    streak_id,
                    user_record.user_id,
                    habit_record.id
                );
                
                -- Add to habit_ids array for check-ins
                habit_ids := habit_ids || habit_record.id;
                
                RAISE NOTICE 'Added habit: % (ID: %)', user_record.selected_habits[i], habit_record.id;
            ELSE
                RAISE WARNING 'Habit not found: %', user_record.selected_habits[i];
            END IF;
        END LOOP;
        
        -- =====================================================
        -- 4. CREATE BACKDATED CHECK-INS
        -- =====================================================
        day_counter := 1;
        current_date := user_record.start_date;
        
        WHILE current_date <= user_record.end_date AND day_counter <= 75 LOOP
            -- Calculate total points for this day
            total_points := 0;
            FOR i IN 1..array_length(habit_ids, 1) LOOP
                SELECT points INTO habit_record.points
                FROM public.sz_habits 
                WHERE id = habit_ids[i];
                
                IF habit_record.points IS NOT NULL THEN
                    total_points := total_points + habit_record.points;
                END IF;
            END LOOP;
            
            -- Create check-in record
            INSERT INTO public.sz_checkins (
                streak_id,
                user_id,
                day_number,
                completed_habit_ids,
                points_earned,
                note,
                created_at
            ) VALUES (
                streak_id,
                user_record.user_id,
                day_counter,
                habit_ids,
                total_points,
                'Day ' || day_counter || ' completed - Historical data',
                current_date + interval '18 hours'  -- Assume check-in at 6 PM
            ) RETURNING id INTO checkin_id;
            
            -- Create progress photo post
            INSERT INTO public.sz_posts (
                streak_id,
                user_id,
                day_number,
                photo_url,
                caption,
                created_at
            ) VALUES (
                streak_id,
                user_record.user_id,
                day_counter,
                'https://example.com/progress-photos/day-' || day_counter || '.jpg',
                'Day ' || day_counter || ' progress photo - Historical data',
                current_date + interval '20 hours'  -- Assume photo at 8 PM
            ) RETURNING id INTO post_id;
            
            -- Move to next day
            current_date := current_date + interval '1 day';
            day_counter := day_counter + 1;
        END LOOP;
        
        -- =====================================================
        -- 5. UPDATE STREAK MEMBER TOTAL POINTS
        -- =====================================================
        UPDATE public.sz_streak_members 
        SET total_points = (
            SELECT COALESCE(SUM(points_earned), 0)
            FROM public.sz_checkins 
            WHERE streak_id = streak_id AND user_id = user_record.user_id
        )
        WHERE streak_id = streak_id AND user_id = user_record.user_id;
        
        RAISE NOTICE 'Completed processing user: % - Created % check-ins', user_record.user_name, day_counter - 1;
        
    END LOOP;
    
    RAISE NOTICE 'Historical data population completed successfully!';
END $$;

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================
-- Run these queries to verify the data was created correctly

-- 1. Check created streaks
SELECT 
    s.name,
    s.code,
    s.mode,
    s.start_date,
    s.duration_days,
    s.is_active,
    sm.user_id,
    sm.current_streak,
    sm.total_points,
    sm.is_out
FROM public.sz_streaks s
JOIN public.sz_streak_members sm ON s.id = sm.streak_id
WHERE s.code LIKE 'HIST-%'
ORDER BY s.created_at DESC;

-- 2. Check user habits
SELECT 
    s.name as streak_name,
    h.title as habit_title,
    h.points,
    uh.created_at
FROM public.sz_user_habits uh
JOIN public.sz_streaks s ON uh.streak_id = s.id
JOIN public.sz_habits h ON uh.habit_id = h.id
WHERE s.code LIKE 'HIST-%'
ORDER BY s.name, h.title;

-- 3. Check check-ins
SELECT 
    s.name as streak_name,
    c.day_number,
    c.points_earned,
    c.completed_habit_ids,
    c.created_at
FROM public.sz_checkins c
JOIN public.sz_streaks s ON c.streak_id = s.id
WHERE s.code LIKE 'HIST-%'
ORDER BY s.name, c.day_number;

-- 4. Check progress photos
SELECT 
    s.name as streak_name,
    p.day_number,
    p.photo_url,
    p.caption,
    p.created_at
FROM public.sz_posts p
JOIN public.sz_streaks s ON p.streak_id = s.id
WHERE s.code LIKE 'HIST-%'
ORDER BY s.name, p.day_number;

-- 5. Summary statistics
SELECT 
    COUNT(DISTINCT s.id) as total_streaks,
    COUNT(DISTINCT sm.user_id) as total_users,
    COUNT(DISTINCT c.id) as total_checkins,
    COUNT(DISTINCT p.id) as total_posts,
    SUM(sm.total_points) as total_points_earned
FROM public.sz_streaks s
JOIN public.sz_streak_members sm ON s.id = sm.streak_id
LEFT JOIN public.sz_checkins c ON s.id = c.streak_id
LEFT JOIN public.sz_posts p ON s.id = p.streak_id
WHERE s.code LIKE 'HIST-%';
