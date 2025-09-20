# 🧪 Heart Protection System Testing Guide

## 📋 Overview

This document provides comprehensive testing procedures for the automatic heart protection system in Streakzilla. The heart protection system automatically uses hearts to protect streaks when users miss days, eliminating the need for manual intervention.

## 🎯 What We're Testing

- **Automatic Heart Usage**: Hearts are automatically used when checking in after missing a day
- **Streak Protection**: Streaks continue instead of breaking when hearts are available
- **Database Transactions**: Heart usage is properly recorded in the database
- **User Experience**: No manual "Use Heart" button needed

## 🚀 Setup Instructions

### Step 1: Apply the Heart Protection System

Run the main SQL script to enable automatic heart protection:

```sql
-- Run this in Supabase SQL Editor
apply_auto_heart_protection.sql
```

**Expected Result**: All functions created successfully without errors.

### Step 2: Verify Database Schema

Ensure the following tables and columns exist:

```sql
-- Check if heart columns exist
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'sz_streak_members' 
AND column_name IN ('hearts_available', 'hearts_earned', 'hearts_used');

-- Check if heart transactions table exists
SELECT table_name 
FROM information_schema.tables 
WHERE table_name = 'sz_hearts_transactions';
```

## 🧪 Testing Methods

### Method 1: Simple Database Test (Recommended)

**Purpose**: Quick verification that the heart protection system works at the database level.

**Steps**:

1. **Run the simple test script**:
   ```sql
   -- Run this in Supabase SQL Editor
   simple_heart_test.sql
   ```

2. **Check the results**:
   ```sql
   -- Verify hearts were used
   SELECT 
       hearts_available,
       hearts_used,
       current_streak,
       CASE 
           WHEN hearts_used > 0 THEN '✅ SUCCESS: Hearts automatically used!'
           ELSE '❌ FAILED: No hearts were used'
       END as test_result
   FROM sz_streak_members
   WHERE streak_id = '00000000-0000-0000-0000-000000000001';
   ```

3. **Check heart transactions**:
   ```sql
   -- Verify transaction was recorded
   SELECT 
       transaction_type,
       day_number,
       note,
       hearts_amount,
       created_at
   FROM sz_hearts_transactions
   WHERE streak_id = '00000000-0000-0000-0000-000000000001'
   ORDER BY created_at DESC;
   ```

**Expected Results**:
- ✅ `hearts_used` > 0
- ✅ `hearts_available` = 0 (if only 1 heart was available)
- ✅ `current_streak` continues (not reset)
- ✅ Heart transaction recorded with `transaction_type = 'auto_use'`

### Method 2: Comprehensive Database Test

**Purpose**: More thorough testing with multiple scenarios.

**Steps**:

1. **Run the comprehensive test script**:
   ```sql
   -- Run this in Supabase SQL Editor
   test_heart_protection.sql
   ```

2. **Analyze the results**:
   - Check streak member data
   - Verify heart transactions
   - Confirm automatic protection worked

### Method 3: Frontend Testing (Real User Experience)

**Purpose**: Test the complete user experience from the frontend.

**Steps**:

1. **Create a test streak**:
   - Go to `/create` in the app
   - Enable "Points to Hearts" system
   - Create a streak

2. **Check in for Day 1**:
   - Complete some habits
   - Verify check-in works normally

3. **Miss Day 2**:
   - Don't check in for Day 2
   - Wait until Day 3

4. **Check in for Day 3**:
   - Go to the streak details page
   - You should see: "Oh no! You broke your streak yesterday 💔"
   - Check in for Day 3
   - You should see: "Check-in completed! 🎉 Hearts automatically protect your streak! ❤️"

5. **Verify the results**:
   - Streak should continue (not broken)
   - Hearts should be used automatically
   - No manual intervention required

## 🔍 Test Scenarios

### Scenario 1: Single Missed Day with Available Hearts

**Setup**:
- User has 1 heart available
- Misses Day 2
- Checks in for Day 3

**Expected Result**:
- Heart automatically used
- Streak continues
- Heart transaction recorded

### Scenario 2: Multiple Missed Days with Multiple Hearts

**Setup**:
- User has 3 hearts available
- Misses Days 2, 3, and 4
- Checks in for Day 5

**Expected Result**:
- 3 hearts automatically used
- Streak continues
- 3 heart transactions recorded

### Scenario 3: No Hearts Available

**Setup**:
- User has 0 hearts available
- Misses a day
- Checks in next day

**Expected Result**:
- No hearts used
- Streak breaks (normal behavior)
- No heart transactions

### Scenario 4: Heart System Disabled

**Setup**:
- Streak has `points_to_hearts_enabled = false`
- User misses a day
- Checks in next day

**Expected Result**:
- No hearts used
- Streak breaks (normal behavior)
- No heart transactions

## 📊 Success Criteria

### ✅ Database Level
- [ ] `sz_auto_use_heart_on_miss` function exists and works
- [ ] `sz_auto_protect_streak_on_checkin` function exists and works
- [ ] `sz_checkin` function returns correct data
- [ ] Heart transactions are recorded in `sz_hearts_transactions`
- [ ] `sz_streak_members` data is updated correctly

### ✅ Frontend Level
- [ ] No "Use Heart" button appears
- [ ] "Missed yesterday" alert shows correct message
- [ ] Check-in success message mentions automatic heart protection
- [ ] Streak continues instead of breaking
- [ ] Heart counts update correctly

### ✅ User Experience
- [ ] No manual intervention required
- [ ] Clear feedback when hearts are used
- [ ] Intuitive flow for users
- [ ] Consistent behavior across all scenarios

## 🐛 Troubleshooting

### Common Issues

**Issue**: "Function sz_auto_use_heart_on_miss does not exist"
**Solution**: Run `apply_auto_heart_protection.sql` first

**Issue**: "Cannot change return type of existing function"
**Solution**: The script now includes `DROP FUNCTION` - run the updated script

**Issue**: Hearts not being used automatically
**Solution**: Check that `points_to_hearts_enabled = true` for the streak

**Issue**: No heart transactions recorded
**Solution**: Verify the `sz_hearts_transactions` table exists and has proper RLS policies

### Debug Queries

```sql
-- Check if heart system is enabled for a streak
SELECT name, points_to_hearts_enabled, hearts_per_100_points
FROM sz_streaks
WHERE id = 'your-streak-id';

-- Check user's heart status
SELECT hearts_available, hearts_earned, hearts_used, current_streak
FROM sz_streak_members
WHERE streak_id = 'your-streak-id' AND user_id = auth.uid();

-- Check recent heart transactions
SELECT *
FROM sz_hearts_transactions
WHERE streak_id = 'your-streak-id'
ORDER BY created_at DESC
LIMIT 10;
```

## 📝 Test Results Template

### Test Run: [Date]

**Environment**: [Development/Staging/Production]

**Test Method**: [Simple/Comprehensive/Frontend]

**Results**:
- [ ] Database functions created successfully
- [ ] Simple test passed
- [ ] Comprehensive test passed
- [ ] Frontend test passed
- [ ] All success criteria met

**Issues Found**:
- [List any issues]

**Notes**:
- [Additional observations]

## 🎉 Conclusion

The heart protection system should work automatically without user intervention. Users simply check in normally, and the system handles streak protection behind the scenes using available hearts.

**Key Benefits**:
- ✅ Seamless user experience
- ✅ Automatic streak protection
- ✅ No manual heart management
- ✅ Clear feedback and notifications
- ✅ Robust database transactions

---

*Last updated: [Current Date]*
*Version: 1.0*
