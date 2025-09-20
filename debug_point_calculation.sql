-- =====================================================
-- DEBUG POINT CALCULATION ISSUE
-- =====================================================

-- 1. Check current template mappings
SELECT 
    'TEMPLATE MAPPINGS' as section,
    t.name as template_name,
    h.title as habit_title,
    h.template_set,
    th.is_core,
    th.points_override,
    h.points as default_points
FROM public.sz_template_habits th
JOIN public.sz_templates t ON th.template_id = t.id
JOIN public.sz_habits h ON th.habit_id = h.id
WHERE t.key = '75_hard_plus'
ORDER BY th.sort_order, h.title;

-- 2. Check recent check-ins and points
SELECT 
    'RECENT CHECK-INS' as section,
    s.name as streak_name,
    s.mode,
    c.day_number,
    c.points_earned,
    c.completed_habit_ids,
    c.photo_url,
    u.email
FROM public.sz_checkins c
JOIN public.sz_streaks s ON c.streak_id = s.id
JOIN auth.users u ON c.user_id = u.id
WHERE s.mode = '75_hard_plus'
ORDER BY c.created_at DESC
LIMIT 5;

-- 3. Check user habits for 75 Hard Plus streaks
SELECT 
    'USER HABITS IN 75 HARD PLUS' as section,
    s.name as streak_name,
    u.email,
    h.title as habit_title,
    h.template_set,
    h.points as habit_points,
    th.is_core,
    th.points_override
FROM public.sz_user_habits uh
JOIN public.sz_streaks s ON uh.streak_id = s.id
JOIN auth.users u ON uh.user_id = u.id
JOIN public.sz_habits h ON uh.habit_id = h.id
LEFT JOIN public.sz_template_habits th ON th.template_id = s.template_id AND th.habit_id = h.id
WHERE s.mode = '75_hard_plus'
ORDER BY s.name, u.email, h.title;

-- 4. Check streak member points
SELECT 
    'STREAK MEMBER POINTS' as section,
    s.name as streak_name,
    u.email,
    sm.total_points,
    sm.current_streak,
    s.mode
FROM public.sz_streak_members sm
JOIN public.sz_streaks s ON sm.streak_id = s.id
JOIN auth.users u ON sm.user_id = u.id
WHERE s.mode = '75_hard_plus'
ORDER BY s.name, sm.total_points DESC;

-- 5. Check the point calculation logic issue
-- The issue is likely in the template_set comparison
SELECT 
    'POINT CALCULATION DEBUG' as section,
    h.title,
    h.template_set,
    CASE 
        WHEN h.template_set != '75_hard' THEN 'SHOULD GET POINTS (bonus)'
        ELSE 'SHOULD NOT GET POINTS (core)'
    END as point_status,
    h.points
FROM public.sz_habits h
WHERE h.title IN ('Take a progress photo', 'Follow a diet', 'No Alcohol', 'Drink 1 gallon of water', 'Two 45-minute workouts', 'Read 10 pages of non-fiction')
ORDER BY h.title;
