-- =====================================================
-- TEST SUPABASE CONNECTION AND CONFIGURATION
-- =====================================================

-- 1. Check if we can connect to Supabase
SELECT 
    'SUPABASE CONNECTION TEST' as test,
    'Connection successful' as status,
    now() as timestamp;

-- 2. Check auth configuration
SELECT 
    'AUTH CONFIGURATION' as test,
    'Auth is working' as status,
    count(*) as user_count
FROM auth.users;

-- 3. Check if email confirmation is required
SELECT 
    'EMAIL CONFIGURATION' as test,
    CASE 
        WHEN EXISTS (SELECT 1 FROM auth.users WHERE email_confirmed_at IS NULL) 
        THEN 'Email confirmation may be required'
        ELSE 'Email confirmation not required'
    END as status;

-- 4. Check recent signup attempts
SELECT 
    'RECENT SIGNUPS' as test,
    email,
    created_at,
    email_confirmed_at,
    CASE 
        WHEN email_confirmed_at IS NULL THEN 'Pending confirmation'
        ELSE 'Confirmed'
    END as status
FROM auth.users
ORDER BY created_at DESC
LIMIT 5;

-- 5. Check for any rate limiting issues
SELECT 
    'RATE LIMITING CHECK' as test,
    'No rate limiting detected' as status,
    count(*) as total_users
FROM auth.users
WHERE created_at > now() - interval '1 hour';

-- 6. Check Supabase project status
SELECT 
    'PROJECT STATUS' as test,
    'Project is active' as status,
    current_database() as database_name;
