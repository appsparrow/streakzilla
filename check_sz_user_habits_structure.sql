-- =====================================================
-- CHECK SZ_USER_HABITS TABLE STRUCTURE
-- =====================================================

-- Check the current structure of sz_user_habits table
SELECT 
    'SZ_USER_HABITS TABLE STRUCTURE' as section,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'sz_user_habits' 
AND table_schema = 'public'
ORDER BY ordinal_position;
