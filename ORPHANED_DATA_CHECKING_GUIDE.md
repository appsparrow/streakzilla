# 🔍 Orphaned Data Checking Guide

## 📋 **Purpose**
This guide provides step-by-step instructions for checking orphaned data in the Streakzilla database, particularly after streak deletions.

## 🚨 **When to Check for Orphaned Data**
- **After deleting a streak** manually
- **After bulk streak operations**
- **When experiencing foreign key constraint errors**
- **During database maintenance**
- **Before implementing new cleanup procedures**

## 🛠️ **Quick Check Process**

### **Step 1: Use the Diagnostic Script**
```sql
-- Run the comprehensive orphaned data checker
-- File: check_orphaned_records.sql
```

### **Step 2: Interpret Results**
The script will show you:
- **STREAK_EXISTS_CHECK**: Whether the streak was actually deleted
- **ORPHANED_*_COUNT**: Number of orphaned records in each table
- **ORPHANED_*_DETAILS**: Specific details of orphaned records
- **SUMMARY_REPORT**: Total counts across all tables
- **CLEANUP_RECOMMENDATION**: Next steps

## 📊 **Understanding the Output**

### **Clean Deletion (No Orphaned Data):**
```
STREAK_EXISTS_CHECK: STREAK DELETED SUCCESSFULLY
ORPHANED_STREAK_MEMBERS: 0
ORPHANED_USER_HABITS: 0
ORPHANED_CHECKINS: 0
ORPHANED_POSTS: 0
ORPHANED_HEARTS_TRANSACTIONS: 0
CLEANUP_RECOMMENDATION: NO ORPHANED DATA - DELETION SUCCESSFUL
```

### **Orphaned Data Found:**
```
STREAK_EXISTS_CHECK: STREAK DELETED SUCCESSFULLY
ORPHANED_STREAK_MEMBERS: 3
ORPHANED_USER_HABITS: 5
ORPHANED_CHECKINS: 12
ORPHANED_POSTS: 2
ORPHANED_HEARTS_TRANSACTIONS: 1
CLEANUP_RECOMMENDATION: ORPHANED DATA FOUND - RUN CLEANUP SCRIPT
```

## 🔧 **Manual Check Queries**

### **Check Specific Streak:**
```sql
-- Replace with actual streak ID
SELECT 'ORPHANED_DATA_CHECK' as check_type,
  (SELECT COUNT(*) FROM sz_streak_members WHERE streak_id = 'YOUR_STREAK_ID' 
   AND NOT EXISTS (SELECT 1 FROM sz_streaks WHERE id = 'YOUR_STREAK_ID')) as orphaned_members,
  (SELECT COUNT(*) FROM sz_user_habits WHERE streak_id = 'YOUR_STREAK_ID' 
   AND NOT EXISTS (SELECT 1 FROM sz_streaks WHERE id = 'YOUR_STREAK_ID')) as orphaned_user_habits,
  (SELECT COUNT(*) FROM sz_checkins WHERE streak_id = 'YOUR_STREAK_ID' 
   AND NOT EXISTS (SELECT 1 FROM sz_streaks WHERE id = 'YOUR_STREAK_ID')) as orphaned_checkins,
  (SELECT COUNT(*) FROM sz_posts WHERE streak_id = 'YOUR_STREAK_ID' 
   AND NOT EXISTS (SELECT 1 FROM sz_streaks WHERE id = 'YOUR_STREAK_ID')) as orphaned_posts,
  (SELECT COUNT(*) FROM sz_hearts_transactions WHERE streak_id = 'YOUR_STREAK_ID' 
   AND NOT EXISTS (SELECT 1 FROM sz_streaks WHERE id = 'YOUR_STREAK_ID')) as orphaned_hearts;
```

### **Check All Orphaned Data:**
```sql
-- Find all orphaned records across the entire database
SELECT 'sz_streak_members' as table_name, COUNT(*) as orphaned_count
FROM sz_streak_members sm 
WHERE NOT EXISTS (SELECT 1 FROM sz_streaks s WHERE s.id = sm.streak_id)
UNION ALL
SELECT 'sz_user_habits', COUNT(*)
FROM sz_user_habits uh 
WHERE NOT EXISTS (SELECT 1 FROM sz_streaks s WHERE s.id = uh.streak_id)
UNION ALL
SELECT 'sz_checkins', COUNT(*)
FROM sz_checkins c 
WHERE NOT EXISTS (SELECT 1 FROM sz_streaks s WHERE s.id = c.streak_id)
UNION ALL
SELECT 'sz_posts', COUNT(*)
FROM sz_posts p 
WHERE NOT EXISTS (SELECT 1 FROM sz_streaks s WHERE s.id = p.streak_id)
UNION ALL
SELECT 'sz_hearts_transactions', COUNT(*)
FROM sz_hearts_transactions ht 
WHERE NOT EXISTS (SELECT 1 FROM sz_streaks s WHERE s.id = ht.streak_id);
```

## 🧹 **Cleanup Actions**

### **If Orphaned Data Found:**
1. **Run**: `cleanup_orphaned_data.sql` (removes all orphaned records)
2. **Run**: `fix_streak_deletion_cleanup_safe.sql` (adds proper constraints)
3. **Verify**: Run orphaned data check again to confirm cleanup

### **Prevention:**
- **Always use** `sz_delete_streak_safely()` function for streak deletion
- **Ensure foreign key constraints** are properly set up
- **Test deletion process** in development environment first

## 📋 **Checklist for Database Maintenance**

### **Before Major Operations:**
- [ ] **Backup database** (always!)
- [ ] **Run orphaned data check** to establish baseline
- [ ] **Document current state** of orphaned records

### **After Major Operations:**
- [ ] **Run orphaned data check** to verify no new orphaned data
- [ ] **Compare before/after counts** to ensure consistency
- [ ] **Test application functionality** to ensure no broken references

### **Regular Maintenance:**
- [ ] **Weekly orphaned data check** during low-traffic periods
- [ ] **Monthly cleanup** if orphaned data accumulates
- [ ] **Quarterly review** of deletion processes and constraints

## 🚨 **Troubleshooting**

### **Common Issues:**

#### **Foreign Key Constraint Errors:**
```
ERROR: 23503: insert or update on table "sz_streak_members" 
violates foreign key constraint "fk_streak_members_streak_id"
```
**Solution**: Run orphaned data check and cleanup scripts

#### **Application Errors:**
- **Missing streak data** in UI
- **Failed check-ins** due to invalid streak references
- **Broken member lists** or habit selections

**Solution**: Check for orphaned data and clean up

#### **Performance Issues:**
- **Slow queries** due to orphaned records
- **Database bloat** from unused data

**Solution**: Regular orphaned data cleanup

## 📚 **Related Documentation**
- [DATABASE_CLEANUP_README.md](./DATABASE_CLEANUP_README.md) - Complete cleanup guide
- [check_orphaned_records.sql](./check_orphaned_records.sql) - Diagnostic script
- [cleanup_orphaned_data.sql](./cleanup_orphaned_data.sql) - Cleanup script
- [fix_streak_deletion_cleanup_safe.sql](./fix_streak_deletion_cleanup_safe.sql) - Prevention script

## 🎯 **Best Practices**

### **For Developers:**
- **Always check for orphaned data** after streak operations
- **Use the diagnostic script** before manual database changes
- **Document any orphaned data findings** for team awareness

### **For Database Administrators:**
- **Schedule regular orphaned data checks** (weekly/monthly)
- **Monitor orphaned data trends** to identify systemic issues
- **Maintain cleanup procedures** and update documentation

### **For Operations:**
- **Include orphaned data checks** in deployment procedures
- **Set up alerts** for orphaned data accumulation
- **Plan maintenance windows** for cleanup operations

---

**⚠️ Remember: Always backup your database before running cleanup operations!**

**📞 Support: If you encounter issues, check the troubleshooting section and related documentation.**
