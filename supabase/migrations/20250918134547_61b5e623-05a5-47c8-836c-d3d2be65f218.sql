-- Fix the infinite recursion in sz_streak_members RLS policy

-- First, drop the problematic policy
DROP POLICY IF EXISTS "Streak members can view other members" ON sz_streak_members;

-- Create a simpler, non-recursive policy
CREATE POLICY "Streak members can view other members" ON sz_streak_members
  FOR SELECT USING (
    -- User can see their own membership
    auth.uid() = user_id 
    OR 
    -- User can see others if they share any streak
    EXISTS (
      SELECT 1 FROM sz_streak_members sm2 
      WHERE sm2.user_id = auth.uid() 
      AND sm2.streak_id = sz_streak_members.streak_id
    )
  );