# 🔄 Migration Guide: Complete Schema Integration

## Overview

This guide explains how to migrate your Flutter app to use the new complete database schema (`COMPLETE_SCHEMA.sql`).

---

## ✅ What's Been Done

### 1. **UserModel Updated** ✅
**File:** [lib/models/user_model.dart](lib/models/user_model.dart)

**Changes:**
- ✅ Added `owner` and `admin` roles
- ✅ Separated fields for `users` and `user_profiles` tables
- ✅ Added new fields: `firstName`, `lastName`, `fullName`, `email`, `department`, `position`, `businessName`
- ✅ Added status fields: `isActive`, `isBlocked`, `lastLoginAt`
- ✅ Updated `fromJson()` to handle both snake_case (database) and camelCase (legacy)
- ✅ Added legacy compatibility getters (`name`, `profilePicturePath`)

### 2. **SupabaseService Updated** ✅
**File:** [lib/services/supabase_service.dart](lib/services/supabase_service.dart)

**Changes:**
- ✅ `getUserProfile()` now uses `vw_user_details` view (joins users + profiles)
- ✅ `createUserProfile()` uses `create_user_with_profile()` database function
- ✅ `updateUserProfile()` updates `user_profiles` table correctly

### 3. **Database Schema Created** ✅
**Files:**
- [database/COMPLETE_SCHEMA.sql](database/COMPLETE_SCHEMA.sql) - Main schema
- [database/04_advanced_functions.sql](database/04_advanced_functions.sql) - Helper functions
- [database/COMPLETE_DATABASE_GUIDE.md](database/COMPLETE_DATABASE_GUIDE.md) - Documentation

---

## 🔧 Steps to Complete Migration

### Step 1: Run Database Scripts ⚠️ **REQUIRED**

```sql
-- In Supabase SQL Editor

-- 1. Run main schema
-- Copy entire content of database/COMPLETE_SCHEMA.sql
-- Paste and Run

-- 2. Run helper functions
-- Copy entire content of database/02_helper_functions.sql
-- Paste and Run

-- 3. Run advanced functions
-- Copy entire content of database/04_advanced_functions.sql
-- Paste and Run
```

**Verify:**
```sql
-- Check tables (should show 12)
SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';

-- Check view exists
SELECT * FROM vw_user_details LIMIT 1;

-- Check function exists
SELECT routine_name FROM information_schema.routines
WHERE routine_name = 'create_user_with_profile';
```

### Step 2: Update AuthService

**File:** [lib/services/auth_service.dart](lib/services/auth_service.dart)

**Current Issue:**
- Uses old `upsert_user()` which doesn't create profile

**Fix:**
```dart
// In registerUser() method, replace:

// OLD:
final userId = await SupabaseService.upsertUser(
  mobileNumber: mobileNumber,
  role: role.toString().split('.').last,
);

// NEW:
final userId = await SupabaseService.createUserProfile({
  'mobile_number': mobileNumber,
  'role': role.toString().split('.').last,
  'first_name': null,  // Will be added in profile setup
  'last_name': null,
  'email': null,
  'nic': null,
});
```

### Step 3: Update ProfileSetupPage

**File:** [lib/screens/auth/profile_setup_page.dart](lib/screens/auth/profile_setup_page.dart)

**Update to use new fields:**
```dart
// When saving profile, use:
await AuthService.updateUserProfile(user.copyWith(
  firstName: firstNameController.text,
  lastName: lastNameController.text,
  fullName: '${firstNameController.text} ${lastNameController.text}',
  nic: nicController.text,
  dateOfBirth: selectedDate,
  gender: selectedGender,
));
```

### Step 4: Update RoleSelectionPage

**File:** [lib/screens/auth/role_selection_page.dart](lib/screens/auth/role_selection_page.dart)

**Add owner role option:**
```dart
// Add to the role options:
_buildRoleCard(
  context,
  'Owner',
  'Manage business and approve expenses',
  Icons.business_center,
  AppColors.secondaryBlue,
  UserRole.owner,
),
```

### Step 5: Test Migration

**Test checklist:**

1. **Registration Flow:**
   ```
   ✅ Enter mobile number
   ✅ Receive OTP
   ✅ Verify OTP
   ✅ User created in `users` table
   ✅ Profile created in `user_profiles` table
   ✅ ADM code generated for employees
   ```

2. **Profile Completion:**
   ```
   ✅ Enter name, NIC, DOB, gender
   ✅ Data saved to `user_profiles` table
   ✅ Can retrieve full profile
   ```

3. **Login Flow:**
   ```
   ✅ Enter existing mobile number
   ✅ Receive OTP
   ✅ Verify OTP
   ✅ User data loaded from `vw_user_details`
   ✅ `last_login_at` updated
   ```

---

## 📋 Database Migration Checklist

### Before Migration
- [ ] **Backup existing data** (if any)
- [ ] **Note current .env configuration**
- [ ] **List any custom queries** in your app

### During Migration
- [ ] Run `COMPLETE_SCHEMA.sql`
- [ ] Run `02_helper_functions.sql`
- [ ] Run `04_advanced_functions.sql`
- [ ] Verify all tables created
- [ ] Verify all functions created
- [ ] Verify views created

### After Migration
- [ ] Test user registration
- [ ] Test user login
- [ ] Test profile updates
- [ ] Test data retrieval
- [ ] Check `vw_user_details` view returns data
- [ ] Verify ADM codes generated for employees

---

## 🆕 New Features Available

### 1. **Expense Management** (Ready to Use)

**Tables:**
- `expenses` - Main expense records
- `expense_categories` - Pre-loaded categories
- `expense_attachments` - Receipt uploads
- `expense_approvals` - Approval workflow

**Functions:**
```sql
-- Create expense
SELECT create_expense(user_id, title, description, amount, category, date, receipt);

-- Approve expense
SELECT approve_expense_advanced(expense_id, approver_id, notes);

-- Get user stats
SELECT get_user_expense_stats(user_id, start_date, end_date);
```

### 2. **Notifications** (Ready to Use)

**Table:** `notifications`

**Functions:**
```sql
-- Create notification
INSERT INTO notifications (user_id, title, message, type) VALUES (...);

-- Bulk notifications
SELECT create_bulk_notification(user_ids[], title, message, type);

-- Get unread count
SELECT get_unread_notification_count(user_id);
```

### 3. **Session Management** (Ready to Use)

**Table:** `user_sessions`

**Functions:**
```sql
-- Create session
SELECT create_user_session(user_id, device_info, ip_address, duration);

-- Validate session
SELECT validate_session(session_token);
```

### 4. **Activity Logs** (Automatic)

**Table:** `activity_logs`

All user actions automatically logged when using database functions.

---

## 🔍 Verification Queries

### Check User Structure
```sql
-- See all user data
SELECT * FROM vw_user_details WHERE mobile_number = '0771234567';

-- Check user + profile
SELECT
  u.id, u.mobile_number, u.role, u.adm_code,
  p.full_name, p.email, p.department
FROM users u
LEFT JOIN user_profiles p ON u.id = p.user_id
WHERE u.mobile_number = '0771234567';
```

### Check Expense Categories
```sql
-- Should return 10 categories
SELECT * FROM expense_categories ORDER BY sort_order;
```

### Check App Settings
```sql
-- Should return ~10 settings
SELECT * FROM app_settings;
```

---

## ⚠️ Breaking Changes

### 1. **User ID Type Changed**
- **Before:** `String` (phone number or UUID)
- **After:** `String` representation of `BIGINT` (e.g., "1", "2", "3")

**Impact:** Minimal - UserModel already uses String

### 2. **Profile Fields Separated**
- **Before:** All in `users` table
- **After:** Split between `users` and `user_profiles`

**Impact:** Handled by `vw_user_details` view

### 3. **Database Function Calls**
- **Before:** Direct table inserts
- **After:** Use database functions

**Impact:** Better data integrity, automatic ADM code generation

---

## 🐛 Troubleshooting

### Issue: "View vw_user_details does not exist"

**Cause:** Schema not fully installed

**Fix:**
```sql
-- Re-run COMPLETE_SCHEMA.sql
-- The view is created at the end of the script
```

### Issue: "Function create_user_with_profile does not exist"

**Cause:** Advanced functions not installed

**Fix:**
```sql
-- Run 04_advanced_functions.sql
```

### Issue: "User profile is null after creation"

**Cause:** Profile not created with user

**Fix:**
Use `create_user_with_profile()` function instead of direct insert.

### Issue: "ADM code is null for employees"

**Cause:** Not using database function

**Fix:**
The `create_user_with_profile()` function automatically generates ADM codes for employees.

---

## 📊 Data Flow

### Registration (New Flow)

```
1. User enters phone → Send OTP via text.lk
   ↓
2. User enters OTP → Verify
   ↓
3. Call create_user_with_profile()
   ├─→ Creates row in `users` table (auto ID, auto ADM code)
   ├─→ Creates row in `user_profiles` table
   └─→ Creates welcome notification
   ↓
4. User completes profile
   └─→ Updates `user_profiles` table
```

### Login (New Flow)

```
1. User enters phone → Check if registered
   ↓
2. Send OTP → Verify
   ↓
3. Query vw_user_details (joined data)
   ↓
4. Update last_login_at in `users` table
   ↓
5. Create session in `user_sessions` table
```

---

## ✅ Migration Complete Checklist

- [ ] Database schema installed (COMPLETE_SCHEMA.sql)
- [ ] Helper functions installed (02_helper_functions.sql)
- [ ] Advanced functions installed (04_advanced_functions.sql)
- [ ] AuthService updated for new schema
- [ ] ProfileSetupPage updated
- [ ] RoleSelectionPage updated (added owner role)
- [ ] Registration tested successfully
- [ ] Login tested successfully
- [ ] Profile updates tested successfully
- [ ] ADM codes generating for employees
- [ ] `vw_user_details` returning full data
- [ ] No errors in app logs

---

## 🚀 Next Steps

After migration is complete:

1. **Test thoroughly** - All auth flows
2. **Implement expense management** - Use new tables
3. **Add notifications** - Use notification table
4. **Monitor performance** - Check query speeds
5. **Set up maintenance** - Schedule cleanup jobs

---

## 📚 Additional Resources

- [COMPLETE_DATABASE_GUIDE.md](database/COMPLETE_DATABASE_GUIDE.md) - Full database documentation
- [DATABASE_SETUP_QUICK.md](DATABASE_SETUP_QUICK.md) - Quick setup guide
- [SECURITY_IMPROVEMENTS.md](SECURITY_IMPROVEMENTS.md) - Security features

---

**Need Help?** Check the database guide or review the SQL scripts for examples.

---

**Last Updated:** 2025-10-01
**Migration Status:** 🟡 **Partially Complete - Database Ready, App Needs Updates**
