-- Fix streak deletion to properly clean up all related data (SAFE VERSION)
-- This migration adds proper foreign key constraints and cleanup functions
-- Run cleanup_orphaned_data.sql FIRST to remove existing orphaned data

-- 1. Check if foreign key constraints already exist and drop them if they do
DO $$
BEGIN
    -- Drop existing constraints if they exist
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE constraint_name = 'fk_streak_members_streak_id' 
               AND table_name = 'sz_streak_members') THEN
        ALTER TABLE public.sz_streak_members DROP CONSTRAINT fk_streak_members_streak_id;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE constraint_name = 'fk_user_habits_streak_id' 
               AND table_name = 'sz_user_habits') THEN
        ALTER TABLE public.sz_user_habits DROP CONSTRAINT fk_user_habits_streak_id;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE constraint_name = 'fk_checkins_streak_id' 
               AND table_name = 'sz_checkins') THEN
        ALTER TABLE public.sz_checkins DROP CONSTRAINT fk_checkins_streak_id;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE constraint_name = 'fk_posts_streak_id' 
               AND table_name = 'sz_posts') THEN
        ALTER TABLE public.sz_posts DROP CONSTRAINT fk_posts_streak_id;
    END IF;
END $$;

-- 2. Add foreign key constraints with CASCADE DELETE to related tables
ALTER TABLE public.sz_streak_members 
ADD CONSTRAINT fk_streak_members_streak_id 
FOREIGN KEY (streak_id) REFERENCES public.sz_streaks(id) ON DELETE CASCADE;

ALTER TABLE public.sz_user_habits 
ADD CONSTRAINT fk_user_habits_streak_id 
FOREIGN KEY (streak_id) REFERENCES public.sz_streaks(id) ON DELETE CASCADE;

ALTER TABLE public.sz_checkins 
ADD CONSTRAINT fk_checkins_streak_id 
FOREIGN KEY (streak_id) REFERENCES public.sz_streaks(id) ON DELETE CASCADE;

ALTER TABLE public.sz_posts 
ADD CONSTRAINT fk_posts_streak_id 
FOREIGN KEY (streak_id) REFERENCES public.sz_streaks(id) ON DELETE CASCADE;

-- 3. Create a function to safely delete a streak with proper cleanup
CREATE OR REPLACE FUNCTION public.sz_delete_streak_safely(p_streak_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_streak_exists BOOLEAN;
    v_user_id UUID;
    v_is_creator BOOLEAN := FALSE;
    v_is_admin BOOLEAN := FALSE;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User must be authenticated to delete streaks';
    END IF;
    
    -- Check if streak exists
    SELECT EXISTS(SELECT 1 FROM sz_streaks WHERE id = p_streak_id) INTO v_streak_exists;
    IF NOT v_streak_exists THEN
        RAISE EXCEPTION 'Streak not found';
    END IF;
    
    -- Check if user is creator or admin
    SELECT EXISTS(
        SELECT 1 FROM sz_streaks 
        WHERE id = p_streak_id AND created_by = v_user_id
    ) INTO v_is_creator;
    
    SELECT EXISTS(
        SELECT 1 FROM sz_streak_members 
        WHERE streak_id = p_streak_id 
        AND user_id = v_user_id 
        AND role = 'admin'
        AND status = 'active'
    ) INTO v_is_admin;
    
    IF NOT (v_is_creator OR v_is_admin) THEN
        RAISE EXCEPTION 'Only streak creators and admins can delete streaks';
    END IF;
    
    -- Delete the streak (this will cascade to related tables due to foreign keys)
    DELETE FROM sz_streaks WHERE id = p_streak_id;
    
    -- Return success
    RETURN TRUE;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error and re-raise
        RAISE EXCEPTION 'Failed to delete streak: %', SQLERRM;
END;
$$;

-- 4. Create a function to get streak deletion summary (for confirmation dialogs)
CREATE OR REPLACE FUNCTION public.sz_get_streak_deletion_summary(p_streak_id UUID)
RETURNS TABLE(
    streak_name TEXT,
    member_count BIGINT,
    habit_count BIGINT,
    checkin_count BIGINT,
    post_count BIGINT,
    hearts_transaction_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.name as streak_name,
        COUNT(DISTINCT sm.id) as member_count,
        COUNT(DISTINCT uh.id) as habit_count,
        COUNT(DISTINCT c.id) as checkin_count,
        COUNT(DISTINCT p.id) as post_count,
        COUNT(DISTINCT ht.id) as hearts_transaction_count
    FROM sz_streaks s
    LEFT JOIN sz_streak_members sm ON sm.streak_id = s.id
    LEFT JOIN sz_user_habits uh ON uh.streak_id = s.id
    LEFT JOIN sz_checkins c ON c.streak_id = s.id
    LEFT JOIN sz_posts p ON p.streak_id = s.id
    LEFT JOIN sz_hearts_transactions ht ON ht.streak_id = s.id
    WHERE s.id = p_streak_id
    GROUP BY s.id, s.name;
END;
$$;

-- 5. Grant execute permissions
GRANT EXECUTE ON FUNCTION public.sz_delete_streak_safely(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.sz_get_streak_deletion_summary(UUID) TO authenticated;

-- 6. Verify the constraints were added successfully
SELECT 'FOREIGN KEY CONSTRAINTS VERIFICATION' as section;

SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
    AND tc.table_name IN ('sz_streak_members', 'sz_user_habits', 'sz_checkins', 'sz_posts')
    AND tc.constraint_name LIKE 'fk_%_streak_id'
ORDER BY tc.table_name;
