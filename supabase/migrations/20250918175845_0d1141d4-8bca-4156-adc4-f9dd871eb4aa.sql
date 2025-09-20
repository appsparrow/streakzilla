-- Fix streak member status tracking and RLS policies
-- Add status tracking for members (active, left, eliminated)
ALTER TABLE sz_streak_members ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active';
ALTER TABLE sz_streak_members ADD COLUMN IF NOT EXISTS left_at TIMESTAMP WITH TIME ZONE;

-- Update existing members to have active status
UPDATE sz_streak_members SET status = 'active' WHERE status IS NULL;

-- Update members who are out to eliminated status
UPDATE sz_streak_members SET status = 'eliminated' WHERE is_out = true;

-- Create function to handle leaving streak (soft delete)
CREATE OR REPLACE FUNCTION sz_leave_streak(p_streak_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Update member status to 'left' instead of deleting
    UPDATE sz_streak_members 
    SET status = 'left', left_at = now()
    WHERE streak_id = p_streak_id AND user_id = auth.uid();
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'User is not a member of this streak';
    END IF;
END;
$$;

-- Fix the DELETE RLS policy for sz_streaks to handle actual deletion
DROP POLICY IF EXISTS "Creators and admins can delete streaks" ON sz_streaks;
CREATE POLICY "Creators and admins can delete streaks" ON sz_streaks
FOR DELETE USING (
    (auth.uid() = created_by) OR 
    (EXISTS (
        SELECT 1 FROM sz_streak_members sm
        WHERE sm.streak_id = sz_streaks.id 
        AND sm.user_id = auth.uid() 
        AND sm.role = 'admin'
        AND sm.status = 'active'
    ))
);

-- Also ensure UPDATE policy works for soft deletion (is_active = false)
DROP POLICY IF EXISTS "Creators and admins can update streaks" ON sz_streaks;
CREATE POLICY "Creators and admins can update streaks" ON sz_streaks
FOR UPDATE USING (
    (auth.uid() = created_by) OR 
    (EXISTS (
        SELECT 1 FROM sz_streak_members sm
        WHERE sm.streak_id = sz_streaks.id 
        AND sm.user_id = auth.uid() 
        AND sm.role = 'admin'
        AND sm.status = 'active'
    ))
);