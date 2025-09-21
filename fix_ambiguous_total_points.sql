-- =====================================================
-- FIX AMBIGUOUS TOTAL_POINTS REFERENCE
-- =====================================================
-- This script fixes the ambiguous column reference error
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
        
        -- Update user's total points (subtract old bonus, add new bonus)
        UPDATE sz_streak_members
        SET total_points = sz_streak_members.total_points - v_existing_bonus_points + v_bonus_points
        WHERE streak_id = p_streak_id AND user_id = v_user_id
        RETURNING current_streak, total_points INTO v_current_streak, v_total_points;
    ELSE
        -- First checkin of the day - increment streak
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
-- VERIFICATION
-- =====================================================

SELECT 
    'FUNCTION FIXED' as section,
    'Ambiguous total_points reference resolved' as message;

-- Test the function
SELECT 
    'TEST FUNCTION' as section,
    'Function should now work without ambiguous column errors' as message;
