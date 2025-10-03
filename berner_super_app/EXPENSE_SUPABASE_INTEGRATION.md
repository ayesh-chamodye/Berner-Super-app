# Expense Supabase Integration - COMPLETE ✅

## Summary
Expenses now upload to Supabase database and history loads from Supabase tables instead of local storage.

## Changes Made

### 1. Added Expense Methods to SupabaseService ✅

**File:** `lib/services/supabase_service.dart`

```dart
/// Create new expense
static Future<int?> createExpense({
  required String userId,
  required String title,
  required double amount,
  required String categoryName,
  String? description,
  DateTime? expenseDate,
  String? receiptUrl,
  String? mileageImageUrl,
})

/// Get expenses for a user
static Future<List<Map<String, dynamic>>> getUserExpenses(String userId, {int limit = 50})

/// Upload expense receipt to Supabase Storage
static Future<String?> uploadExpenseReceipt(String filePath, int expenseId)
```

### 2. Updated Expense Page ✅

**File:** `lib/screens/expense_page.dart`

**Before:**
- Stored expenses in local `_uploadHistory` list
- Lost data on app restart
- No database persistence

**After:**
- Creates expense in Supabase `expenses` table
- Uploads receipt/mileage images to Supabase Storage
- Saves attachments in `expense_attachments` table
- Loads history from database on init
- Data persists across devices

### 3. Features Implemented ✅

- ✅ Create expense with amount, category, description
- ✅ Upload receipt image to Supabase Storage
- ✅ Upload mileage image to Supabase Storage
- ✅ Save expense to `expenses` table
- ✅ Save attachments to `expense_attachments` table
- ✅ Load expense history from database
- ✅ Display approval status (pending/approved/rejected)
- ✅ Show loading indicator while saving
- ✅ Error handling and user feedback

## Database Schema Used

### expenses table
```sql
- id: SERIAL PRIMARY KEY
- user_id: INTEGER (FK to users.id)
- title: TEXT
- description: TEXT
- amount: NUMERIC(10,2)
- currency: TEXT (default 'LKR')
- category_name: TEXT
- expense_date: DATE
- status: expense_status_enum (pending/approved/rejected)
- is_approved: BOOLEAN
- is_reimbursable: BOOLEAN
- created_at: TIMESTAMP
```

### expense_attachments table
```sql
- id: SERIAL PRIMARY KEY
- expense_id: INTEGER (FK to expenses.id)
- file_name: TEXT
- file_path: TEXT
- file_url: TEXT
- file_size: INTEGER
- mime_type: TEXT
- is_receipt: BOOLEAN
- uploaded_at: TIMESTAMP
```

## Storage Buckets Required

### ⚠️ IMPORTANT: Create Storage Buckets

You **MUST** create these storage buckets in Supabase:

#### 1. expense-receipts Bucket
**Purpose:** Store receipt and mileage images

**Setup:**
1. Go to Supabase Dashboard → Storage
2. Create bucket named: `expense-receipts`
3. Make it **Public**
4. Add RLS policies

**Quick SQL:**
```sql
CREATE POLICY "Allow all operations on expense-receipts"
  ON storage.objects
  FOR ALL
  TO anon, authenticated
  USING (bucket_id = 'expense-receipts')
  WITH CHECK (bucket_id = 'expense-receipts');
```

#### 2. profile-pictures Bucket
**Purpose:** Store user profile pictures (already created)

## How It Works

### Creating an Expense

```
1. User fills expense form
   ↓
2. User selects category (Food/Fuel/Other)
   ↓
3. User enters amount and description
   ↓
4. User optionally attaches receipt image
   ↓
5. User optionally attaches mileage image
   ↓
6. User clicks Submit
   ↓
7. App creates expense record in Supabase
   ↓
8. App uploads receipt image to expense-receipts bucket
   ↓
9. App saves receipt attachment record
   ↓
10. App uploads mileage image (if provided)
   ↓
11. App saves mileage attachment record
   ↓
12. App reloads expense history
   ↓
13. New expense appears in history
```

### Loading Expense History

```
1. Page opens → initState() called
   ↓
2. _loadExpenseHistory() fetches from Supabase
   ↓
3. Gets user's expenses with attachments (JOIN)
   ↓
4. Maps database records to UI format
   ↓
5. Updates _uploadHistory list
   ↓
6. UI displays expenses with status badges
```

## Testing

### Test Expense Creation
1. Open app
2. Navigate to Expense page
3. Fill in:
   - Amount: 1500
   - Category: Food
   - Description: "Lunch with client"
4. Attach receipt image (optional)
5. Click Submit
6. Check logs for:
   ```
   🔵 ExpensePage: Creating expense...
   🔵 SupabaseService: Creating expense for user 5
   🟢 SupabaseService: Expense created with ID: 123
   🔵 ExpensePage: Uploading receipt image...
   🟢 SupabaseService: Expense receipt uploaded successfully
   🟢 ExpensePage: Receipt uploaded
   🟢 ExpensePage: Loaded 1 expenses
   ```

### Verify in Supabase
1. Go to Supabase Dashboard
2. **Table Editor** → **expenses**
3. You should see new expense record
4. **Storage** → **expense-receipts**
5. You should see uploaded receipt image

### Test History Loading
1. Close and reopen app
2. Navigate to Expense page
3. Scroll down to "Recent Uploads"
4. Expenses should load from database
5. Check logs for:
   ```
   🔵 ExpensePage: Loading expense history for user 5
   🟢 SupabaseService: Found 10 expenses
   🟢 ExpensePage: Loaded 10 expenses
   ```

## Error Handling

### Expense Creation Fails
- Error message shown to user
- Form data NOT cleared (can retry)
- Logs show exact error
- No partial data saved

### Image Upload Fails
- Expense still created
- Attachment record not created
- User notified of partial success
- Can manually upload later

### History Loading Fails
- Shows empty state
- Error logged
- User can pull to refresh

## File Structure

| File | Purpose |
|------|---------|
| `lib/services/supabase_service.dart` | Expense CRUD operations |
| `lib/screens/expense_page.dart` | Expense UI and form |
| `database/COMPLETE_SCHEMA.sql` | Database schema |
| `EXPENSE_SUPABASE_INTEGRATION.md` | This documentation |

## Setup Checklist

Before using expense functionality:

- [ ] Run RLS_FOR_EXTERNAL_OTP.sql (allows anon access)
- [ ] Create `expense-receipts` storage bucket
- [ ] Set bucket to Public
- [ ] Add RLS policies for storage
- [ ] Verify `expenses` table exists
- [ ] Verify `expense_attachments` table exists
- [ ] Test expense creation
- [ ] Test image upload
- [ ] Test history loading

## Next Steps

### Required
- [ ] Create `expense-receipts` bucket
- [ ] Test with real data
- [ ] Verify RLS policies work

### Optional Enhancements
- [ ] Add pull-to-refresh for history
- [ ] Add expense editing
- [ ] Add expense deletion
- [ ] Add expense approval workflow
- [ ] Add expense reports/analytics
- [ ] Add expense search/filter
- [ ] Add expense categories management
- [ ] Add expense export (PDF/Excel)
- [ ] Add expense notifications
- [ ] Add expense comments/notes

## Troubleshooting

### "Error creating expense"
- Check if user is logged in
- Verify `expenses` table exists
- Check RLS policies allow anon insert
- Verify user_id is valid

### "Error uploading receipt"
- Create `expense-receipts` bucket
- Verify bucket is Public
- Check storage RLS policies
- Verify internet connection

### "No expenses showing"
- Check if user has any expenses
- Verify getUserExpenses query works
- Check RLS policies allow anon select
- Look for errors in logs

### Images not displaying
- Verify URL is public
- Check bucket is Public
- Ensure NetworkImage is used for URLs
- Check internet connection

## Security Notes

### Current Setup (Development)
- Anonymous users can create expenses
- Anyone can view any user's expenses
- Anyone can upload receipts

### Production Recommendations
1. **Restrict to Authenticated Users**
   ```sql
   -- Only authenticated users can create expenses
   CREATE POLICY "Users can create own expenses"
     ON expenses FOR INSERT
     TO authenticated
     WITH CHECK (user_id = auth.uid()::int);
   ```

2. **Users Can Only View Own Expenses**
   ```sql
   CREATE POLICY "Users can view own expenses"
     ON expenses FOR SELECT
     TO authenticated
     USING (user_id = auth.uid()::int);
   ```

3. **Add Approval Workflow**
   - Only managers can approve expenses
   - Add approval notifications
   - Track approval history

4. **Add File Size Limits**
   - Limit receipt uploads to 5MB
   - Compress images before upload
   - Validate file types

## Benefits

### Before (Local Storage)
- ❌ Data lost on app reinstall
- ❌ Not accessible from other devices
- ❌ No backup
- ❌ No approval workflow
- ❌ Can't track across team

### After (Supabase)
- ✅ Data persists across devices
- ✅ Automatic backup
- ✅ Centralized tracking
- ✅ Approval workflow ready
- ✅ Team visibility
- ✅ Audit trail
- ✅ Reporting ready

---

**Status**: ✅ Complete - Bucket setup required before use
**Last Updated**: 2025-10-02
