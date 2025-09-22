-- Check the actual structure of sz_habits table
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'sz_habits' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Also check what data exists in the habits table
SELECT * FROM sz_habits LIMIT 5;
