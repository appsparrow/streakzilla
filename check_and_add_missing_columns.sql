-- =====================================================
-- CHECK AND ADD ONLY MISSING COLUMNS TO SZ_USER_HABITS
-- =====================================================
-- This script checks what columns exist and only adds the missing ones
-- =====================================================

-- Check current structure
SELECT 
    'CURRENT SZ_USER_HABITS STRUCTURE' as section,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'sz_user_habits' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Add points_override column if it doesn't exist
ALTER TABLE public.sz_user_habits 
ADD COLUMN IF NOT EXISTS points_override INTEGER DEFAULT NULL;

-- Add updated_at column if it doesn't exist
ALTER TABLE public.sz_user_habits 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

-- Verify the final structure
SELECT 
    'FINAL SZ_USER_HABITS STRUCTURE' as section,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'sz_user_habits' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Summary
SELECT 
    'COLUMNS CHECK COMPLETE' as section,
    'Only missing columns added (if any)' as message,
    'Ready to run the streak update script!' as next_step;
