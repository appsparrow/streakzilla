-- Check what columns exist in sz_streaks table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'sz_streaks' 
AND table_schema = 'public'
ORDER BY ordinal_position;
