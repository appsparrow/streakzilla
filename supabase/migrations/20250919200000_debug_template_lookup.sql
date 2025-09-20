-- Debug function to check template lookup
CREATE OR REPLACE FUNCTION public.debug_template_lookup(p_mode text)
RETURNS TABLE(template_key text, template_id uuid, template_name text, core_habits_count bigint)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_template_key TEXT;
    v_template_id UUID;
    v_template_name TEXT;
    v_core_count BIGINT;
BEGIN
    -- Same logic as sz_create_streak
    v_template_key := lower(replace(p_mode, ' ', '_'));
    
    SELECT id, name INTO v_template_id, v_template_name 
    FROM public.sz_templates 
    WHERE key = v_template_key;
    
    IF v_template_id IS NOT NULL THEN
        SELECT COUNT(*) INTO v_core_count
        FROM public.sz_template_habits th
        WHERE th.template_id = v_template_id AND th.is_core = true;
    ELSE
        v_core_count := 0;
    END IF;
    
    RETURN QUERY
    SELECT v_template_key, v_template_id, v_template_name, v_core_count;
END;
$function$;
