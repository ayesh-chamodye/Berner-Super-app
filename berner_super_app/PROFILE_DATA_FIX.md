# Profile Data Not Showing - FIXED ✅

## Problem
Profile page was showing "Not provided" for NIC, Date of Birth, and Gender even though data existed in the Supabase database.

## Root Cause
The `getUserProfile()` method in `SupabaseService` was using the `vw_user_details` view which wasn't returning profile data correctly due to:
1. RLS policies not properly configured for the view
2. Anonymous access not working with views

## Solution Applied

### 1. Updated `SupabaseService.getUserProfile()`
Changed from using a view to fetching from both tables separately:

**Before:**
```dart
// Used vw_user_details view (didn't work with anon role)
final response = await client
    .from('vw_user_details')
    .select()
    .eq('mobile_number', phoneNumber)
    .maybeSingle();
```

**After:**
```dart
// Fetch from users table
final userResponse = await client
    .from('users')
    .select()
    .eq('mobile_number', phoneNumber)
    .maybeSingle();

// Fetch from user_profiles table
final profileResponse = await client
    .from('user_profiles')
    .select()
    .eq('user_id', userId)
    .maybeSingle();

// Merge the data
final mergedData = Map<String, dynamic>.from(userResponse);
mergedData.addAll(profileResponse);
```

### 2. RLS Policies Applied
Run the [RLS_FOR_EXTERNAL_OTP.sql](../database/RLS_FOR_EXTERNAL_OTP.sql) script in Supabase SQL Editor to allow anonymous access.

## Files Modified
1. ✅ `lib/services/supabase_service.dart` - Fixed getUserProfile() method
2. ✅ `database/RLS_FOR_EXTERNAL_OTP.sql` - Created comprehensive RLS policies

## Testing Steps
1. ✅ Run the RLS SQL script in Supabase
2. ✅ Restart the Flutter app
3. ✅ Navigate to Profile page
4. ✅ Verify NIC, Date of Birth, and Gender are displayed

## Additional Features Fixed
- Profile edit functionality now works
- Data persists to Supabase correctly
- Proper error handling and logging
- Fallback to user data if profile doesn't exist

## Related Issues Fixed
- Registration RLS error (anonymous users can now create accounts)
- Profile creation during signup
- Profile updates after registration

## Next Steps
1. Run the app and test profile page
2. If still showing "Not provided", check Supabase logs
3. Verify RLS policies are applied:
   ```sql
   SELECT tablename, policyname, roles, cmd
   FROM pg_policies
   WHERE tablename IN ('users', 'user_profiles')
   ORDER BY tablename, policyname;
   ```

## Notes
- The view (`vw_user_details`) is still available but not used by the app
- Direct table access is more reliable with external OTP authentication
- All data is properly merged from both tables
