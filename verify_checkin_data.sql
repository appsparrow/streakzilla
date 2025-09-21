-- Replace 'YOUR_STREAK_ID' and 'YOUR_USER_ID' with actual values from your browser URL/network tab
-- Example: streak ID from URL like /streak/55e675ae-6937-4ece-a5b6-156115a797d2

-- A) See exactly what's saved for today (most recent checkins)
SELECT 
    id, 
    day_number, 
    completed_habit_ids,
    array_length(completed_habit_ids, 1) AS habit_count,
    points_earned, 
    created_at
FROM public.sz_checkins
WHERE streak_id = 'YOUR_STREAK_ID' 
  AND user_id = 'YOUR_USER_ID'
ORDER BY created_at DESC
LIMIT 5;

-- B) Human-readable list of completed habits for today
SELECT 
    c.day_number,
    h.title,
    h.category,
    h.points
FROM public.sz_checkins c
JOIN public.sz_habits h ON h.id = ANY(c.completed_habit_ids)
WHERE c.streak_id = 'YOUR_STREAK_ID' 
  AND c.user_id = 'YOUR_USER_ID'
ORDER BY c.created_at DESC, h.title;

-- C) Check if there are multiple checkins for the same day (should be only 1)
SELECT 
    day_number,
    COUNT(*) as checkin_count,
    array_agg(id ORDER BY created_at) as checkin_ids
FROM public.sz_checkins
WHERE streak_id = 'YOUR_STREAK_ID' 
  AND user_id = 'YOUR_USER_ID'
GROUP BY day_number
HAVING COUNT(*) > 1
ORDER BY day_number;

-- D) Verify the 6 core habits for your template
SELECT 
    t.name as template_name,
    h.title as habit_title,
    th.is_core,
    th.points_override,
    h.points as default_points
FROM public.sz_templates t
JOIN public.sz_template_habits th ON th.template_id = t.id
JOIN public.sz_habits h ON h.id = th.habit_id
WHERE t.id = (
    SELECT template_id 
    FROM public.sz_streaks 
    WHERE id = 'YOUR_STREAK_ID'
)
ORDER BY th.sort_order;

-- E) Check current streak member totals
SELECT 
    current_streak,
    total_points,
    lives_remaining,
    hearts_available
FROM public.sz_streak_members
WHERE streak_id = 'YOUR_STREAK_ID' 
  AND user_id = 'YOUR_USER_ID';
