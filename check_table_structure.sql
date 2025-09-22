-- Check the actual structure of sz_streaks table
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'sz_streaks' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Also check what data exists in the source streak
SELECT * FROM sz_streaks 
WHERE id = '55e675ae-6937-4ece-a5b6-156115a797d2'::uuid;
