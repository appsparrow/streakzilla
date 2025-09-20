-- Fix infinite recursion in sz_streak_members policies
DROP POLICY IF EXISTS "Streak members can view other members" ON public.sz_streak_members;

-- Create a simpler policy that doesn't cause recursion
CREATE POLICY "Streak members can view other members" 
ON public.sz_streak_members 
FOR SELECT 
USING (
  streak_id IN (
    SELECT sm.streak_id 
    FROM public.sz_streak_members sm 
    WHERE sm.user_id = auth.uid()
  )
);

-- Fix the ambiguous code reference in sz_generate_streak_code
CREATE OR REPLACE FUNCTION public.sz_generate_streak_code()
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_code TEXT;
    v_exists_check INTEGER;
BEGIN
    LOOP
        -- Generate a 6-character alphanumeric code
        v_code := UPPER(
            SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 3) || 
            LPAD(FLOOR(RANDOM() * 1000)::TEXT, 3, '0')
        );
        
        -- Check if this code already exists (fully qualify table reference)
        SELECT COUNT(*) INTO v_exists_check 
        FROM public.sz_streaks s
        WHERE s.code = v_code;
        
        -- If code doesn't exist, we can use it
        IF v_exists_check = 0 THEN
            EXIT;
        END IF;
    END LOOP;
    
    RETURN v_code;
END;
$function$