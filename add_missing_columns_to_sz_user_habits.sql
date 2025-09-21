-- =====================================================
-- ADD MISSING COLUMNS TO SZ_USER_HABITS
-- =====================================================
-- Based on the actual Supabase schema, sz_user_habits only has:
-- id, streak_id, user_id, habit_id, created_at
-- We need to add: is_core, points_override, updated_at
-- =====================================================

-- Add is_core column
ALTER TABLE public.sz_user_habits 
ADD COLUMN is_core BOOLEAN DEFAULT false;

-- Add points_override column
ALTER TABLE public.sz_user_habits 
ADD COLUMN points_override INTEGER DEFAULT NULL;

-- Add updated_at column
ALTER TABLE public.sz_user_habits 
ADD COLUMN updated_at TIMESTAMPTZ DEFAULT now();

-- Verify the columns were added
SELECT 
    'SZ_USER_HABITS UPDATED STRUCTURE' as section,
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
    'COLUMNS ADDED SUCCESSFULLY' as section,
    'is_core (BOOLEAN)' as column1,
    'points_override (INTEGER)' as column2,
    'updated_at (TIMESTAMPTZ)' as column3,
    'Ready to run the streak update script!' as next_step;
