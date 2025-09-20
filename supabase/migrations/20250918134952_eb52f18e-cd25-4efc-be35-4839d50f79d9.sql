-- Fix all RLS policies causing infinite recursion in sz_streak_members

-- Drop all existing policies for sz_streak_members
DROP POLICY IF EXISTS "Users can view their memberships" ON sz_streak_members;
DROP POLICY IF EXISTS "Users can join streaks" ON sz_streak_members;
DROP POLICY IF EXISTS "Users can update their own membership" ON sz_streak_members;
DROP POLICY IF EXISTS "Streak members can view other members" ON sz_streak_members;

-- Create new simple, non-recursive policies
CREATE POLICY "sz_streak_members_select_own" ON sz_streak_members
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "sz_streak_members_insert_own" ON sz_streak_members
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "sz_streak_members_update_own" ON sz_streak_members
  FOR UPDATE USING (auth.uid() = user_id);

-- Allow users to view other members of streaks they belong to
-- Create a security definer function to check membership
CREATE OR REPLACE FUNCTION public.user_is_streak_member(p_streak_id uuid)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM sz_streak_members 
    WHERE streak_id = p_streak_id 
    AND user_id = auth.uid()
  );
$$ LANGUAGE SQL SECURITY DEFINER STABLE SET search_path = public;

-- Policy using the security definer function
CREATE POLICY "sz_streak_members_select_shared" ON sz_streak_members
  FOR SELECT USING (
    auth.uid() = user_id OR public.user_is_streak_member(streak_id)
  );