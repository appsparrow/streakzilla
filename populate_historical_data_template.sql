-- =====================================================
-- HISTORICAL 75 HARD PLUS DATA POPULATION TEMPLATE
-- =====================================================
-- 
-- INSTRUCTIONS:
-- 1. Replace the user_data section below with your actual user data
-- 2. Run this script in Supabase SQL Editor
-- 3. The script will create complete historical data for each user
-- =====================================================

-- =====================================================
-- STEP 1: REPLACE THIS SECTION WITH YOUR USER DATA
-- =====================================================

-- Example format for each user:
-- User 1: John Doe completed 75 Hard Plus from Jan 1 to Mar 16, 2024
-- User 2: Jane Smith completed 75 Hard Plus from Feb 1 to Apr 16, 2024
-- etc.

WITH user_data AS (
  -- USER 1 - Replace with actual data
  SELECT 
    'REPLACE_WITH_USER_ID_1'::uuid as user_id,
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
  
  -- USER 2 - Replace with actual data
  SELECT 
    'REPLACE_WITH_USER_ID_2'::uuid as user_id,
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
  -- Make sure to replace the user_id, user_name, dates, and habit selections
),

-- =====================================================
-- STEP 2: THE SCRIPT AUTOMATICALLY PROCESSES THE DATA
-- =====================================================

processed_data AS (
  SELECT 
    ud.*,
    s.id as streak_id,
    array_agg(h.id ORDER BY h.title) as habit_ids,
    array_agg(h.points ORDER BY h.title) as habit_points
  FROM user_data ud
  CROSS JOIN LATERAL (
    SELECT id FROM public.sz_streaks 
    WHERE name = ud.streak_name 
    LIMIT 1
  ) existing_streak
  LEFT JOIN public.sz_habits h ON h.title = ANY(ud.selected_habits)
  GROUP BY ud.user_id, ud.user_name, ud.streak_name, ud.start_date, ud.end_date, ud.selected_habits, existing_streak.id
)

-- =====================================================
-- STEP 3: CREATE THE HISTORICAL DATA
-- =====================================================

INSERT INTO public.sz_streaks (
  name,
  code,
  mode,
  start_date,
  duration_days,
  created_by,
  is_active
)
SELECT 
  pd.streak_name,
  'HIST-' || substring(pd.user_id::text, 1, 8) || '-' || extract(epoch from pd.start_date)::integer,
  '75_hard_plus',
  pd.start_date,
  75,
  pd.user_id,
  false
FROM processed_data pd
WHERE pd.streak_id IS NULL;  -- Only create if doesn't exist

-- Add users to streak members
INSERT INTO public.sz_streak_members (
  streak_id,
  user_id,
  role,
  current_streak,
  total_points,
  lives_remaining,
  is_out
)
SELECT 
  COALESCE(pd.streak_id, s.id),
  pd.user_id,
  'admin',
  75,
  0,  -- Will be calculated later
  3,
  false
FROM processed_data pd
LEFT JOIN public.sz_streaks s ON s.name = pd.streak_name AND s.created_by = pd.user_id
WHERE NOT EXISTS (
  SELECT 1 FROM public.sz_streak_members sm 
  WHERE sm.streak_id = COALESCE(pd.streak_id, s.id) AND sm.user_id = pd.user_id
);

-- Add user habits
INSERT INTO public.sz_user_habits (
  streak_id,
  user_id,
  habit_id
)
SELECT 
  COALESCE(pd.streak_id, s.id),
  pd.user_id,
  h.id
FROM processed_data pd
LEFT JOIN public.sz_streaks s ON s.name = pd.streak_name AND s.created_by = pd.user_id
JOIN public.sz_habits h ON h.title = ANY(pd.selected_habits)
WHERE NOT EXISTS (
  SELECT 1 FROM public.sz_user_habits uh 
  WHERE uh.streak_id = COALESCE(pd.streak_id, s.id) 
    AND uh.user_id = pd.user_id 
    AND uh.habit_id = h.id
);

-- Create backdated check-ins for each day
INSERT INTO public.sz_checkins (
  streak_id,
  user_id,
  day_number,
  completed_habit_ids,
  points_earned,
  note,
  created_at
)
SELECT 
  COALESCE(pd.streak_id, s.id),
  pd.user_id,
  day_num,
  pd.habit_ids,
  COALESCE(array_sum(pd.habit_points), 0),
  'Day ' || day_num || ' completed - Historical data',
  pd.start_date + (day_num - 1) * interval '1 day' + interval '18 hours'
FROM processed_data pd
LEFT JOIN public.sz_streaks s ON s.name = pd.streak_name AND s.created_by = pd.user_id
CROSS JOIN generate_series(1, 75) as day_num
WHERE NOT EXISTS (
  SELECT 1 FROM public.sz_checkins c 
  WHERE c.streak_id = COALESCE(pd.streak_id, s.id) 
    AND c.user_id = pd.user_id 
    AND c.day_number = day_num
);

-- Create progress photos for each day
INSERT INTO public.sz_posts (
  streak_id,
  user_id,
  day_number,
  photo_url,
  caption,
  created_at
)
SELECT 
  COALESCE(pd.streak_id, s.id),
  pd.user_id,
  day_num,
  'https://example.com/progress-photos/' || pd.user_id || '/day-' || day_num || '.jpg',
  'Day ' || day_num || ' progress photo - Historical data',
  pd.start_date + (day_num - 1) * interval '1 day' + interval '20 hours'
FROM processed_data pd
LEFT JOIN public.sz_streaks s ON s.name = pd.streak_name AND s.created_by = pd.user_id
CROSS JOIN generate_series(1, 75) as day_num
WHERE NOT EXISTS (
  SELECT 1 FROM public.sz_posts p 
  WHERE p.streak_id = COALESCE(pd.streak_id, s.id) 
    AND p.user_id = pd.user_id 
    AND p.day_number = day_num
);

-- Update total points for each user
UPDATE public.sz_streak_members 
SET total_points = (
  SELECT COALESCE(SUM(points_earned), 0)
  FROM public.sz_checkins c
  WHERE c.streak_id = sz_streak_members.streak_id 
    AND c.user_id = sz_streak_members.user_id
)
WHERE streak_id IN (
  SELECT COALESCE(pd.streak_id, s.id)
  FROM processed_data pd
  LEFT JOIN public.sz_streaks s ON s.name = pd.streak_name AND s.created_by = pd.user_id
);

-- =====================================================
-- HELPER FUNCTION FOR ARRAY SUM
-- =====================================================
CREATE OR REPLACE FUNCTION array_sum(arr INTEGER[])
RETURNS INTEGER AS $$
DECLARE
    result INTEGER := 0;
    elem INTEGER;
BEGIN
    IF arr IS NULL THEN
        RETURN 0;
    END IF;
    
    FOREACH elem IN ARRAY arr
    LOOP
        result := result + COALESCE(elem, 0);
    END LOOP;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check what was created
SELECT 
  'Streaks Created' as type,
  COUNT(*) as count
FROM public.sz_streaks s
WHERE s.code LIKE 'HIST-%'

UNION ALL

SELECT 
  'Users Added' as type,
  COUNT(*) as count
FROM public.sz_streak_members sm
JOIN public.sz_streaks s ON sm.streak_id = s.id
WHERE s.code LIKE 'HIST-%'

UNION ALL

SELECT 
  'Check-ins Created' as type,
  COUNT(*) as count
FROM public.sz_checkins c
JOIN public.sz_streaks s ON c.streak_id = s.id
WHERE s.code LIKE 'HIST-%'

UNION ALL

SELECT 
  'Progress Photos Created' as type,
  COUNT(*) as count
FROM public.sz_posts p
JOIN public.sz_streaks s ON p.streak_id = s.id
WHERE s.code LIKE 'HIST-%';
