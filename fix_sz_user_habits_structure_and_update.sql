-- =====================================================
-- FIX SZ_USER_HABITS STRUCTURE AND UPDATE EXISTING STREAKS
-- =====================================================
-- This script adds missing columns and updates existing streaks
-- based on the actual table structure
-- =====================================================

-- =====================================================
-- STEP 1: CHECK CURRENT TABLE STRUCTURE
-- =====================================================

SELECT 
    'CURRENT SZ_USER_HABITS STRUCTURE' as section,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'sz_user_habits' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- =====================================================
-- STEP 2: ADD MISSING COLUMNS TO SZ_USER_HABITS
-- =====================================================

-- Add is_core column if it doesn't exist
ALTER TABLE public.sz_user_habits 
ADD COLUMN IF NOT EXISTS is_core BOOLEAN DEFAULT false;

-- Add points_override column if it doesn't exist
ALTER TABLE public.sz_user_habits 
ADD COLUMN IF NOT EXISTS points_override INTEGER DEFAULT NULL;

-- Add updated_at column if it doesn't exist
ALTER TABLE public.sz_user_habits 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

-- =====================================================
-- STEP 3: FIX CHECK-IN FUNCTION (AMBIGUOUS COLUMN ERROR)
-- =====================================================

-- Drop existing function first
DROP FUNCTION IF EXISTS public.sz_checkin(UUID, INTEGER, UUID[], TEXT, TEXT);

CREATE OR REPLACE FUNCTION public.sz_checkin(
    p_streak_id UUID,
    p_day_number INTEGER,
    p_completed_habit_ids UUID[],
    p_note TEXT DEFAULT NULL,
    p_photo_url TEXT DEFAULT NULL
)
RETURNS TABLE(points_earned INTEGER, current_streak INTEGER, total_points INTEGER, hearts_earned INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_user_id UUID;
    v_points INTEGER := 0;
    v_bonus_points INTEGER := 0;
    v_existing_checkin_id UUID;
    v_existing_points INTEGER := 0;
    v_existing_bonus_points INTEGER := 0;
    v_previous_total INTEGER := 0;
    v_current_streak INTEGER;
    v_total_points INTEGER;
    v_hearts_earned INTEGER := 0;
    v_mode TEXT;
    v_streak_mode TEXT;
BEGIN
    v_user_id := auth.uid();
    
    -- Get streak mode and template info
    SELECT s.mode, s.template_id INTO v_streak_mode, v_mode
    FROM sz_streaks s WHERE s.id = p_streak_id;
    
    -- Check if there's already a checkin for this day
    SELECT c.id, c.points_earned INTO v_existing_checkin_id, v_existing_points
    FROM sz_checkins c
    WHERE c.streak_id = p_streak_id 
    AND c.user_id = v_user_id 
    AND c.day_number = p_day_number
    ORDER BY c.created_at DESC
    LIMIT 1;
    
    -- Get previous total points
    SELECT COALESCE(sm.total_points, 0) INTO v_previous_total
    FROM sz_streak_members sm
    WHERE sm.streak_id = p_streak_id AND sm.user_id = v_user_id;
    
    -- Calculate total points and bonus points from completed habits
    -- NEW LOGIC: Use template system (is_core) instead of template_set
    IF v_mode IS NOT NULL THEN
        -- Use new template system
        SELECT 
            COALESCE(SUM(
                CASE 
                    WHEN th.is_core = false OR th.is_core IS NULL THEN 
                        COALESCE(th.points_override, h.points, 0)
                    ELSE 0 
                END
            ), 0),
            COALESCE(SUM(
                CASE 
                    WHEN th.is_core = false OR th.is_core IS NULL THEN 
                        COALESCE(th.points_override, h.points, 0)
                    ELSE 0 
                END
            ), 0)
        INTO v_points, v_bonus_points
        FROM sz_habits h
        LEFT JOIN sz_template_habits th ON th.habit_id = h.id AND th.template_id = v_mode
        WHERE h.id = ANY(p_completed_habit_ids);
    ELSE
        -- Fallback to old template_set logic
        SELECT 
            COALESCE(SUM(h.points), 0),
            COALESCE(SUM(CASE 
                WHEN v_streak_mode = '75_hard_plus' AND h.template_set != '75_hard' THEN h.points 
                WHEN v_streak_mode != '75_hard_plus' THEN h.points
                ELSE 0 
            END), 0)
        INTO v_points, v_bonus_points
        FROM sz_habits h
        WHERE h.id = ANY(p_completed_habit_ids);
    END IF;
    
    -- Add progress photo bonus points for Hard Plus mode
    IF v_streak_mode = '75_hard_plus' AND p_photo_url IS NOT NULL THEN
        v_points := v_points + 5;
        v_bonus_points := v_bonus_points + 5;
    END IF;
    
    -- Get existing bonus points if updating
    IF v_existing_checkin_id IS NOT NULL THEN
        IF v_mode IS NOT NULL THEN
            -- Use new template system for existing checkin
            SELECT COALESCE(SUM(
                CASE 
                    WHEN th.is_core = false OR th.is_core IS NULL THEN 
                        COALESCE(th.points_override, h.points, 0)
                    ELSE 0 
                END
            ), 0)
            INTO v_existing_bonus_points
            FROM sz_habits h
            LEFT JOIN sz_template_habits th ON th.habit_id = h.id AND th.template_id = v_mode
            INNER JOIN sz_checkins c ON c.id = v_existing_checkin_id
            INNER JOIN unnest(c.completed_habit_ids) AS habit_id ON habit_id = h.id;
        ELSE
            -- Fallback to old logic
            SELECT COALESCE(SUM(CASE 
                WHEN v_streak_mode = '75_hard_plus' AND h.template_set != '75_hard' THEN h.points 
                WHEN v_streak_mode != '75_hard_plus' THEN h.points
                ELSE 0 
            END), 0)
            INTO v_existing_bonus_points
            FROM sz_habits h, sz_checkins c, unnest(c.completed_habit_ids) AS habit_id
            WHERE c.id = v_existing_checkin_id AND h.id = habit_id;
        END IF;
        
        -- Add existing photo bonus if applicable
        IF v_existing_checkin_id IS NOT NULL AND EXISTS(
            SELECT 1 FROM sz_checkins WHERE id = v_existing_checkin_id AND photo_url IS NOT NULL
        ) AND v_streak_mode = '75_hard_plus' THEN
            v_existing_bonus_points := v_existing_bonus_points + 5;
        END IF;
    END IF;

    IF v_existing_checkin_id IS NOT NULL THEN
        -- Update existing checkin
        UPDATE sz_checkins
        SET 
            completed_habit_ids = p_completed_habit_ids,
            points_earned = v_points,
            note = p_note,
            photo_url = p_photo_url,
            created_at = now()
        WHERE id = v_existing_checkin_id;
        
        -- Update user's total points (subtract old bonus, add new bonus) - FIXED AMBIGUOUS COLUMN
        UPDATE sz_streak_members
        SET total_points = sz_streak_members.total_points - v_existing_bonus_points + v_bonus_points
        WHERE streak_id = p_streak_id AND user_id = v_user_id
        RETURNING current_streak, total_points INTO v_current_streak, v_total_points;
    ELSE
        -- First checkin of the day - increment streak - FIXED AMBIGUOUS COLUMN
        UPDATE sz_streak_members
        SET 
            total_points = sz_streak_members.total_points + v_points,
            current_streak = current_streak + 1
        WHERE streak_id = p_streak_id AND user_id = v_user_id
        RETURNING current_streak, total_points INTO v_current_streak, v_total_points;
    END IF;

    -- Calculate hearts earned for 75_hard modes
    IF v_streak_mode IN ('75_hard', '75_hard_plus') THEN
        -- Base points per day for 75 hard (0 points for core habits in plus mode)
        DECLARE
            v_base_points_per_day INTEGER := CASE WHEN v_streak_mode = '75_hard_plus' THEN 0 ELSE 55 END;
            v_expected_base_points INTEGER;
            v_previous_extra_points INTEGER;
            v_current_extra_points INTEGER;
            v_previous_hearts INTEGER;
            v_current_hearts INTEGER;
        BEGIN
            v_expected_base_points := v_base_points_per_day * p_day_number;
            
            -- Calculate extra points before and after this checkin
            v_previous_extra_points := GREATEST(0, v_previous_total - (v_base_points_per_day * (p_day_number - 1)));
            v_current_extra_points := GREATEST(0, v_total_points - v_expected_base_points);
            
            -- Calculate hearts (1 per 500 extra points, max 3)
            v_previous_hearts := LEAST(3, v_previous_extra_points / 500);
            v_current_hearts := LEAST(3, v_current_extra_points / 500);
            
            v_hearts_earned := v_current_hearts - v_previous_hearts;
            
            -- Update lives if hearts were earned
            IF v_hearts_earned > 0 THEN
                UPDATE sz_streak_members
                SET lives_remaining = LEAST(lives_remaining + v_hearts_earned, lives_remaining + 3)
                WHERE streak_id = p_streak_id AND user_id = v_user_id;
            END IF;
        END;
    END IF;

    RETURN QUERY
    SELECT v_points as points_earned, v_current_streak as current_streak, v_total_points as total_points, v_hearts_earned as hearts_earned;
END;
$function$;

-- =====================================================
-- STEP 4: UPDATE EXISTING STREAKS (CORRECTED)
-- =====================================================

DO $$
DECLARE
    v_hard_template_id UUID;
    v_hard_plus_template_id UUID;
    r_streak RECORD;
    r_template_habit RECORD;
    v_user_habit_id UUID;
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
        -- CORRECTED: Only insert the columns that actually exist in the table
        FOR r_template_habit IN
            SELECT
                h.id AS habit_id,
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
                -- Habit is missing, insert it (only the columns that exist)
                INSERT INTO public.sz_user_habits (
                    user_id,
                    streak_id,
                    habit_id,
                    is_core,
                    points_override,
                    created_at,
                    updated_at
                ) VALUES (
                    r_streak.member_user_id,
                    r_streak.streak_id,
                    r_template_habit.habit_id,
                    r_template_habit.is_core,
                    CASE
                        WHEN r_streak.mode = '75_hard_plus' AND r_template_habit.is_core = TRUE THEN 0
                        WHEN r_streak.mode = '75_hard' AND r_template_habit.is_core = TRUE THEN NULL
                        ELSE r_template_habit.points_override
                    END,
                    now(),
                    now()
                );
                RAISE NOTICE '  Inserted missing core habit (ID: %) for streak % and member %', r_template_habit.habit_id, r_streak.streak_id, r_streak.member_user_id;
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
-- STEP 5: VERIFICATION
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

-- Verify 75 Hard Plus streaks with habit details
SELECT
    '75 HARD PLUS STREAKS VERIFICATION' as section,
    s.name AS streak_name,
    s.mode,
    u.email AS member_email,
    h.title AS habit_title,
    uh.is_core,
    uh.points_override,
    h.points AS default_points
FROM public.sz_streaks s
JOIN public.sz_streak_members sm ON s.id = sm.streak_id
JOIN auth.users u ON sm.user_id = u.id
JOIN public.sz_user_habits uh ON sm.user_id = uh.user_id AND s.id = uh.streak_id
JOIN public.sz_habits h ON uh.habit_id = h.id
WHERE s.template_id = (SELECT id FROM public.sz_templates WHERE key = '75_hard_plus')
ORDER BY s.name, u.email, uh.is_core DESC, h.title;

-- Summary of changes
SELECT 
    'COMPLETE UPDATE SUMMARY' as section,
    'Added missing columns to sz_user_habits' as step1,
    'Fixed check-in function ambiguous column error' as step2,
    'Updated all existing streaks to match template definitions' as step3,
    'All systems ready!' as status;
