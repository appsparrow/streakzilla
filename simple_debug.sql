-- Simple debug to check what's in the database
SELECT 
    'STREAK MEMBERS COUNT' as check_type,
    COUNT(*) as count
FROM sz_streak_members 
WHERE streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2'::uuid;

SELECT 
    'STREAK MEMBERS DATA' as check_type,
    user_id,
    role,
    status
FROM sz_streak_members 
WHERE streak_id = '55e675ae-6937-4ece-a5b6-156115a797d2'::uuid;
