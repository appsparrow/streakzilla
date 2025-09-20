-- Clean up orphaned data before adding foreign key constraints
-- This script removes all orphaned records that reference non-existent streaks

-- 1. Find and report orphaned data
SELECT 'ORPHANED DATA REPORT' as section;

-- Check for orphaned streak members
SELECT 
    'Orphaned Streak Members' as table_name,
    COUNT(*) as orphaned_count
FROM sz_streak_members sm
WHERE NOT EXISTS (
    SELECT 1 FROM sz_streaks s WHERE s.id = sm.streak_id
);

-- Check for orphaned user habits
SELECT 
    'Orphaned User Habits' as table_name,
    COUNT(*) as orphaned_count
FROM sz_user_habits uh
WHERE NOT EXISTS (
    SELECT 1 FROM sz_streaks s WHERE s.id = uh.streak_id
);

-- Check for orphaned checkins
SELECT 
    'Orphaned Checkins' as table_name,
    COUNT(*) as orphaned_count
FROM sz_checkins c
WHERE NOT EXISTS (
    SELECT 1 FROM sz_streaks s WHERE s.id = c.streak_id
);

-- Check for orphaned posts
SELECT 
    'Orphaned Posts' as table_name,
    COUNT(*) as orphaned_count
FROM sz_posts p
WHERE NOT EXISTS (
    SELECT 1 FROM sz_streaks s WHERE s.id = p.streak_id
);

-- Check for orphaned hearts transactions
SELECT 
    'Orphaned Hearts Transactions' as table_name,
    COUNT(*) as orphaned_count
FROM sz_hearts_transactions ht
WHERE NOT EXISTS (
    SELECT 1 FROM sz_streaks s WHERE s.id = ht.streak_id
);

-- 2. Clean up orphaned data
SELECT 'CLEANING UP ORPHANED DATA' as section;

-- Delete orphaned streak members
DELETE FROM sz_streak_members 
WHERE NOT EXISTS (
    SELECT 1 FROM sz_streaks s WHERE s.id = sz_streak_members.streak_id
);

-- Delete orphaned user habits
DELETE FROM sz_user_habits 
WHERE NOT EXISTS (
    SELECT 1 FROM sz_streaks s WHERE s.id = sz_user_habits.streak_id
);

-- Delete orphaned checkins
DELETE FROM sz_checkins 
WHERE NOT EXISTS (
    SELECT 1 FROM sz_streaks s WHERE s.id = sz_checkins.streak_id
);

-- Delete orphaned posts
DELETE FROM sz_posts 
WHERE NOT EXISTS (
    SELECT 1 FROM sz_streaks s WHERE s.id = sz_posts.streak_id
);

-- Delete orphaned hearts transactions
DELETE FROM sz_hearts_transactions 
WHERE NOT EXISTS (
    SELECT 1 FROM sz_streaks s WHERE s.id = sz_hearts_transactions.streak_id
);

-- 3. Verify cleanup
SELECT 'CLEANUP VERIFICATION' as section;

-- Check that no orphaned data remains
SELECT 
    'Remaining Orphaned Streak Members' as table_name,
    COUNT(*) as orphaned_count
FROM sz_streak_members sm
WHERE NOT EXISTS (
    SELECT 1 FROM sz_streaks s WHERE s.id = sm.streak_id
);

SELECT 
    'Remaining Orphaned User Habits' as table_name,
    COUNT(*) as orphaned_count
FROM sz_user_habits uh
WHERE NOT EXISTS (
    SELECT 1 FROM sz_streaks s WHERE s.id = uh.streak_id
);

SELECT 
    'Remaining Orphaned Checkins' as table_name,
    COUNT(*) as orphaned_count
FROM sz_checkins c
WHERE NOT EXISTS (
    SELECT 1 FROM sz_streaks s WHERE s.id = c.streak_id
);

SELECT 
    'Remaining Orphaned Posts' as table_name,
    COUNT(*) as orphaned_count
FROM sz_posts p
WHERE NOT EXISTS (
    SELECT 1 FROM sz_streaks s WHERE s.id = p.streak_id
);

SELECT 
    'Remaining Orphaned Hearts Transactions' as table_name,
    COUNT(*) as orphaned_count
FROM sz_hearts_transactions ht
WHERE NOT EXISTS (
    SELECT 1 FROM sz_streaks s WHERE s.id = ht.streak_id
);
