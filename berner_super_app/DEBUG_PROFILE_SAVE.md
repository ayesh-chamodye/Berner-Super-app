# Debug Guide: Profile Not Saving to Supabase

## 🔍 How to Debug Profile Save Issues

When you complete profile setup, you'll now see detailed logs in your Flutter console that show exactly where the process is failing.

---

## ✅ **What Should Happen (Successful Flow)**

When profile save works correctly, you'll see:

```
🔵 ProfileSetupPage: Starting profile save
🔵 ProfileSetupPage: User ID: 1
🔵 ProfileSetupPage: Mobile Number: 0766568369
🔵 ProfileSetupPage: Attempting to save to Supabase...
🔵 ProfileSetupPage: Name: John Doe
🔵 ProfileSetupPage: NIC: 123456789V
🔵 ProfileSetupPage: DOB: 1990-01-01
🔵 ProfileSetupPage: Gender: male
🔵 SupabaseService: Creating/updating profile for 0766568369
🔵 SupabaseService: Querying users table for phone: 0766568369
🟢 SupabaseService: Found user ID: 1
🔵 SupabaseService: Checking if profile exists for user ID: 1
🔵 SupabaseService: Profile data prepared: [user_id, first_name, last_name, full_name, nic, ...]
🔵 SupabaseService: No existing profile found - creating new one
🟢 SupabaseService: Profile created successfully!
🟢 ProfileSetupPage: Profile saved to Supabase successfully!
🟢 ProfileSetupPage: Profile saved locally
```

---

## ❌ **Common Errors and Solutions**

### **Error 1: "relation 'users' does not exist"**

```
❌ SupabaseService: Error creating/updating user profile
❌ Error details: PostgrestException: relation "users" does not exist
⚠️ Common causes:
   1. Supabase tables not created (run SQL scripts)
```

**Solution:**
1. Go to Supabase Dashboard → SQL Editor
2. Run `database/COMPLETE_SCHEMA.sql`
3. Verify tables exist in Table Editor

---

### **Error 2: "No rows found"**

```
🔵 SupabaseService: Querying users table for phone: 0766568369
❌ SupabaseService: Error creating/updating user profile
❌ Error details: PostgrestException: No rows found
⚠️ Common causes:
   2. User does not exist in users table
```

**What this means:** The user was not created in the `users` table during registration.

**Solution:**

Check the registration logs. You should see:
```
🔵 Starting user registration for: 0766568369
🔵 Creating new user in Supabase with role: customer
🔵 SupabaseService: Creating basic user in users table
🟢 SupabaseService: User created with ID: 1
```

If you see errors in registration, the database tables might not exist.

---

### **Error 3: "Failed host lookup" or "SocketException"**

```
❌ SupabaseService: Error creating/updating user profile
❌ Error details: SocketException: Failed host lookup
⚠️ Common causes:
   3. Network connection issue
```

**Solutions:**
- Check your device/emulator has internet connection
- Try: `ping ompqyjdrfnjdxqavslhg.supabase.co` from terminal
- Check if Supabase project is paused (unpause it)

---

### **Error 4: "Invalid API key" or "JWT expired"**

```
❌ SupabaseService: Error creating/updating user profile
❌ Error details: Invalid API key
⚠️ Common causes:
   4. Invalid Supabase credentials in .env
```

**Solution:**
1. Go to Supabase Dashboard → Settings → API
2. Copy the **anon public** key (not the service_role key!)
3. Update `SUPABASE_ANON_KEY` in `.env` file
4. **Restart app** (not hot reload - full restart!)

---

### **Error 5: Profile saves locally but not to Supabase**

```
❌ ProfileSetupPage: Failed to save to Supabase: <error>
⚠️ ProfileSetupPage: Will save to local storage only
🟢 ProfileSetupPage: Profile saved locally
```

**What this means:** The app couldn't reach Supabase, but saved to local storage as fallback.

**This is OK for development!** The app will still work, but:
- ❌ Data won't sync across devices
- ❌ Data won't appear in Supabase dashboard
- ❌ No cloud backup

To fix: Follow the error message and resolve the Supabase connection issue.

---

## 🔧 **How to Verify Data Was Saved**

### **1. Check Flutter Console Logs**

Look for this line:
```
🟢 SupabaseService: Profile created successfully!
```

### **2. Check Supabase Dashboard**

1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Open your project
3. Go to **Table Editor**
4. Click on **users** table
5. You should see your user with phone number
6. Click on **user_profiles** table
7. You should see your profile data

### **3. Run SQL Query**

In Supabase SQL Editor, run:

```sql
-- Check if user exists
SELECT * FROM users WHERE mobile_number = '0766568369';

-- Check if profile exists
SELECT
  u.id,
  u.mobile_number,
  u.role,
  up.full_name,
  up.nic,
  up.gender
FROM users u
LEFT JOIN user_profiles up ON u.id = up.user_id
WHERE u.mobile_number = '0766568369';
```

If you see data, it worked! 🎉

---

## 📋 **Debugging Checklist**

Before asking "why isn't data saving?", check:

- [ ] Supabase project exists and is not paused
- [ ] Ran `COMPLETE_SCHEMA.sql` in Supabase SQL Editor
- [ ] Tables `users` and `user_profiles` exist in Table Editor
- [ ] `.env` file has correct `SUPABASE_URL`
- [ ] `.env` file has correct `SUPABASE_ANON_KEY`
- [ ] Device/emulator has internet connection
- [ ] Did **full restart** of app (not just hot reload)
- [ ] Checked Flutter console for detailed error logs

---

## 🎯 **Quick Test: Is Supabase Working?**

Run this test to verify Supabase connection:

1. Open Flutter console
2. Start the app
3. Look for this line during app startup:
   ```
   ✓ Supabase initialized
   ```

If you see:
```
⚠ Supabase initialization failed: <error>
```

Then Supabase is not configured correctly. Check your `.env` file.

---

## 🆘 **Still Not Working?**

### **Option 1: Use App Without Supabase**

The app works perfectly fine with just local storage:
- ✅ OTP sending via text.lk works
- ✅ User data saves locally
- ✅ Login/logout works
- ✅ All features work

You just won't have cloud sync.

### **Option 2: Fresh Start**

1. Delete the Supabase project
2. Create a new Supabase project
3. Copy new URL and anon key to `.env`
4. Run all 3 SQL scripts in order
5. **Full restart** of app
6. Try registering again

---

## 📊 **Understanding the Save Flow**

```
User fills profile form
         ↓
Click "Complete Profile"
         ↓
App tries to save to Supabase
         ↓
   ┌─────┴─────┐
   ↓           ↓
SUCCESS      FAILURE
   ↓           ↓
Saves to      Saves to
Supabase      Local Only
   ↓           ↓
Shows success message
   ↓
Navigate to Home
```

**Key point:** Even if Supabase save fails, the app continues and saves locally. This is by design!

---

## 🔬 **Advanced: Raw HTTP Test**

Test Supabase connection directly:

```bash
curl https://ompqyjdrfnjdxqavslhg.supabase.co/rest/v1/users?select=id \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Authorization: Bearer YOUR_ANON_KEY"
```

If this works, Supabase is reachable!

---

## ✅ **Summary**

The detailed logging will now show you **exactly** where the save is failing:

1. ❌ Can't find user in `users` table → User wasn't created during registration
2. ❌ Table doesn't exist → Run SQL scripts
3. ❌ Network error → Check internet/Supabase status
4. ❌ Invalid credentials → Update `.env` file
5. ✅ Success → Data saved to Supabase!

**Check your Flutter console logs after trying to save profile!**
