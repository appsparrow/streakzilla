-- =====================================================
-- UPDATE CORE HABITS FOR EXISTING TEMPLATE-BASED STREAKS
-- =====================================================
-- This script synchronizes sz_user_habits for existing streaks
-- based on '75_hard' and '75_hard_plus' templates with the
-- latest core habit definitions and point settings.
-- =====================================================

DO $$
DECLARE
    v_hard_template_id UUID;
    v_hard_plus_template_id UUID;
    r_streak RECORD;
    r_template_habit RECORD;
    v_user_habit_id UUID;
    v_habit_id UUID;
    v_habit_title TEXT;
    v_habit_description TEXT;
    v_habit_category TEXT;
    v_habit_frequency TEXT;
    v_habit_default_points INTEGER;
    v_is_core BOOLEAN;
    v_points_override INTEGER;
BEGIN
    -- Get template IDs
    SELECT id INTO v_hard_template_id FROM public.sz_templates WHERE key = '75_hard';
    SELECT id INTO v_hard_plus_template_id FROM public.sz_templates WHERE key = '75_hard_plus';

    RAISE NOTICE 'Starting update for existing template-based streaks...';
    RAISE NOTICE '75 Hard Template ID: %', v_hard_template_id;
    RAISE NOTICE '75 Hard Plus Template ID: %', v_hard_plus_template_id;

    -- Iterate through all active streaks that use '75_hard' or '75_hard_plus' templates
    FOR r_streak IN
        SELECT
            s.id AS streak_id,
            s.name AS streak_name,
            s.template_id,
            s.mode,
            sm.user_id AS member_user_id
        FROM public.sz_streaks s
        JOIN public.sz_streak_members sm ON s.id = sm.streak_id
        WHERE s.template_id IN (v_hard_template_id, v_hard_plus_template_id)
          AND s.is_active = TRUE -- Only update active streaks
    LOOP
        RAISE NOTICE 'Processing Streak: % (ID: %, Mode: %, Member: %)', r_streak.streak_name, r_streak.streak_id, r_streak.mode, r_streak.member_user_id;

        -- Step 1: Update existing sz_user_habits for this streak member
        -- Mark habits as core/non-core and set points_override based on the template
        UPDATE public.sz_user_habits uh
        SET
            is_core = th.is_core,
            points_override = CASE
                WHEN r_streak.mode = '75_hard_plus' AND th.is_core = TRUE THEN 0 -- Core habits in 75 Hard Plus give 0 points
                WHEN r_streak.mode = '75_hard' AND th.is_core = TRUE THEN NULL -- Core habits in 75 Hard use default points (NULL override)
                ELSE th.points_override -- Use template's override for bonus habits or specific overrides
            END,
            updated_at = now()
        FROM public.sz_template_habits th
        JOIN public.sz_habits h ON th.habit_id = h.id
        WHERE uh.streak_id = r_streak.streak_id
          AND uh.user_id = r_streak.member_user_id
          AND uh.habit_id = th.habit_id
          AND th.template_id = r_streak.template_id;

        RAISE NOTICE '  Updated existing user habits for streak % and member %', r_streak.streak_id, r_streak.member_user_id;

        -- Step 2: Insert any missing core habits from the template into sz_user_habits for this streak member
        FOR r_template_habit IN
            SELECT
                h.id AS habit_id,
                h.title AS habit_title,
                h.description AS habit_description,
                h.category AS habit_category,
                h.frequency AS habit_frequency,
                h.points AS habit_default_points,
                th.is_core,
                th.points_override
            FROM public.sz_template_habits th
            JOIN public.sz_habits h ON th.habit_id = h.id
            WHERE th.template_id = r_streak.template_id
              AND th.is_core = TRUE -- Only consider core habits for insertion
        LOOP
            -- Check if this core habit already exists for the user in this streak
            SELECT id INTO v_user_habit_id
            FROM public.sz_user_habits
            WHERE streak_id = r_streak.streak_id
              AND user_id = r_streak.member_user_id
              AND habit_id = r_template_habit.habit_id;

            IF v_user_habit_id IS NULL THEN
                -- Habit is missing, insert it
                INSERT INTO public.sz_user_habits (
                    user_id,
                    streak_id,
                    habit_id,
                    title,
                    description,
                    category,
                    frequency,
                    points,
                    is_core,
                    points_override,
                    created_at,
                    updated_at
                ) VALUES (
                    r_streak.member_user_id,
                    r_streak.streak_id,
                    r_template_habit.habit_id,
                    r_template_habit.habit_title,
                    r_template_habit.habit_description,
                    r_template_habit.habit_category,
                    r_template_habit.habit_frequency,
                    r_template_habit.habit_default_points,
                    r_template_habit.is_core,
                    CASE
                        WHEN r_streak.mode = '75_hard_plus' AND r_template_habit.is_core = TRUE THEN 0
                        WHEN r_streak.mode = '75_hard' AND r_template_habit.is_core = TRUE THEN NULL
                        ELSE r_template_habit.points_override
                    END,
                    now(),
                    now()
                );
                RAISE NOTICE '  Inserted missing core habit "%" for streak % and member %', r_template_habit.habit_title, r_streak.streak_id, r_streak.member_user_id;
            END IF;
            v_user_habit_id := NULL; -- Reset for next iteration
        END LOOP;

        -- Step 3: Mark any user habits that are NOT in the template's core list as non-core (bonus)
        UPDATE public.sz_user_habits uh
        SET
            is_core = FALSE,
            points_override = NULL, -- Use default points for bonus habits
            updated_at = now()
        WHERE uh.streak_id = r_streak.streak_id
          AND uh.user_id = r_streak.member_user_id
          AND uh.is_core = TRUE -- Only consider habits currently marked as core
          AND NOT EXISTS (
            SELECT 1
            FROM public.sz_template_habits th_check
            WHERE th_check.template_id = r_streak.template_id
              AND th_check.habit_id = uh.habit_id
              AND th_check.is_core = TRUE
          );
        RAISE NOTICE '  Marked non-template core habits as bonus for streak % and member %', r_streak.streak_id, r_streak.member_user_id;

    END LOOP;

    RAISE NOTICE 'Finished updating existing template-based streaks.';
END $$;

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check the specific streak mentioned
SELECT
    'SPECIFIC STREAK CHECK' as section,
    s.id AS streak_id,
    s.name AS streak_name,
    s.mode,
    s.template_id,
    t.name as template_name
FROM public.sz_streaks s
LEFT JOIN public.sz_templates t ON s.template_id = t.id
WHERE s.id = '55e675ae-6937-4ece-a5b6-156115a797d2';

-- Verify 75 Hard streaks
SELECT
    '75 HARD STREAKS VERIFICATION' as section,
    s.name AS streak_name,
    s.mode,
    u.email AS member_email,
    uh.title AS user_habit_title,
    uh.is_core,
    uh.points_override,
    uh.points AS default_points
FROM public.sz_streaks s
JOIN public.sz_streak_members sm ON s.id = sm.streak_id
JOIN auth.users u ON sm.user_id = u.id
JOIN public.sz_user_habits uh ON sm.user_id = uh.user_id AND s.id = uh.streak_id
WHERE s.template_id = (SELECT id FROM public.sz_templates WHERE key = '75_hard')
ORDER BY s.name, u.email, uh.is_core DESC, uh.title;

-- Verify 75 Hard Plus streaks
SELECT
    '75 HARD PLUS STREAKS VERIFICATION' as section,
    s.name AS streak_name,
    s.mode,
    u.email AS member_email,
    uh.title AS user_habit_title,
    uh.is_core,
    uh.points_override,
    uh.points AS default_points
FROM public.sz_streaks s
JOIN public.sz_streak_members sm ON s.id = sm.streak_id
JOIN auth.users u ON sm.user_id = u.id
JOIN public.sz_user_habits uh ON sm.user_id = uh.user_id AND s.id = uh.streak_id
WHERE s.template_id = (SELECT id FROM public.sz_templates WHERE key = '75_hard_plus')
ORDER BY s.name, u.email, uh.is_core DESC, uh.title;

-- Summary of changes
SELECT 
    'UPDATE SUMMARY' as section,
    'All existing streaks updated to match template definitions' as message,
    'Core habits now properly marked and points calculated correctly' as details;
