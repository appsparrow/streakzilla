-- =====================================================
-- EXAMPLE: Populate Historical 75 Hard Plus Data
-- =====================================================
-- 
-- This is a working example with 2 sample users
-- Replace the data below with your actual user data
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
    -- Loop through each user
    FOR user_record IN 
        SELECT 
            'REPLACE_WITH_ACTUAL_USER_ID_1'::uuid as user_id,
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
            'REPLACE_WITH_ACTUAL_USER_ID_2'::uuid as user_id,
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
        
        -- Add more users here by copying the pattern above
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
            false  -- Mark as completed
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
        -- 4. CREATE BACKDATED CHECK-INS (75 days)
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
                current_date + interval '18 hours'  -- 6 PM check-in
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
                'https://example.com/progress-photos/' || user_record.user_id || '/day-' || day_counter || '.jpg',
                'Day ' || day_counter || ' progress photo - Historical data',
                current_date + interval '20 hours'  -- 8 PM photo
            ) RETURNING id INTO post_id;
            
            -- Move to next day
            current_date := current_date + interval '1 day';
            day_counter := day_counter + 1;
        END LOOP;
        
        -- =====================================================
        -- 5. UPDATE TOTAL POINTS
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

-- Check what was created
SELECT 
    'HISTORICAL STREAKS CREATED' as section,
    COUNT(*) as count
FROM public.sz_streaks s
WHERE s.code LIKE 'HIST-%'

UNION ALL

SELECT 
    'USERS ADDED TO STREAKS' as section,
    COUNT(*) as count
FROM public.sz_streak_members sm
JOIN public.sz_streaks s ON sm.streak_id = s.id
WHERE s.code LIKE 'HIST-%'

UNION ALL

SELECT 
    'CHECK-INS CREATED' as section,
    COUNT(*) as count
FROM public.sz_checkins c
JOIN public.sz_streaks s ON c.streak_id = s.id
WHERE s.code LIKE 'HIST-%'

UNION ALL

SELECT 
    'PROGRESS PHOTOS CREATED' as section,
    COUNT(*) as count
FROM public.sz_posts p
JOIN public.sz_streaks s ON p.streak_id = s.id
WHERE s.code LIKE 'HIST-%';

-- Show detailed results
SELECT 
    s.name as streak_name,
    s.start_date,
    s.end_date,
    sm.user_id,
    sm.current_streak,
    sm.total_points,
    COUNT(c.id) as checkins_created,
    COUNT(p.id) as photos_created
FROM public.sz_streaks s
JOIN public.sz_streak_members sm ON s.id = sm.streak_id
LEFT JOIN public.sz_checkins c ON s.id = c.streak_id AND sm.user_id = c.user_id
LEFT JOIN public.sz_posts p ON s.id = p.streak_id AND sm.user_id = p.user_id
WHERE s.code LIKE 'HIST-%'
GROUP BY s.id, s.name, s.start_date, s.end_date, sm.user_id, sm.current_streak, sm.total_points
ORDER BY s.created_at DESC;
