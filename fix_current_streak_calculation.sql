-- Fix current_streak calculation for all users
-- This will recalculate current_streak based on consecutive days with ALL core habits completed

-- First, let's see what the current values are
SELECT 
    'BEFORE_FIX' as status,
    user_id,
    current_streak,
    total_points
FROM public.sz_streak_members
WHERE streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2';

-- Function to recalculate current_streak for a user
CREATE OR REPLACE FUNCTION public.recalculate_current_streak(
    p_streak_id UUID,
    p_user_id UUID
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_streak INTEGER := 0;
    v_day_number INTEGER;
    v_core_habits_completed INTEGER;
    v_total_core_habits INTEGER;
    v_checkin_record RECORD;
BEGIN
    -- Get total core habits required for this template
    SELECT COUNT(*) INTO v_total_core_habits
    FROM public.sz_template_habits th
    JOIN public.sz_streaks s ON s.template_id = th.template_id
    WHERE s.id = p_streak_id AND th.is_core = true;
    
    -- Get all check-ins ordered by day (most recent first)
    FOR v_checkin_record IN 
        SELECT c.day_number, c.completed_habit_ids
        FROM public.sz_checkins c
        WHERE c.streak_id = p_streak_id 
          AND c.user_id = p_user_id
        ORDER BY c.day_number DESC
    LOOP
        -- Count core habits completed for this day
        SELECT COUNT(*) INTO v_core_habits_completed
        FROM public.sz_habits h
        JOIN public.sz_template_habits th ON th.habit_id = h.id
        JOIN public.sz_streaks s ON s.template_id = th.template_id
        WHERE h.id = ANY(v_checkin_record.completed_habit_ids)
          AND s.id = p_streak_id
          AND th.is_core = true;
        
        -- If all core habits completed, increment streak
        IF v_core_habits_completed = v_total_core_habits THEN
            v_current_streak := v_current_streak + 1;
        ELSE
            -- If not all core habits completed, streak breaks
            EXIT;
        END IF;
    END LOOP;
    
    RETURN v_current_streak;
END;
$$;

-- Update current_streak for all members of this streak
UPDATE public.sz_streak_members
SET current_streak = public.recalculate_current_streak(streak_id, user_id)
WHERE streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2';

-- Show results after fix
SELECT 
    'AFTER_FIX' as status,
    user_id,
    current_streak,
    total_points
FROM public.sz_streak_members
WHERE streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2';

-- Clean up
DROP FUNCTION public.recalculate_current_streak(UUID, UUID);
