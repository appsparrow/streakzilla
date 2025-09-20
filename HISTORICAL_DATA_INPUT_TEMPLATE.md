# 📊 Historical 75 Hard Plus Data Input Template

## 🎯 Purpose
This template helps you input historical data for users who completed 75 Hard Plus challenges before using the Streakzilla app.

## 📋 Data Collection Template

### **User Information Needed:**
For each user who completed 75 Hard Plus, collect:

1. **User ID** (from Supabase auth.users table)
2. **Display Name** (how they want to be known)
3. **Streak Name** (name they gave their challenge)
4. **Start Date** (when they began - YYYY-MM-DD format)
5. **End Date** (when they completed - YYYY-MM-DD format)
6. **Selected Habits** (which habits they completed daily)

### **Available 75 Hard Plus Habits:**
- ✅ Drink 1 gallon of water
- ✅ Two 45-minute workouts
- ✅ Read 10 pages of non-fiction
- ✅ Follow a diet
- ✅ Take a progress photo
- ✅ No Alcohol

---

## 📝 Data Input Format

### **Example User Data:**
```json
{
  "user_id": "123e4567-e89b-12d3-a456-426614174000",
  "user_name": "John Doe",
  "streak_name": "My 75 Hard Plus Journey",
  "start_date": "2024-01-01",
  "end_date": "2024-03-16",
  "selected_habits": [
    "Drink 1 gallon of water",
    "Two 45-minute workouts",
    "Read 10 pages of non-fiction",
    "Follow a diet",
    "Take a progress photo",
    "No Alcohol"
  ]
}
```

### **Multiple Users Format:**
```json
[
  {
    "user_id": "123e4567-e89b-12d3-a456-426614174000",
    "user_name": "John Doe",
    "streak_name": "My 75 Hard Plus Journey",
    "start_date": "2024-01-01",
    "end_date": "2024-03-16",
    "selected_habits": [
      "Drink 1 gallon of water",
      "Two 45-minute workouts",
      "Read 10 pages of non-fiction",
      "Follow a diet",
      "Take a progress photo",
      "No Alcohol"
    ]
  },
  {
    "user_id": "987fcdeb-51a2-43d7-b890-123456789abc",
    "user_name": "Jane Smith",
    "streak_name": "75 Hard Plus Challenge",
    "start_date": "2024-02-01",
    "end_date": "2024-04-16",
    "selected_habits": [
      "Drink 1 gallon of water",
      "Two 45-minute workouts",
      "Read 10 pages of non-fiction",
      "Follow a diet",
      "Take a progress photo",
      "No Alcohol"
    ]
  }
]
```

---

## 🔍 How to Find User IDs

### **Option 1: Supabase Dashboard**
1. Go to Supabase Dashboard
2. Navigate to **Authentication** → **Users**
3. Copy the UUID for each user

### **Option 2: SQL Query**
```sql
SELECT id, email, raw_user_meta_data->>'display_name' as display_name
FROM auth.users
ORDER BY created_at DESC;
```

---

## 📊 What Gets Created

For each user, the script will create:

### **1. Streak Record**
- ✅ Streak with name and dates
- ✅ Marked as completed (inactive)
- ✅ 75-day duration
- ✅ Unique code for identification

### **2. User Membership**
- ✅ User added as admin of their streak
- ✅ Current streak: 75 days
- ✅ Lives remaining: 3 (started with 3)
- ✅ Status: Completed (not out)

### **3. Selected Habits**
- ✅ Links user to their chosen habits
- ✅ Only the habits they actually completed

### **4. Daily Check-ins**
- ✅ 75 check-in records (one for each day)
- ✅ All selected habits marked as completed
- ✅ Points calculated based on habit values
- ✅ Backdated timestamps (6 PM each day)

### **5. Progress Photos**
- ✅ 75 progress photo records
- ✅ Backdated timestamps (8 PM each day)
- ✅ Placeholder photo URLs

### **6. Total Points**
- ✅ Automatically calculated from all check-ins
- ✅ Updated in user's streak membership

---

## 🚀 How to Use

### **Step 1: Collect Data**
- Use the template above to collect user information
- Make sure you have all required fields
- Verify dates are correct (75 days apart)

### **Step 2: Update SQL Script**
- Open `populate_historical_data_template.sql`
- Replace the user_data section with your actual data
- Make sure to replace `REPLACE_WITH_USER_ID_1` etc. with actual UUIDs

### **Step 3: Run Script**
- Open Supabase SQL Editor
- Paste the updated script
- Click "Run" to execute

### **Step 4: Verify Results**
- Check the verification queries at the bottom
- Confirm all data was created correctly
- Users should see their historical streaks in the app

---

## ⚠️ Important Notes

### **Before Running:**
- ✅ **Backup your database** before running the script
- ✅ **Verify user IDs** are correct
- ✅ **Check dates** are exactly 75 days apart
- ✅ **Confirm habit names** match exactly (case-sensitive)

### **After Running:**
- ✅ **Check verification queries** for success
- ✅ **Test in the app** that users can see their streaks
- ✅ **Verify check-ins** show as completed
- ✅ **Confirm points** are calculated correctly

### **Troubleshooting:**
- ❌ **Habit not found**: Check exact spelling and case
- ❌ **User not found**: Verify UUID is correct
- ❌ **Date errors**: Ensure dates are valid and 75 days apart
- ❌ **Duplicate data**: Script includes checks to prevent duplicates

---

## 📞 Support

If you encounter any issues:
1. Check the verification queries first
2. Look for error messages in the SQL output
3. Verify your data format matches the template
4. Contact support with specific error details

**The script is designed to be safe and will not overwrite existing data.**
