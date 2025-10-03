# Quick Fix: Profile Picture Upload Not Working

## 🔴 Most Likely Problem

**The Supabase Storage bucket doesn't exist yet!**

## ✅ Quick Fix (2 minutes)

### Step 1: Create the Bucket

1. Go to **[Supabase Dashboard](https://app.supabase.com)**
2. Select your project
3. Click **Storage** in the left sidebar
4. Click **"New Bucket"** button
5. Enter these details:
   - **Name**: `profile-pictures` (exactly this, with hyphen)
   - **Public bucket**: ✅ **CHECK THIS BOX** (very important!)
   - Click **"Create Bucket"**

### Step 2: Allow Anonymous Upload

After creating the bucket, you need to allow uploads:

1. Still in Storage section
2. Click on `profile-pictures` bucket
3. Click **"Policies"** tab
4. Click **"New Policy"**
5. Click **"For full customization"** (not templates)
6. Fill in:
   - **Policy name**: `Allow all operations`
   - **Allowed operation**: Select **ALL** (SELECT, INSERT, UPDATE, DELETE)
   - **Target roles**: `anon`, `authenticated`
   - **USING expression**: Leave blank or type `true`
   - **WITH CHECK expression**: Leave blank or type `true`
7. Click **"Save policy"**

**Or use this quick SQL (faster):**

```sql
CREATE POLICY "Allow all operations on profile-pictures"
  ON storage.objects
  FOR ALL
  TO anon, authenticated
  USING (bucket_id = 'profile-pictures')
  WITH CHECK (bucket_id = 'profile-pictures');
```

### Step 3: Test in Your App

1. Run your app
2. Go to Profile → Edit
3. Select a profile picture
4. Click Save
5. Check logs for success message

## Common Errors & Solutions

### Error: "Bucket not found"
```
❌ Error: The resource you requested could not be found
```

**Fix**: Create the bucket (Step 1 above)

---

### Error: "new row violates policy"
```
❌ Error: new row violates row-level security policy for table "objects"
```

**Fix**: Add the policy (Step 2 above)

---

### Error: "Permission denied"
```
❌ Error: PermissionDenied
```

**Fix**: Make sure bucket is marked as **Public** and policy allows `anon` role

---

## How to Verify It's Working

### In App Logs
You should see:
```
🔵 ProfilePage: Uploading profile picture to Supabase...
🔵 SupabaseService: Uploading profile picture for user 5
🟢 SupabaseService: Profile picture uploaded successfully
🟢 SupabaseService: Public URL: https://ompqyjdrfnjdxqavslhg.supabase.co/storage/v1/object/public/profile-pictures/profile_pictures/profile_5.jpg
🟢 ProfilePage: Profile picture uploaded successfully
```

### In Supabase Dashboard
1. Go to **Storage** → **profile-pictures**
2. You should see a folder: `profile_pictures`
3. Inside, files like: `profile_5.jpg`, `profile_12.png`

---

##Still Not Working?

### Check These:

1. **Internet connection** - Device must be online
2. **Bucket name** - Must be exactly `profile-pictures` (with hyphen, not underscore)
3. **Public bucket** - Checkbox must be checked
4. **RLS policy** - Must allow `anon` role
5. **Supabase project** - Must not be paused (free tier)

### Get Detailed Error:

Check your Flutter console/logcat for the exact error message. Look for lines with:
- `❌ SupabaseService: Error uploading profile picture:`
- The error message will tell you exactly what's wrong

---

## Alternative: Use Local Storage (Temporary)

If you can't set up Supabase Storage right now, the app will fallback to local storage automatically. The profile picture will be stored on the device only (won't sync across devices).

This is fine for testing, but for production you should use Supabase Storage.

---

**TL;DR:**
1. Create bucket named `profile-pictures`
2. Make it **Public**
3. Add policy allowing `anon` uploads
4. Done! ✅
