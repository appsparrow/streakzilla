-- Check for Orphaned Records After Streak Deletion
-- Streak ID: 726a9c03-6fe2-4a00-982c-0b799032b02f

-- =====================================================
-- 1. CHECK IF STREAK STILL EXISTS
-- =====================================================
SELECT 
    'STREAK_EXISTS_CHECK' as section,
    CASE 
        WHEN COUNT(*) > 0 THEN 'STREAK STILL EXISTS - DELETION FAILED'
        ELSE 'STREAK DELETED SUCCESSFULLY'
    END as status,
    COUNT(*) as count
FROM sz_streaks 
WHERE id = '726a9c03-6fe2-4a00-982c-0b799032b02f';

-- =====================================================
-- 2. CHECK FOR ORPHANED STREAK MEMBERS
-- =====================================================
SELECT 
    'ORPHANED_STREAK_MEMBERS' as section,
    COUNT(*) as orphaned_count,
    'Members referencing deleted streak' as description
FROM sz_streak_members sm 
WHERE sm.streak_id = '726a9c03-6fe2-4a00-982c-0b799032b02f'
  AND NOT EXISTS (
    SELECT 1 FROM sz_streaks s WHERE s.id = sm.streak_id
  );

-- Show details of orphaned members
SELECT 
    'ORPHANED_MEMBER_DETAILS' as section,
    sm.id,
    sm.user_id,
    sm.role,
    sm.joined_at,
    sm.streak_id
FROM sz_streak_members sm 
WHERE sm.streak_id = '726a9c03-6fe2-4a00-982c-0b799032b02f'
  AND NOT EXISTS (
    SELECT 1 FROM sz_streaks s WHERE s.id = sm.streak_id
  );

-- =====================================================
-- 3. CHECK FOR ORPHANED USER HABITS
-- =====================================================
SELECT 
    'ORPHANED_USER_HABITS' as section,
    COUNT(*) as orphaned_count,
    'Habit selections referencing deleted streak' as description
FROM sz_user_habits uh 
WHERE uh.streak_id = '726a9c03-6fe2-4a00-982c-0b799032b02f'
  AND NOT EXISTS (
    SELECT 1 FROM sz_streaks s WHERE s.id = uh.streak_id
  );

-- Show details of orphaned user habits
SELECT 
    'ORPHANED_USER_HABIT_DETAILS' as section,
    uh.id,
    uh.user_id,
    uh.habit_id,
    uh.streak_id,
    uh.created_at
FROM sz_user_habits uh 
WHERE uh.streak_id = '726a9c03-6fe2-4a00-982c-0b799032b02f'
  AND NOT EXISTS (
    SELECT 1 FROM sz_streaks s WHERE s.id = uh.streak_id
  );

-- =====================================================
-- 4. CHECK FOR ORPHANED CHECKINS
-- =====================================================
SELECT 
    'ORPHANED_CHECKINS' as section,
    COUNT(*) as orphaned_count,
    'Check-ins referencing deleted streak' as description
FROM sz_checkins c 
WHERE c.streak_id = '726a9c03-6fe2-4a00-982c-0b799032b02f'
  AND NOT EXISTS (
    SELECT 1 FROM sz_streaks s WHERE s.id = c.streak_id
  );

-- Show details of orphaned checkins
SELECT 
    'ORPHANED_CHECKIN_DETAILS' as section,
    c.id,
    c.user_id,
    c.streak_id,
    c.day_number,
    c.completed_habit_ids,
    c.points_earned,
    c.note,
    c.created_at
FROM sz_checkins c 
WHERE c.streak_id = '726a9c03-6fe2-4a00-982c-0b799032b02f'
  AND NOT EXISTS (
    SELECT 1 FROM sz_streaks s WHERE s.id = c.streak_id
  );

-- =====================================================
-- 5. CHECK FOR ORPHANED POSTS
-- =====================================================
SELECT 
    'ORPHANED_POSTS' as section,
    COUNT(*) as orphaned_count,
    'Progress photos referencing deleted streak' as description
FROM sz_posts p 
WHERE p.streak_id = '726a9c03-6fe2-4a00-982c-0b799032b02f'
  AND NOT EXISTS (
    SELECT 1 FROM sz_streaks s WHERE s.id = p.streak_id
  );

-- Show details of orphaned posts
SELECT 
    'ORPHANED_POST_DETAILS' as section,
    p.id,
    p.user_id,
    p.streak_id,
    p.day_number,
    p.photo_url,
    p.caption,
    p.created_at
FROM sz_posts p 
WHERE p.streak_id = '726a9c03-6fe2-4a00-982c-0b799032b02f'
  AND NOT EXISTS (
    SELECT 1 FROM sz_streaks s WHERE s.id = p.streak_id
  );

-- =====================================================
-- 6. CHECK FOR ORPHANED HEARTS TRANSACTIONS
-- =====================================================
SELECT 
    'ORPHANED_HEARTS_TRANSACTIONS' as section,
    COUNT(*) as orphaned_count,
    'Heart transactions referencing deleted streak' as description
FROM sz_hearts_transactions ht 
WHERE ht.streak_id = '726a9c03-6fe2-4a00-982c-0b799032b02f'
  AND NOT EXISTS (
    SELECT 1 FROM sz_streaks s WHERE s.id = ht.streak_id
  );

-- Show details of orphaned hearts transactions
SELECT 
    'ORPHANED_HEARTS_DETAILS' as section,
    ht.id,
    ht.from_user_id,
    ht.to_user_id,
    ht.streak_id,
    ht.hearts_amount,
    ht.transaction_type,
    ht.day_number,
    ht.note,
    ht.created_at
FROM sz_hearts_transactions ht 
WHERE ht.streak_id = '726a9c03-6fe2-4a00-982c-0b799032b02f'
  AND NOT EXISTS (
    SELECT 1 FROM sz_streaks s WHERE s.id = ht.streak_id
  );

-- =====================================================
-- 7. SUMMARY REPORT
-- =====================================================
SELECT 
    'SUMMARY_REPORT' as section,
    'Orphaned Records Summary' as title,
    (
        SELECT COUNT(*) FROM sz_streak_members sm 
        WHERE sm.streak_id = '726a9c03-6fe2-4a00-982c-0b799032b02f'
          AND NOT EXISTS (SELECT 1 FROM sz_streaks s WHERE s.id = sm.streak_id)
    ) as orphaned_members,
    (
        SELECT COUNT(*) FROM sz_user_habits uh 
        WHERE uh.streak_id = '726a9c03-6fe2-4a00-982c-0b799032b02f'
          AND NOT EXISTS (SELECT 1 FROM sz_streaks s WHERE s.id = uh.streak_id)
    ) as orphaned_user_habits,
    (
        SELECT COUNT(*) FROM sz_checkins c 
        WHERE c.streak_id = '726a9c03-6fe2-4a00-982c-0b799032b02f'
          AND NOT EXISTS (SELECT 1 FROM sz_streaks s WHERE s.id = c.streak_id)
    ) as orphaned_checkins,
    (
        SELECT COUNT(*) FROM sz_posts p 
        WHERE p.streak_id = '726a9c03-6fe2-4a00-982c-0b799032b02f'
          AND NOT EXISTS (SELECT 1 FROM sz_streaks s WHERE s.id = p.streak_id)
    ) as orphaned_posts,
    (
        SELECT COUNT(*) FROM sz_hearts_transactions ht 
        WHERE ht.streak_id = '726a9c03-6fe2-4a00-982c-0b799032b02f'
          AND NOT EXISTS (SELECT 1 FROM sz_streaks s WHERE s.id = ht.streak_id)
    ) as orphaned_hearts_transactions;

-- =====================================================
-- 8. CLEANUP RECOMMENDATION
-- =====================================================
SELECT 
    'CLEANUP_RECOMMENDATION' as section,
    CASE 
        WHEN (
            SELECT COUNT(*) FROM sz_streak_members sm 
            WHERE sm.streak_id = '726a9c03-6fe2-4a00-982c-0b799032b02f'
              AND NOT EXISTS (SELECT 1 FROM sz_streaks s WHERE s.id = sm.streak_id)
        ) > 0 
        THEN 'ORPHANED DATA FOUND - RUN CLEANUP SCRIPT'
        ELSE 'NO ORPHANED DATA - DELETION SUCCESSFUL'
    END as recommendation;
