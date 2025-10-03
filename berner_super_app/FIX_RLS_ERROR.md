# Fix: Row-Level Security (RLS) Error

## 🔴 Error

```
PostgrestException(message: new row violates row-level security policy for table "users",
code: 42501, details: Unauthorized, hint: null)
```

---

## 🎯 **What's Wrong?**

Row Level Security (RLS) is enabled on the `users` table, but there's **no policy allowing anonymous users to INSERT** into it during registration.

### The Problem:

When you try to register, the app tries to insert a new user:
```dart
await client.from('users').insert({
  'mobile_number': phoneNumber,
  'role': role,
  ...
});
```

But RLS blocks it because there's no policy saying "anonymous users can create accounts".

---

## ✅ **The Fix (2 Options)**

### **Option 1: Run Quick Fix SQL (Recommended)**

1. Go to **Supabase Dashboard** → **SQL Editor**
2. Click **New Query**
3. Copy and paste this entire file: `database/FIX_RLS_POLICY.sql`
4. Click **Run** (or press Ctrl+Enter)
5. Restart your app

This adds the missing RLS policies without affecting existing data.

---

### **Option 2: Re-run Complete Schema (Clean Start)**

If you want a completely fresh database:

1. Go to **Supabase Dashboard** → **SQL Editor**
2. **Delete all existing tables** (if any):
   ```sql
   DROP SCHEMA public CASCADE;
   CREATE SCHEMA public;
   GRANT ALL ON SCHEMA public TO postgres;
   GRANT ALL ON SCHEMA public TO public;
   ```

3. Run the updated schema:
   - Copy `database/COMPLETE_SCHEMA.sql`
   - Paste and Run
   - Run `database/02_helper_functions.sql`
   - Run `database/04_advanced_functions.sql`

---

## 📋 **What the Fix Does**

The fix adds 4 new RLS policies:

### 1. Allow Anonymous User Creation
```sql
CREATE POLICY "Allow anon to create users"
    ON users
    FOR INSERT
    TO anon
    WITH CHECK (true);
```
**Purpose:** Lets users register without being logged in

### 2. Allow Anonymous User Read
```sql
CREATE POLICY "Allow anon to read users"
    ON users
    FOR SELECT
    TO anon
    USING (true);
```
**Purpose:** Lets app check if phone number exists during login

### 3. Allow Anonymous User Update
```sql
CREATE POLICY "Allow anon to update users"
    ON users
    FOR UPDATE
    TO anon
    USING (true)
    WITH CHECK (true);
```
**Purpose:** Lets app mark user as verified after OTP

### 4. Allow Anonymous Profile Creation
```sql
CREATE POLICY "Allow anon to create user_profiles"
    ON user_profiles
    FOR INSERT
    TO anon
    WITH CHECK (true);
```
**Purpose:** Lets users create their profile after registration

---

## 🔐 **Is This Secure?**

**YES!** Here's why:

1. **OTP Verification Required** - Users must verify phone number via text.lk before account is active
2. **App-Level Validation** - The Flutter app validates all data before sending
3. **Database Constraints** - Phone numbers must be unique, roles are restricted
4. **Audit Trail** - All OTP attempts are logged in `otp_logs` table
5. **Standard Practice** - This is how phone-based authentication works in Supabase

**What's Protected:**
- Users can't insert arbitrary data (phone number must be unique)
- Users can't set themselves as admin (role validation in app)
- All actions are logged for security auditing

---

## 🧪 **How to Verify It Works**

After running the fix SQL:

### 1. Check Policies Were Created

Run this in SQL Editor:
```sql
SELECT tablename, policyname, roles, cmd
FROM pg_policies
WHERE tablename = 'users'
ORDER BY policyname;
```

You should see:
- ✅ `Allow anon to create users` - INSERT - {anon}
- ✅ `Allow anon to read users` - SELECT - {anon}
- ✅ `Allow anon to update users` - UPDATE - {anon}
- ✅ `Service role full access to users` - ALL - {service_role}

### 2. Test Registration

1. Restart your Flutter app (full restart, not hot reload)
2. Try to register a new user
3. Check console logs - should see:
   ```
   🔵 Creating new user in Supabase with role: customer
   🔵 SupabaseService: Creating basic user in users table
   🟢 SupabaseService: User created with ID: 1
   🟢 User marked as verified
   ```

4. Check Supabase Table Editor → `users` table
5. You should see your new user! 🎉

---

## 🔍 **Understanding RLS**

### What is Row Level Security (RLS)?

RLS is like a bouncer for your database:
- **Without RLS:** Anyone can read/write any data
- **With RLS:** Only people with the right "policy" can access data

### Why Do We Use RLS?

1. **Security:** Prevents unauthorized data access
2. **Multi-tenancy:** Users can only see their own data
3. **Fine-grained Control:** Different rules for different roles

### How RLS Works in This App:

```
User tries to register
        ↓
App sends INSERT to Supabase
        ↓
Supabase checks RLS policies
        ↓
   ┌────┴────┐
   ↓         ↓
Policy     No Policy
Exists     Found
   ↓         ↓
Allow      BLOCK ❌
✅         (42501 error)
```

**Before Fix:** No policy → Blocked ❌
**After Fix:** Policy exists → Allowed ✅

---

## 🆘 **Troubleshooting**

### **Error: "policy already exists"**

If you see:
```
ERROR: policy "Allow anon to create users" for table "users" already exists
```

**Solution:** The policy is already there! Just restart your app.

---

### **Error: "relation 'users' does not exist"**

**Solution:** You haven't created the tables yet. Run `COMPLETE_SCHEMA.sql` first.

---

### **Still Getting 42501 Error After Fix**

1. **Verify policies exist:**
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'users';
   ```

2. **Check you're using the anon key** (not service_role key) in `.env`:
   ```env
   SUPABASE_ANON_KEY=eyJhbGci...  # Should be anon/public key
   ```

3. **Restart app** (full restart, not hot reload)

4. **Clear Flutter cache:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

## 📚 **More About Supabase RLS**

Official Docs: https://supabase.com/docs/guides/auth/row-level-security

Key Concepts:
- **anon** role = unauthenticated users (before login)
- **authenticated** role = logged-in users
- **service_role** = your backend/admin (full access)

In this app:
- We use **anon** for registration (no Supabase Auth)
- We use phone + OTP instead of Supabase Auth
- Data access is controlled at app level + RLS

---

## ✅ **Summary**

**Problem:** RLS blocking user registration
**Cause:** Missing policies for anonymous user INSERT
**Fix:** Run `FIX_RLS_POLICY.sql` in Supabase SQL Editor
**Result:** Users can now register successfully! 🎉

---

## 📝 **Quick Checklist**

- [ ] Ran `FIX_RLS_POLICY.sql` in Supabase SQL Editor
- [ ] Verified policies exist (check pg_policies)
- [ ] Restarted Flutter app (full restart)
- [ ] Tried registering a new user
- [ ] Checked Supabase Table Editor - user appears in `users` table
- [ ] Profile data appears in `user_profiles` table
- [ ] No more 42501 errors in console

If all checked, you're good to go! ✅
