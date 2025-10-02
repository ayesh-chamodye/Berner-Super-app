# Berner Super App - Database Setup

This directory contains SQL scripts for setting up the Berner Super App database in Supabase.

## Overview

The database uses **auto-generated numeric UIDs** (BIGSERIAL) instead of Supabase Auth UUIDs, allowing for custom OTP-based authentication via text.lk SMS API.

## Files

1. **01_init_schema.sql** - Main database schema with all tables, indexes, and policies
2. **02_helper_functions.sql** - Helper functions for common operations
3. **03_sample_data.sql** - Sample data for testing (development only)

## Database Schema

### Tables

#### 1. **users** (Primary user table)
- `id` (BIGSERIAL) - Auto-generated numeric user ID
- `mobile_number` (VARCHAR) - Unique phone number for login
- `adm_code` (VARCHAR) - Auto-generated admin code for employees (ADM25XXXXXX)
- `role` (VARCHAR) - 'employee' or 'owner'
- Profile fields: name, nic, date_of_birth, gender, profile_picture_path
- Status fields: is_verified, is_active
- Timestamps: created_at, updated_at, last_login_at

#### 2. **otp_logs** (OTP attempt tracking)
- Logs all OTP attempts for security monitoring
- Includes phone, success status, error messages, IP, user agent

#### 3. **expenses** (Expense records)
- User expenses with approval workflow
- References users.id (numeric)
- Includes title, description, amount, category, expense_date
- Approval tracking: is_approved, approved_by, approved_at

#### 4. **user_sessions** (Session management)
- Tracks user login sessions
- Session tokens, device info, IP tracking
- Expiry and activity timestamps

#### 5. **notifications** (In-app notifications)
- User notifications with read status
- Can link to related entities (expenses, users, etc.)

#### 6. **app_settings** (Application settings)
- Key-value store for app-wide settings
- Public/private flag for access control

## Setup Instructions

### Step 1: Access Supabase SQL Editor

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor** in the left sidebar
3. Click **New Query**

### Step 2: Run Schema Script

1. Open `01_init_schema.sql`
2. Copy the entire contents
3. Paste into Supabase SQL Editor
4. Click **Run** or press `Ctrl+Enter`
5. Wait for completion (should show success message)

### Step 3: Run Helper Functions

1. Open `02_helper_functions.sql`
2. Copy the entire contents
3. Paste into Supabase SQL Editor
4. Click **Run**
5. Verify all functions are created successfully

### Step 4: (Optional) Insert Sample Data

**⚠️ Only for development/testing environments**

1. Open `03_sample_data.sql`
2. Copy the entire contents
3. Paste into Supabase SQL Editor
4. Click **Run**
5. Check the output for summary of inserted data

### Step 5: Verify Installation

Run this query to verify everything is set up correctly:

```sql
-- Check tables
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Check functions
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'public'
ORDER BY routine_name;

-- Check sample data (if inserted)
SELECT
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM expenses) as total_expenses,
    (SELECT COUNT(*) FROM otp_logs) as total_otp_logs;
```

## Key Features

### Auto-Generated Numeric UIDs

Unlike Supabase Auth which uses UUIDs, this schema uses `BIGSERIAL` for user IDs:

```sql
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,  -- Auto-incrementing numeric ID
    mobile_number VARCHAR(15) UNIQUE NOT NULL,
    ...
);
```

### ADM Code Generation

Employees automatically get an ADM code in format `ADM25XXXXXX`:

```sql
-- Use the helper function
SELECT generate_adm_code();
-- Returns: ADM25123456
```

### OTP Rate Limiting

Built-in rate limiting to prevent abuse:

```sql
-- Check if phone can request OTP (max 5 attempts per hour)
SELECT check_otp_rate_limit('0771234567', 60, 5);
```

## Helper Functions Reference

### User Management

- `generate_adm_code()` - Generates unique ADM code for employees
- `get_user_by_mobile(phone)` - Retrieves user by mobile number
- `upsert_user(...)` - Creates or updates user profile
- `update_user_last_login(user_id)` - Updates last login timestamp

### OTP Management

- `log_otp_attempt(...)` - Logs OTP attempt
- `check_otp_rate_limit(phone, minutes, max_attempts)` - Checks rate limit
- `clean_old_otp_logs(days_old)` - Cleans old OTP logs

### Expense Management

- `create_expense(...)` - Creates new expense
- `approve_expense(expense_id, approved_by)` - Approves expense
- `get_user_expenses_summary(user_id, start_date, end_date)` - Gets expense summary

### Notification Management

- `create_notification(...)` - Creates notification
- `mark_notification_read(notification_id)` - Marks notification as read
- `mark_all_notifications_read(user_id)` - Marks all user notifications as read

### Statistics

- `get_app_statistics()` - Returns overall app statistics

## Example Queries

### Create a new employee

```sql
SELECT upsert_user(
    '0771234567',           -- mobile_number
    'employee',             -- role
    'John Doe',            -- name
    '199012345678',        -- nic
    '1990-05-15',          -- date_of_birth
    'male'                 -- gender
);
```

### Get user by mobile number

```sql
SELECT * FROM get_user_by_mobile('0771234567');
```

### Create an expense

```sql
SELECT create_expense(
    1,                      -- user_id
    'Office Supplies',      -- title
    'Pens and papers',      -- description
    1500.00,               -- amount
    'office',              -- category
    CURRENT_DATE,          -- expense_date
    NULL                   -- receipt_path
);
```

### Get user expense summary

```sql
SELECT * FROM get_user_expenses_summary(
    1,                      -- user_id
    '2025-01-01',          -- start_date
    '2025-12-31'           -- end_date
);
```

## Row Level Security (RLS)

RLS is enabled on all tables with policies configured for:
- Service role (full access)
- Anonymous users (limited access for OTP flow)
- Authenticated users (own data access)

**Note:** Since we're not using Supabase Auth, your app needs to:
1. Use the `service_role` key for backend operations
2. Implement custom authentication logic
3. Pass user context explicitly in queries

## Maintenance

### Clean old OTP logs (run periodically)

```sql
SELECT clean_old_otp_logs(30);  -- Delete logs older than 30 days
```

### Backup before updates

Always backup your database before running updates:

```bash
# In Supabase dashboard:
# Database → Backups → Create backup
```

## Security Notes

1. **Never commit .env file** with real credentials
2. **Use service_role key** only on backend/server
3. **Implement rate limiting** in your app for OTP requests
4. **Monitor otp_logs table** for suspicious activity
5. **Regularly clean old logs** to save space

## Troubleshooting

### Error: relation already exists

If you get this error, tables already exist. Either:
- Drop existing tables first (⚠️ will delete data)
- Or skip to the next script

### Error: permission denied

Make sure you're using the SQL Editor in Supabase dashboard with appropriate permissions.

### Functions not working

Verify functions were created:

```sql
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public';
```

## Support

For issues or questions:
- Check Supabase documentation: https://supabase.com/docs
- Review the SQL scripts for comments
- Test queries in SQL Editor before using in app

---

**Last Updated:** 2025-10-01
**Version:** 1.0.0
