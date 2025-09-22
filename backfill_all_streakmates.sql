-- Backfill all streakmates with completed check-ins for Days 1, 2, 3
-- This will make everyone current and consistent

-- First, let's see current state
SELECT 
    'BEFORE_BACKFILL' as status,
    user_id,
    current_streak,
    total_points,
    lives_remaining
FROM public.sz_streak_members
WHERE streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2'
ORDER BY user_id;

-- Get all member user IDs for this streak
WITH streak_members AS (
    SELECT user_id
    FROM public.sz_streak_members
    WHERE streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2'
),
-- Get all habits for this streak (core + bonus)
all_habits AS (
    SELECT h.id as habit_id
    FROM public.sz_habits h
    JOIN public.sz_template_habits th ON th.habit_id = h.id
    JOIN public.sz_streaks s ON s.template_id = th.template_id
    WHERE s.id = '55e675ae-6937-4ece-a5b6-156115a797d2'
),
-- Get habit IDs as array
habit_ids AS (
    SELECT array_agg(habit_id) as all_habit_ids
    FROM all_habits
)
-- Insert check-ins for all members for days 1, 2, 3
INSERT INTO public.sz_checkins (
    id,
    user_id,
    streak_id,
    day_number,
    completed_habit_ids,
    points_earned,
    note,
    photo_url,
    created_at
)
SELECT 
    gen_random_uuid(),
    sm.user_id,
    '55e675ae-6937-4ece-a5b6-156115a797d2',
    day_num,
    hi.all_habit_ids,
    -- Calculate points: 0 for core habits in 75_hard_plus, full points for bonus
    (
        SELECT COALESCE(SUM(
            CASE 
                WHEN th.is_core = true THEN 0  -- Core habits give 0 points in hard plus
                ELSE COALESCE(th.points_override, h.points, 0)  -- Bonus habits give full points
            END
        ), 0)
        FROM public.sz_habits h
        JOIN public.sz_template_habits th ON th.habit_id = h.id
        JOIN public.sz_streaks s ON s.template_id = th.template_id
        WHERE h.id = ANY(hi.all_habit_ids)
          AND s.id = '55e675ae-6937-4ece-a5b6-156115a797d2'
    ) + 5, -- +5 for progress photo bonus
    'Backfilled check-in - all habits completed',
    'https://example.com/photo.jpg',
    now() - INTERVAL (3 - day_num) || ' days'
FROM streak_members sm
CROSS JOIN (SELECT unnest(ARRAY[1,2,3]) as day_num) days
CROSS JOIN habit_ids hi
WHERE NOT EXISTS (
    -- Only insert if check-in doesn't already exist
    SELECT 1 FROM public.sz_checkins c
    WHERE c.streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2'
      AND c.user_id = sm.user_id
      AND c.day_number = days.day_num
);

-- Update streak member totals
UPDATE public.sz_streak_members
SET 
    current_streak = 3,  -- All 3 days completed
    total_points = (
        -- Calculate total points for all 3 days
        SELECT COALESCE(SUM(c.points_earned), 0)
        FROM public.sz_checkins c
        WHERE c.streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2'
          AND c.user_id = public.sz_streak_members.user_id
    ),
    lives_remaining = GREATEST(lives_remaining, 3)  -- Give everyone at least 3 lives
WHERE streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2';

-- Show results after backfill
SELECT 
    'AFTER_BACKFILL' as status,
    user_id,
    current_streak,
    total_points,
    lives_remaining
FROM public.sz_streak_members
WHERE streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2'
ORDER BY user_id;

-- Show check-ins created
SELECT 
    'CHECKINS_CREATED' as status,
    user_id,
    day_number,
    array_length(completed_habit_ids, 1) as habits_completed,
    points_earned,
    created_at
FROM public.sz_checkins
WHERE streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2'
ORDER BY user_id, day_number;
