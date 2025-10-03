# Gender Field Fix

## 🔴 The Error

```
PostgrestException: new row for relation "user_profiles" violates check constraint "user_profiles_gender_check"
```

---

## 🎯 **What Was Wrong**

**The Mismatch:**
- **App sends:** `'Male'`, `'Female'`, `'Other'` (capitalized)
- **Database expects:** `'male'`, `'female'`, `'other'`, `'prefer_not_to_say'` (lowercase)

The database has a CHECK constraint that only allows lowercase values:

```sql
gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say'))
```

---

## ✅ **The Fix**

I've updated the code to convert gender to lowercase before saving:

```dart
// Convert gender to lowercase to match database constraint
final genderValue = _selectedGender?.toLowerCase();

await SupabaseService.createOrUpdateUserProfile(
  // ...
  gender: genderValue,  // Now sends 'male' instead of 'Male'
);
```

**Location:** [lib/screens/auth/profile_setup_page.dart](lib/screens/auth/profile_setup_page.dart:262-274)

---

## 🔄 **What To Do Now**

### **Option 1: Restart App (Recommended)**

The fix is already in the code. Just restart your app:

```bash
flutter run
```

Then try filling the profile form again. It should work now! ✅

---

### **Option 2: If You Have Existing Data**

If you already have users with capitalized gender values in the database, you can fix them:

```sql
-- Fix existing records (run in Supabase SQL Editor)
UPDATE user_profiles
SET gender = LOWER(gender)
WHERE gender IN ('Male', 'Female', 'Other');
```

---

## 🧪 **How to Verify**

After the fix, when you save profile:

**Console logs will show:**
```
🔵 ProfileSetupPage: Gender: Male
🔵 ProfileSetupPage: Gender (converted): male    ← Converted to lowercase!
🟢 SupabaseService: Profile created successfully!
```

**Supabase Table Editor:**
```
user_profiles table:
├── gender: 'male'     ✅ (lowercase)
└── gender: 'female'   ✅ (lowercase)
```

---

## 📊 **Valid Gender Values**

The database accepts these values (all lowercase):
- ✅ `'male'`
- ✅ `'female'`
- ✅ `'other'`
- ✅ `'prefer_not_to_say'`

**Note:** The UI still shows capitalized for better user experience:
- User sees: "Male", "Female", "Other"
- Database stores: "male", "female", "other"

---

## ✅ **Summary**

**Problem:** Gender values were capitalized, database expects lowercase
**Fix:** Convert to lowercase before saving
**Status:** FIXED ✅

Just restart your app and try again!
