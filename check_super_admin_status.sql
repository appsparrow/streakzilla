-- =====================================================
-- CHECK SUPER ADMIN STATUS AND TEMPLATE SYSTEM
-- =====================================================

-- 1. Check if sz_user_roles table exists and has any super admins
SELECT 
    'SUPER ADMIN STATUS' as section,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sz_user_roles') 
        THEN 'Table exists'
        ELSE 'Table does not exist'
    END as table_status;

-- 2. Check existing super admin users (if table exists)
SELECT 
    'SUPER ADMIN USERS' as section,
    ur.user_id,
    u.email,
    ur.role,
    ur.granted_at,
    ur.is_active
FROM public.sz_user_roles ur
JOIN auth.users u ON ur.user_id = u.id
WHERE ur.role = 'super_admin' AND ur.is_active = true;

-- 3. Check template system status
SELECT 
    'TEMPLATE SYSTEM STATUS' as section,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sz_templates') 
        THEN 'Templates table exists'
        ELSE 'Templates table does not exist'
    END as templates_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sz_template_habits') 
        THEN 'Template habits table exists'
        ELSE 'Template habits table does not exist'
    END as template_habits_status;

-- 4. Check existing templates
SELECT 
    'EXISTING TEMPLATES' as section,
    t.id,
    t.key,
    t.name,
    t.description,
    t.allow_custom_habits,
    COUNT(th.id) as habit_count
FROM public.sz_templates t
LEFT JOIN public.sz_template_habits th ON t.id = th.template_id
GROUP BY t.id, t.key, t.name, t.description, t.allow_custom_habits
ORDER BY t.name;

-- 5. Check template habits mapping
SELECT 
    'TEMPLATE HABITS MAPPING' as section,
    t.name as template_name,
    h.title as habit_title,
    th.is_core,
    th.points_override,
    th.sort_order
FROM public.sz_template_habits th
JOIN public.sz_templates t ON th.template_id = t.id
JOIN public.sz_habits h ON th.habit_id = h.id
ORDER BY t.name, th.sort_order, h.title;

-- 6. Check current user_habits data that could be migrated
SELECT 
    'CURRENT USER HABITS DATA' as section,
    COUNT(*) as total_user_habits,
    COUNT(DISTINCT streak_id) as unique_streaks,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT habit_id) as unique_habits
FROM public.sz_user_habits;

-- 7. Check streaks that could benefit from template migration
SELECT 
    'STREAKS WITHOUT TEMPLATES' as section,
    s.mode,
    COUNT(*) as count,
    COUNT(CASE WHEN s.template_id IS NULL THEN 1 END) as without_template
FROM public.sz_streaks s
GROUP BY s.mode
ORDER BY s.mode;

-- 8. Sample of user habits that could be migrated
SELECT 
    'SAMPLE USER HABITS FOR MIGRATION' as section,
    s.name as streak_name,
    s.mode,
    s.template_id,
    u.email as user_email,
    h.title as habit_title,
    h.template_set,
    uh.created_at
FROM public.sz_user_habits uh
JOIN public.sz_streaks s ON uh.streak_id = s.id
JOIN auth.users u ON uh.user_id = u.id
JOIN public.sz_habits h ON uh.habit_id = h.id
ORDER BY s.created_at DESC, h.title
LIMIT 20;
