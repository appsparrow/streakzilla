-- Fix RLS policy for streak deletion - allow admins and creators to update streaks
DROP POLICY IF EXISTS "Creators can update their streaks" ON sz_streaks;
CREATE POLICY "Creators and admins can update streaks" ON sz_streaks
FOR UPDATE USING (
  (auth.uid() = created_by) OR 
  (EXISTS (
    SELECT 1 FROM sz_streak_members sm
    WHERE sm.streak_id = sz_streaks.id 
    AND sm.user_id = auth.uid() 
    AND sm.role = 'admin'
  ))
);

-- Fix sz_checkin function to prevent double counting on same day
CREATE OR REPLACE FUNCTION public.sz_checkin(p_streak_id uuid, p_day_number integer, p_completed_habit_ids uuid[], p_note text DEFAULT NULL::text, p_photo_url text DEFAULT NULL::text)
 RETURNS TABLE(points_earned integer, current_streak integer, total_points integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_user_id UUID;
    v_points INTEGER := 0;
    v_current_streak INTEGER;
    v_total_points INTEGER;
    v_existing_checkin_id UUID;
    v_existing_points INTEGER := 0;
BEGIN
    v_user_id := auth.uid();
    
    -- Check if there's already a checkin for this day
    SELECT id, points_earned INTO v_existing_checkin_id, v_existing_points
    FROM sz_checkins 
    WHERE streak_id = p_streak_id 
    AND user_id = v_user_id 
    AND day_number = p_day_number
    ORDER BY created_at DESC
    LIMIT 1;
    
    -- Calculate points from completed habits
    SELECT COALESCE(SUM(h.points), 0)
    INTO v_points
    FROM sz_habits h
    WHERE h.id = ANY(p_completed_habit_ids);

    IF v_existing_checkin_id IS NOT NULL THEN
        -- Update existing checkin instead of creating new one
        UPDATE sz_checkins
        SET 
            completed_habit_ids = p_completed_habit_ids,
            points_earned = v_points,
            note = COALESCE(p_note, note),
            photo_url = COALESCE(p_photo_url, photo_url),
            created_at = now()
        WHERE id = v_existing_checkin_id;
        
        -- Update user's total points by removing old points and adding new ones
        UPDATE sz_streak_members AS sm
        SET total_points = sm.total_points - v_existing_points + v_points
        WHERE sm.streak_id = p_streak_id AND sm.user_id = v_user_id
        RETURNING sm.current_streak, sm.total_points INTO v_current_streak, v_total_points;
    ELSE
        -- Create new checkin record
        INSERT INTO sz_checkins (
            streak_id,
            user_id,
            day_number,
            completed_habit_ids,
            points_earned,
            note,
            photo_url
        ) VALUES (
            p_streak_id,
            v_user_id,
            p_day_number,
            p_completed_habit_ids,
            v_points,
            p_note,
            p_photo_url
        );

        -- Update user's points and streak
        UPDATE sz_streak_members AS sm
        SET 
            total_points = sm.total_points + v_points,
            current_streak = sm.current_streak + 1
        WHERE sm.streak_id = p_streak_id AND sm.user_id = v_user_id
        RETURNING sm.current_streak, sm.total_points INTO v_current_streak, v_total_points;
    END IF;

    RETURN QUERY
    SELECT v_points as points_earned, v_current_streak as current_streak, v_total_points as total_points;
END;
$function$;

-- Fix initial lives for Hard Plus mode - users should start with 0 lives, not 3
-- Update the sz_create_streak and sz_join_streak functions to give 0 lives for hard plus modes
CREATE OR REPLACE FUNCTION public.sz_create_streak(p_name text, p_mode text, p_start_date date, p_duration_days integer DEFAULT 75)
 RETURNS TABLE(streak_id uuid, streak_code text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_streak_id UUID;
    v_streak_code TEXT;
    v_user_id UUID;
    v_initial_lives INTEGER;
BEGIN
    -- Get current user ID
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Determine initial lives based on mode
    IF p_mode LIKE '%_plus' THEN
        v_initial_lives := 0; -- Hard Plus modes start with 0 lives, must earn them
    ELSE
        v_initial_lives := 3; -- Regular modes start with 3 lives
    END IF;

    -- Generate streak ID and code
    v_streak_id := gen_random_uuid();
    v_streak_code := public.sz_generate_streak_code();

    -- Create the streak
    INSERT INTO public.sz_streaks (id, name, code, mode, start_date, duration_days, created_by)
    VALUES (v_streak_id, p_name, v_streak_code, p_mode, p_start_date, p_duration_days, v_user_id);

    -- Add creator as admin member
    INSERT INTO public.sz_streak_members (streak_id, user_id, role, lives_remaining)
    VALUES (v_streak_id, v_user_id, 'admin', v_initial_lives);

    -- Auto-assign template habits if it's a template mode
    IF p_mode IN ('75_hard', '75_hard_plus', '75_custom') THEN
        INSERT INTO public.sz_user_habits (streak_id, user_id, habit_id)
        SELECT v_streak_id, v_user_id, h.id
        FROM public.sz_habits h
        WHERE h.template_set = p_mode;
    END IF;

    -- Return the created streak
    RETURN QUERY
    SELECT v_streak_id as streak_id, v_streak_code as streak_code;
END;
$function$;

CREATE OR REPLACE FUNCTION public.sz_join_streak(p_code text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_streak_id UUID;
    v_user_id UUID;
    v_mode TEXT;
    v_initial_lives INTEGER;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Get streak ID and mode
    SELECT id, mode INTO v_streak_id, v_mode
    FROM public.sz_streaks 
    WHERE code = p_code AND is_active = true;
    
    IF v_streak_id IS NULL THEN
        RAISE EXCEPTION 'Invalid or inactive streak code';
    END IF;
    
    -- Check if already a member
    IF EXISTS(
        SELECT 1 FROM public.sz_streak_members 
        WHERE streak_id = v_streak_id AND user_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'User is already a member of this streak';
    END IF;
    
    -- Determine initial lives based on mode
    IF v_mode LIKE '%_plus' THEN
        v_initial_lives := 0; -- Hard Plus modes start with 0 lives, must earn them
    ELSE
        v_initial_lives := 3; -- Regular modes start with 3 lives
    END IF;
    
    -- Add user to streak
    INSERT INTO public.sz_streak_members (streak_id, user_id, role, lives_remaining) 
    VALUES (v_streak_id, v_user_id, 'member', v_initial_lives);
    
    -- Auto-assign template habits if it's a template mode
    IF v_mode IN ('75_hard', '75_hard_plus', '75_custom') THEN
        INSERT INTO public.sz_user_habits (streak_id, user_id, habit_id)
        SELECT v_streak_id, v_user_id, h.id
        FROM public.sz_habits h
        WHERE h.template_set = v_mode;
    END IF;
    
    RETURN v_streak_id;
END;
$function$;