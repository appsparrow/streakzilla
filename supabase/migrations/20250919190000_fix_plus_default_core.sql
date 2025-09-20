-- Align default habit assignment for 75_hard_plus with UI expectations
-- For Hard Plus modes, only the 75_hard core habits should be auto-assigned.
-- This prevents core requirements from showing up under "Bonus" on first check-in.

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
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    IF p_mode LIKE '%_plus' THEN
        v_initial_lives := 0;
    ELSE
        v_initial_lives := 3;
    END IF;

    v_streak_id := gen_random_uuid();
    v_streak_code := public.sz_generate_streak_code();

    INSERT INTO public.sz_streaks (id, name, code, mode, start_date, duration_days, created_by)
    VALUES (v_streak_id, p_name, v_streak_code, p_mode, p_start_date, p_duration_days, v_user_id);

    INSERT INTO public.sz_streak_members (streak_id, user_id, role, lives_remaining)
    VALUES (v_streak_id, v_user_id, 'admin', v_initial_lives);

    -- Auto-assign default/core habits
    IF p_mode IN ('75_hard', '75_hard_plus', '75_custom') THEN
        INSERT INTO public.sz_user_habits (streak_id, user_id, habit_id)
        SELECT v_streak_id, v_user_id, h.id
        FROM public.sz_habits h
        WHERE h.template_set = CASE 
            WHEN p_mode = '75_hard_plus' THEN '75_hard'  -- Only core for plus
            ELSE p_mode
        END;
    END IF;

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

    SELECT id, mode INTO v_streak_id, v_mode
    FROM public.sz_streaks 
    WHERE code = p_code AND is_active = true;

    IF v_streak_id IS NULL THEN
        RAISE EXCEPTION 'Invalid or inactive streak code';
    END IF;

    IF EXISTS(
        SELECT 1 FROM public.sz_streak_members 
        WHERE streak_id = v_streak_id AND user_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'User is already a member of this streak';
    END IF;

    IF v_mode LIKE '%_plus' THEN
        v_initial_lives := 0;
    ELSE
        v_initial_lives := 3;
    END IF;

    INSERT INTO public.sz_streak_members (streak_id, user_id, role, lives_remaining) 
    VALUES (v_streak_id, v_user_id, 'member', v_initial_lives);

    -- Auto-assign default/core habits
    IF v_mode IN ('75_hard', '75_hard_plus', '75_custom') THEN
        INSERT INTO public.sz_user_habits (streak_id, user_id, habit_id)
        SELECT v_streak_id, v_user_id, h.id
        FROM public.sz_habits h
        WHERE h.template_set = CASE 
            WHEN v_mode = '75_hard_plus' THEN '75_hard'  -- Only core for plus
            ELSE v_mode
        END;
    END IF;

    RETURN v_streak_id;
END;
$function$;


