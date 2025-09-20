-- Fix security warnings by setting search_path for all new functions

-- Update sz_generate_streak_code function
CREATE OR REPLACE FUNCTION public.sz_generate_streak_code()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    code TEXT;
    exists_check INTEGER;
BEGIN
    LOOP
        -- Generate a 6-character alphanumeric code
        code := UPPER(
            SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 3) || 
            LPAD(FLOOR(RANDOM() * 1000)::TEXT, 3, '0')
        );
        
        -- Check if this code already exists
        SELECT COUNT(*) INTO exists_check 
        FROM sz_streaks 
        WHERE code = code;
        
        -- If code doesn't exist, we can use it
        IF exists_check = 0 THEN
            EXIT;
        END IF;
    END LOOP;
    
    RETURN code;
END;
$$;

-- Update sz_create_streak function
CREATE OR REPLACE FUNCTION public.sz_create_streak(
    p_name TEXT,
    p_mode TEXT,
    p_start_date DATE,
    p_duration_days INTEGER DEFAULT 75
)
RETURNS TABLE(streak_id UUID, streak_code TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_streak_id UUID;
    v_streak_code TEXT;
    v_user_id UUID;
BEGIN
    -- Get current user ID
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Generate streak ID and code
    v_streak_id := gen_random_uuid();
    v_streak_code := public.sz_generate_streak_code();

    -- Create the streak
    INSERT INTO public.sz_streaks (id, name, code, mode, start_date, duration_days, created_by)
    VALUES (v_streak_id, p_name, v_streak_code, p_mode, p_start_date, p_duration_days, v_user_id);

    -- Add creator as admin member
    INSERT INTO public.sz_streak_members (streak_id, user_id, role, lives_remaining)
    VALUES (v_streak_id, v_user_id, 'admin', 3);

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
$$;

-- Update sz_join_streak function
CREATE OR REPLACE FUNCTION public.sz_join_streak(p_code TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_streak_id UUID;
    v_user_id UUID;
    v_mode TEXT;
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
    
    -- Add user to streak
    INSERT INTO public.sz_streak_members (streak_id, user_id, role, lives_remaining) 
    VALUES (v_streak_id, v_user_id, 'member', 3);
    
    -- Auto-assign template habits if it's a template mode
    IF v_mode IN ('75_hard', '75_hard_plus', '75_custom') THEN
        INSERT INTO public.sz_user_habits (streak_id, user_id, habit_id)
        SELECT v_streak_id, v_user_id, h.id
        FROM public.sz_habits h
        WHERE h.template_set = v_mode;
    END IF;
    
    RETURN v_streak_id;
END;
$$;

-- Update sz_checkin function
CREATE OR REPLACE FUNCTION public.sz_checkin(
    p_streak_id UUID,
    p_day_number INTEGER,
    p_completed_habit_ids UUID[],
    p_note TEXT DEFAULT NULL,
    p_photo_url TEXT DEFAULT NULL
)
RETURNS TABLE(points_earned INTEGER, current_streak INTEGER, total_points INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_points INTEGER := 0;
    v_current_streak INTEGER;
    v_total_points INTEGER;
BEGIN
    v_user_id := auth.uid();
    
    -- Calculate points from completed habits
    SELECT COALESCE(SUM(h.points), 0)
    INTO v_points
    FROM sz_habits h
    WHERE h.id = ANY(p_completed_habit_ids);

    -- Create checkin record
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
    UPDATE sz_streak_members
    SET 
        total_points = total_points + v_points,
        current_streak = current_streak + 1
    WHERE streak_id = p_streak_id AND user_id = v_user_id
    RETURNING current_streak, total_points INTO v_current_streak, v_total_points;

    RETURN QUERY
    SELECT v_points as points_earned, v_current_streak as current_streak, v_total_points as total_points;
END;
$$;