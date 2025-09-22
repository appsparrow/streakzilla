-- Check what's causing the streak calculation issue
-- This will show us exactly what's stored and what should be calculated

-- 1. Check current streak member data
SELECT 
    'CURRENT_STREAK_DATA' as section,
    current_streak,
    total_points,
    lives_remaining
FROM public.sz_streak_members
WHERE streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2' 
  AND user_id = 'YOUR_USER_ID';

-- 2. Check all check-ins for this user
SELECT 
    'ALL_CHECKINS' as section,
    day_number,
    array_length(completed_habit_ids, 1) as habits_completed,
    points_earned,
    created_at
FROM public.sz_checkins
WHERE streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2' 
  AND user_id = 'YOUR_USER_ID'
ORDER BY day_number;

-- 3. Check which check-ins should count as "streak days" (all core habits completed)
SELECT 
    'STREAK_ELIGIBLE_CHECKINS' as section,
    c.day_number,
    array_length(c.completed_habit_ids, 1) as total_habits,
    -- Count core habits completed
    (
        SELECT COUNT(*)
        FROM public.sz_habits h
        JOIN public.sz_template_habits th ON th.habit_id = h.id
        WHERE h.id = ANY(c.completed_habit_ids)
          AND th.template_id = (SELECT template_id FROM public.sz_streaks WHERE id = '55e675ae-6937-4ece-a5b6-156115a797d2')
          AND th.is_core = true
    ) as core_habits_completed,
    -- Total core habits required
    (
        SELECT COUNT(*)
        FROM public.sz_template_habits th
        WHERE th.template_id = (SELECT template_id FROM public.sz_streaks WHERE id = '55e675ae-6937-4ece-a5b6-156115a797d2')
          AND th.is_core = true
    ) as total_core_habits_required,
    c.created_at
FROM public.sz_checkins c
WHERE c.streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2' 
  AND c.user_id = 'YOUR_USER_ID'
ORDER BY c.day_number;
