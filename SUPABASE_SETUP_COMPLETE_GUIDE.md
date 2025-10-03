# Supabase Setup Complete Guide 🚀

## Overview
Your Berner Super App now integrates with Supabase for:
- ✅ User authentication (external OTP via text.lk)
- ✅ User profiles
- ✅ Profile pictures storage
- ✅ Expenses tracking
- ✅ Expense receipts storage

## ⚠️ REQUIRED: Storage Buckets Setup

You **MUST** create these storage buckets in Supabase before the app will work fully:

### 1. profile-pictures Bucket
**For:** User profile pictures

### 2. expense-receipts Bucket
**For:** Expense receipts and mileage images

---

## Quick Setup (5 minutes)

### Step 1: Create Storage Buckets

1. **Go to Supabase Dashboard**
   - URL: https://app.supabase.com
   - Select your project: `ompqyjdrfnjdxqavslhg`

2. **Create First Bucket: profile-pictures**
   - Click **Storage** in left sidebar
   - Click **New Bucket**
   - Name: `profile-pictures`
   - ✅ Check **"Public bucket"**
   - Click **Create**

3. **Create Second Bucket: expense-receipts**
   - Click **New Bucket** again
   - Name: `expense-receipts`
   - ✅ Check **"Public bucket"**
   - Click **Create**

### Step 2: Add RLS Policies

1. **Go to SQL Editor**
   - Click **SQL Editor** in left sidebar
   - Click **New Query**

2. **Copy and Run This SQL:**

```sql
-- RLS Policies for Storage Buckets

-- Profile Pictures Bucket
CREATE POLICY "Allow all operations on profile-pictures"
  ON storage.objects
  FOR ALL
  TO anon, authenticated
  USING (bucket_id = 'profile-pictures')
  WITH CHECK (bucket_id = 'profile-pictures');

-- Expense Receipts Bucket
CREATE POLICY "Allow all operations on expense-receipts"
  ON storage.objects
  FOR ALL
  TO anon, authenticated
  USING (bucket_id = 'expense-receipts')
  WITH CHECK (bucket_id = 'expense-receipts');

-- Done!
SELECT 'Storage buckets configured successfully!' as message;
```

3. **Click "Run"**
   - Should see success message

### Step 3: Verify Setup

Run this verification query:

```sql
-- Verify buckets exist
SELECT id, name, public
FROM storage.buckets
WHERE id IN ('profile-pictures', 'expense-receipts');

-- Should return 2 rows with public = true
```

---

## What's Working Now

### ✅ User Authentication
- Phone number + OTP via text.lk
- User registration with profile setup
- Session management
- **File:** [RLS_FOR_EXTERNAL_OTP.sql](berner_super_app/database/RLS_FOR_EXTERNAL_OTP.sql)

### ✅ User Profiles
- Create/update profile
- NIC, DOB, Gender fields
- Profile picture upload to Supabase Storage
- **Docs:** [PROFILE_PICTURE_UPLOAD_COMPLETE.md](berner_super_app/PROFILE_PICTURE_UPLOAD_COMPLETE.md)

### ✅ Expense Tracking
- Create expenses with amount, category, description
- Upload receipt images
- Upload mileage images
- View expense history
- **Docs:** [EXPENSE_SUPABASE_INTEGRATION.md](berner_super_app/EXPENSE_SUPABASE_INTEGRATION.md)

---

## Testing Checklist

### Test Profile Picture Upload
1. ✅ Open app
2. ✅ Navigate to Profile → Edit
3. ✅ Tap profile picture
4. ✅ Select image from gallery
5. ✅ Click Save (checkmark icon)
6. ✅ Check logs for:
   ```
   🟢 SupabaseService: Profile picture uploaded successfully
   🟢 SupabaseService: Public URL: https://...
   ```
7. ✅ Verify in Supabase Dashboard → Storage → profile-pictures

### Test Expense Creation
1. ✅ Open app
2. ✅ Navigate to Expense page
3. ✅ Fill form (amount, category, description)
4. ✅ Attach receipt image
5. ✅ Click Submit
6. ✅ Check logs for:
   ```
   🟢 SupabaseService: Expense created with ID: X
   🟢 SupabaseService: Expense receipt uploaded successfully
   ```
7. ✅ Verify in Supabase Dashboard → Table Editor → expenses

### Test Expense History
1. ✅ Close and reopen app
2. ✅ Navigate to Expense page
3. ✅ Scroll to "Recent Uploads"
4. ✅ Should see previously created expenses
5. ✅ Check logs for:
   ```
   🟢 ExpensePage: Loaded X expenses
   ```

---

## File Structure

```
berner_super_app/
├── lib/
│   ├── services/
│   │   ├── supabase_service.dart    ✅ All Supabase operations
│   │   ├── auth_service.dart         ✅ Authentication logic
│   │   └── storage_diagnostic.dart   🔧 Diagnostic tool
│   ├── screens/
│   │   ├── profile_page.dart         ✅ Profile with upload
│   │   ├── expense_page.dart         ✅ Expense with upload
│   │   └── auth/
│   │       └── profile_setup_page.dart  ✅ Initial setup
│   └── config/
│       └── app_config.dart           ✅ API keys (dart-define ready)
├── database/
│   ├── COMPLETE_SCHEMA.sql           📋 Full database schema
│   ├── RLS_FOR_EXTERNAL_OTP.sql      🔐 RLS policies
│   └── SETUP_STORAGE_BUCKET.md       📖 Storage setup guide
├── android/
│   └── app/src/main/AndroidManifest.xml  ✅ INTERNET permission added
├── EXPENSE_SUPABASE_INTEGRATION.md   📖 Expense docs
├── PROFILE_PICTURE_UPLOAD_COMPLETE.md 📖 Profile pic docs
├── QUICK_FIX_PROFILE_PICTURE.md      🔧 Troubleshooting
├── RELEASE_BUILD_GUIDE.md            📦 Production build guide
└── build_release.bat                 🔨 Build script (Windows)
```

---

## Troubleshooting

### "Bucket not found" Error
```
❌ Error: The resource you requested could not be found
```
**Fix:** Create the storage buckets (Step 1 above)

---

### Profile Picture Not Uploading
**Symptoms:** Image selected but not saved

**Fix:**
1. Verify `profile-pictures` bucket exists
2. Check bucket is marked as **Public**
3. Verify RLS policy allows anon uploads
4. Check internet connection

---

### Expense Not Saving
**Symptoms:** "Error creating expense" message

**Fix:**
1. Verify user is logged in
2. Check `expenses` table exists in database
3. Verify RLS policies in [RLS_FOR_EXTERNAL_OTP.sql](berner_super_app/database/RLS_FOR_EXTERNAL_OTP.sql) are applied
4. Check logs for specific error

---

### Expense Receipt Not Uploading
**Symptoms:** Expense created but no image

**Fix:**
1. Create `expense-receipts` bucket (Step 1 above)
2. Set bucket to Public
3. Add RLS policies (Step 2 above)
4. Check internet connection

---

### Data Not Showing After Restart
**Symptoms:** Profile/expenses disappear on app restart

**Possible Causes:**
1. Not saving to Supabase (check logs)
2. RLS policies blocking reads
3. Internet connection issue

**Fix:**
1. Check logs for save confirmation
2. Verify RLS policies allow SELECT
3. Test with mobile data vs WiFi

---

## Security Configuration

### Current Setup (Development)
- ✅ Anonymous users can:
  - Register and login
  - Create/update profiles
  - Upload profile pictures
  - Create expenses
  - Upload receipts
  - View their data

### For Production
See individual docs for production security recommendations:
- [RLS_FOR_EXTERNAL_OTP.sql](berner_super_app/database/RLS_FOR_EXTERNAL_OTP.sql) - Auth policies
- [EXPENSE_SUPABASE_INTEGRATION.md](berner_super_app/EXPENSE_SUPABASE_INTEGRATION.md) - Expense security

---

## Build for Release

### Development Build (uses .env)
```bash
flutter run
```

### Release Build (uses --dart-define)
```bash
# Windows
build_release.bat

# Or manually
flutter build apk --release \
  --dart-define=SUPABASE_URL=your-url \
  --dart-define=SUPABASE_ANON_KEY=your-key \
  --dart-define=TEXTLK_API_TOKEN=your-token
```

**Full guide:** [RELEASE_BUILD_GUIDE.md](berner_super_app/RELEASE_BUILD_GUIDE.md)

---

## API Keys Location

### Development (.env file)
```
berner_super_app/.env
```

### Production (--dart-define)
Pass via command line or CI/CD secrets

**Never commit:**
- `.env` file
- API keys
- Service role keys

---

## Support Resources

| Issue | Documentation |
|-------|--------------|
| Storage bucket setup | [SETUP_STORAGE_BUCKET.md](berner_super_app/database/SETUP_STORAGE_BUCKET.md) |
| Profile pictures | [PROFILE_PICTURE_UPLOAD_COMPLETE.md](berner_super_app/PROFILE_PICTURE_UPLOAD_COMPLETE.md) |
| Expenses | [EXPENSE_SUPABASE_INTEGRATION.md](berner_super_app/EXPENSE_SUPABASE_INTEGRATION.md) |
| RLS policies | [RLS_FOR_EXTERNAL_OTP.sql](berner_super_app/database/RLS_FOR_EXTERNAL_OTP.sql) |
| Release builds | [RELEASE_BUILD_GUIDE.md](berner_super_app/RELEASE_BUILD_GUIDE.md) |
| Profile picture fix | [QUICK_FIX_PROFILE_PICTURE.md](QUICK_FIX_PROFILE_PICTURE.md) |

---

## Summary

### ✅ Completed
- User authentication with external OTP
- Profile management with picture upload
- Expense tracking with receipt upload
- Database integration
- Storage integration
- RLS policies configured
- Android INTERNET permission added
- Release build scripts created

### ⚠️ Required Before Use
- Create `profile-pictures` storage bucket
- Create `expense-receipts` storage bucket
- Add RLS policies to storage buckets

### 📝 Optional Improvements
- Add expense editing/deletion
- Add expense approval workflow
- Add profile picture to Supabase Storage (instead of local)
- Implement proper authentication with Supabase Auth
- Add offline support
- Add data sync
- Add push notifications

---

**Status**: ✅ Development Complete - Storage buckets required
**Last Updated**: 2025-10-02
**Flutter Version**: 3.35.2
**Supabase Project**: ompqyjdrfnjdxqavslhg
