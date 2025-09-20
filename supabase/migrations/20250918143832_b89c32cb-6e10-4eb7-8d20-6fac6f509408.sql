-- Create function to save user habits
CREATE OR REPLACE FUNCTION public.sz_save_user_habits(p_streak_id uuid, p_habit_ids uuid[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Check if user is a member of the streak
    IF NOT EXISTS(
        SELECT 1 FROM sz_streak_members 
        WHERE streak_id = p_streak_id AND user_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'User is not a member of this streak';
    END IF;

    -- Delete existing user habits for this streak
    DELETE FROM sz_user_habits 
    WHERE streak_id = p_streak_id AND user_id = v_user_id;

    -- Insert new user habits
    INSERT INTO sz_user_habits (streak_id, user_id, habit_id)
    SELECT p_streak_id, v_user_id, unnest(p_habit_ids);
END;
$function$;