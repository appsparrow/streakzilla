-- Fix ambiguous column reference in sz_create_streak function
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
BEGIN
    -- Get current user ID
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Generate streak ID and code
    v_streak_id := gen_random_uuid();
    v_streak_code := public.sz_generate_streak_code();

    -- Create the streak (qualify table name to avoid ambiguity)
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
$function$