-- Fix sz_create_streak to properly set template_id
CREATE OR REPLACE FUNCTION public.sz_create_streak(p_name text, p_mode text, p_start_date date, p_duration_days integer default 75)
RETURNS TABLE(streak_id uuid, streak_code text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_streak_id uuid;
    v_streak_code text;
    v_user_id uuid;
    v_initial_lives integer;
    v_template_id uuid;
    v_template_key text;
BEGIN
    v_user_id := auth.uid();
    if v_user_id is null then
        raise exception 'User not authenticated';
    end if;

    if p_mode like '%_plus' then
        v_initial_lives := 0;
    else
        v_initial_lives := 3;
    end if;

    -- Resolve template by key (mode may be '75 hard' or '75_hard')
    v_template_key := lower(replace(p_mode, ' ', '_'));
    select id into v_template_id from public.sz_templates where key = v_template_key;

    v_streak_id := gen_random_uuid();
    v_streak_code := public.sz_generate_streak_code();

    -- Insert streak with template_id
    insert into public.sz_streaks (id, name, code, mode, start_date, duration_days, created_by, template_id)
    values (v_streak_id, p_name, v_streak_code, p_mode, p_start_date, p_duration_days, v_user_id, v_template_id);

    insert into public.sz_streak_members (streak_id, user_id, role, lives_remaining)
    values (v_streak_id, v_user_id, 'admin', v_initial_lives);

    -- Assign core habits from template if present, else fallback to legacy behavior
    if v_template_id is not null then
        insert into public.sz_user_habits (streak_id, user_id, habit_id)
        select v_streak_id, v_user_id, th.habit_id
        from public.sz_template_habits th
        where th.template_id = v_template_id and th.is_core = true;
    else
        -- Fallback: legacy template_set
        insert into public.sz_user_habits (streak_id, user_id, habit_id)
        select v_streak_id, v_user_id, h.id
        from public.sz_habits h
        where h.template_set = case when p_mode = '75_hard_plus' then '75_hard' else p_mode end;
    end if;

    return query select v_streak_id, v_streak_code;
END;
$function$;
