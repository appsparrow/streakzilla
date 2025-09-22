-- Fix RLS policies to allow super admins to manage streak members
-- This script adds policies that allow super admins to insert, update, and delete streak members

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Super admins can manage streak members" ON sz_streak_members;
DROP POLICY IF EXISTS "Super admins can insert streak members" ON sz_streak_members;
DROP POLICY IF EXISTS "Super admins can update streak members" ON sz_streak_members;
DROP POLICY IF EXISTS "Super admins can delete streak members" ON sz_streak_members;

-- Create policies for super admins to manage streak members
CREATE POLICY "Super admins can insert streak members" ON sz_streak_members
    FOR INSERT 
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM sz_user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'super_admin' 
            AND is_active = true
        )
    );

CREATE POLICY "Super admins can update streak members" ON sz_streak_members
    FOR UPDATE 
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM sz_user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'super_admin' 
            AND is_active = true
        )
    );

CREATE POLICY "Super admins can delete streak members" ON sz_streak_members
    FOR DELETE 
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM sz_user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'super_admin' 
            AND is_active = true
        )
    );

-- Also add policies for sz_user_habits table
DROP POLICY IF EXISTS "Super admins can manage user habits" ON sz_user_habits;
DROP POLICY IF EXISTS "Super admins can insert user habits" ON sz_user_habits;
DROP POLICY IF EXISTS "Super admins can update user habits" ON sz_user_habits;
DROP POLICY IF EXISTS "Super admins can delete user habits" ON sz_user_habits;

CREATE POLICY "Super admins can insert user habits" ON sz_user_habits
    FOR INSERT 
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM sz_user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'super_admin' 
            AND is_active = true
        )
    );

CREATE POLICY "Super admins can update user habits" ON sz_user_habits
    FOR UPDATE 
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM sz_user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'super_admin' 
            AND is_active = true
        )
    );

CREATE POLICY "Super admins can delete user habits" ON sz_user_habits
    FOR DELETE 
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM sz_user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'super_admin' 
            AND is_active = true
        )
    );

-- Also add policies for sz_checkins table
DROP POLICY IF EXISTS "Super admins can manage checkins" ON sz_checkins;
DROP POLICY IF EXISTS "Super admins can insert checkins" ON sz_checkins;
DROP POLICY IF EXISTS "Super admins can update checkins" ON sz_checkins;
DROP POLICY IF EXISTS "Super admins can delete checkins" ON sz_checkins;

CREATE POLICY "Super admins can insert checkins" ON sz_checkins
    FOR INSERT 
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM sz_user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'super_admin' 
            AND is_active = true
        )
    );

CREATE POLICY "Super admins can update checkins" ON sz_checkins
    FOR UPDATE 
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM sz_user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'super_admin' 
            AND is_active = true
        )
    );

CREATE POLICY "Super admins can delete checkins" ON sz_checkins
    FOR DELETE 
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM sz_user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'super_admin' 
            AND is_active = true
        )
    );

-- Verify the policies were created
SELECT 
    'POLICIES CREATED' as status,
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE tablename IN ('sz_streak_members', 'sz_user_habits', 'sz_checkins')
AND policyname LIKE '%Super admins%'
ORDER BY tablename, cmd;
