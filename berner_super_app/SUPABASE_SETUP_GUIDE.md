# Supabase Setup Guide - Fix Connection Errors

## 🔴 Current Error

```
Error getting user profile: ClientException with SocketException:
Failed host lookup: 'ompqyjdrfnjdxqavslhg.supabase.co'
```

## ✅ Solution: Set Up Supabase Database

Your app is configured to use Supabase, but the database tables haven't been created yet. Follow these steps:

---

## Step 1: Verify Supabase Project

1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Log in to your account
3. Check if project `ompqyjdrfnjdxqavslhg` exists
4. If the project is **paused**, click "Restore" or "Unpause"
5. If the project **doesn't exist**, create a new one

---

## Step 2: Create Database Tables

You need to run 3 SQL scripts in order:

### 2.1: Run COMPLETE_SCHEMA.sql

1. In Supabase Dashboard, go to **SQL Editor**
2. Click **"New Query"**
3. Open file: `database/COMPLETE_SCHEMA.sql`
4. Copy **ALL** the contents
5. Paste into Supabase SQL Editor
6. Click **"Run"** (or press Ctrl+Enter)
7. Wait for success message

This creates:
- ✅ `users` table
- ✅ `user_profiles` table
- ✅ `otp_logs` table
- ✅ `expenses` table
- ✅ And 8 more tables...

### 2.2: Run 02_helper_functions.sql

1. Still in SQL Editor, click **"New Query"**
2. Open file: `database/02_helper_functions.sql`
3. Copy and paste contents
4. Click **"Run"**

This creates helper functions for the database.

### 2.3: Run 04_advanced_functions.sql

1. Click **"New Query"** again
2. Open file: `database/04_advanced_functions.sql`
3. Copy and paste contents
4. Click **"Run"**

This creates advanced functions including `create_user_with_profile()`.

---

## Step 3: Verify Tables Were Created

1. In Supabase Dashboard, go to **Table Editor**
2. You should see these tables:
   - ✅ users
   - ✅ user_profiles
   - ✅ otp_logs
   - ✅ expenses
   - ✅ expense_categories
   - ✅ notifications
   - ✅ And more...

3. Go to **Database** → **Functions**
4. You should see:
   - ✅ create_user_with_profile
   - ✅ generate_adm_code
   - ✅ And more...

---

## Step 4: Enable Row Level Security (RLS)

The SQL scripts already enabled RLS, but verify:

1. Go to **Authentication** → **Policies**
2. For `users` table, you should see policies for:
   - ✅ Users can read own data
   - ✅ Users can update own data
   - ✅ Service role can do everything

---

## Step 5: Test the App

1. **Restart the app** (hot reload won't work - full restart needed)
   ```bash
   flutter run
   ```

2. **Try registering a new user**
   - Enter phone number
   - Request OTP (this will use text.lk, NOT Supabase)
   - Enter OTP
   - Fill profile information

3. **Check Supabase Dashboard**
   - Go to **Table Editor** → **users**
   - You should see your new user!
   - Go to **Table Editor** → **user_profiles**
   - You should see your profile data!

---

## 🔧 Alternative: App Works Without Supabase

**Good News:** The app has fallback to local storage!

Even if Supabase isn't set up, the app will still work by:
- ✅ Storing user data locally (SharedPreferences)
- ✅ Sending OTP via text.lk (this works independently)
- ✅ Verifying OTP locally

However, you **lose these features** without Supabase:
- ❌ Data sync across devices
- ❌ Cloud backup
- ❌ Multi-user access
- ❌ Admin panel features

---

## 🐛 Troubleshooting

### Error: "relation vw_user_details does not exist"

**Solution:** The database view wasn't created. Run `COMPLETE_SCHEMA.sql` again.

### Error: "function create_user_with_profile does not exist"

**Solution:** The database functions weren't created. Run `04_advanced_functions.sql`.

### Error: "Failed host lookup"

**Possible causes:**
1. **No internet connection** - Check your device/emulator has internet
2. **Supabase project paused** - Unpause it in dashboard
3. **Wrong Supabase URL** - Check `.env` file has correct URL

### Error: "JWT expired" or "Invalid API key"

**Solution:** Your `SUPABASE_ANON_KEY` in `.env` is wrong or expired.

1. Go to Supabase Dashboard → **Settings** → **API**
2. Copy the **anon public** key
3. Update `SUPABASE_ANON_KEY` in `.env` file
4. Restart app (full restart, not hot reload)

---

## 📋 Quick Checklist

- [ ] Supabase project exists and is not paused
- [ ] Ran `COMPLETE_SCHEMA.sql` in SQL Editor
- [ ] Ran `02_helper_functions.sql` in SQL Editor
- [ ] Ran `04_advanced_functions.sql` in SQL Editor
- [ ] Verified tables exist in Table Editor
- [ ] Verified functions exist in Database → Functions
- [ ] `.env` has correct `SUPABASE_URL`
- [ ] `.env` has correct `SUPABASE_ANON_KEY`
- [ ] Restarted app (full restart, not hot reload)
- [ ] text.lk API token is configured (for OTP SMS)

---

## 🎯 Expected Behavior After Setup

When you register a new user:

```
📱 AuthService: Validating phone number
🔐 AuthService: OTP generated locally: 123456
💾 AuthService: OTP stored in local device storage
📤 AuthService: Sending OTP via text.lk SMS API...
✅ text.lk: SMS sent successfully via text.lk API
📝 AuthService: Logging OTP attempt to Supabase (audit trail only)
🔵 Starting user registration for: 0766568369
🔵 Creating new user in Supabase with role: customer
🔵 SupabaseService: Creating basic user in users table
🟢 SupabaseService: User created with ID: 1
🟢 User marked as verified
🔵 SupabaseService: Fetching user profile for 0766568369
🟢 SupabaseService: User profile fetched successfully
```

---

## 💡 Need Help?

Check these files for more info:
- `OTP_ARCHITECTURE.md` - How OTP works
- `COMPLETE_SCHEMA_SETUP.md` - Database setup details
- `MIGRATION_TO_COMPLETE_SCHEMA.md` - Migration guide

**Still having issues?** Make sure:
1. Your Supabase project is active (not paused)
2. You have internet connection
3. The SQL scripts ran without errors
4. You did a **full restart** of the app (not hot reload)
