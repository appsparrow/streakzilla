-- Check RLS policies for sz_streak_members table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'sz_streak_members' 
AND schemaname = 'public';

-- Check if RLS is enabled on the table
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'sz_streak_members' 
AND schemaname = 'public';
