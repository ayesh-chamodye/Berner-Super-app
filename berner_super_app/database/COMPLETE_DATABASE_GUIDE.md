

# 🗄️ Berner Super App - Complete Database Guide

## Overview

This is the **complete production database** for Berner Super App with:
- ✅ **No Supabase Auth dependency** - Phone-based authentication via text.lk
- ✅ **Auto-generated numeric user IDs** - BIGSERIAL primary keys
- ✅ **Full expense management** - Approval workflow, categories, attachments
- ✅ **Comprehensive audit trail** - Activity logs, OTP logs, session tracking
- ✅ **Rich user profiles** - Extended information with preferences
- ✅ **Notification system** - In-app notifications with multiple channels
- ✅ **Row Level Security** - Proper RLS policies configured

---

## 📁 Database Files

### Main Schema Files

1. **[COMPLETE_SCHEMA.sql](COMPLETE_SCHEMA.sql)** - Complete database schema
   - 12 main tables
   - Views for common queries
   - Triggers for automatic updates
   - Row Level Security policies
   - Default settings and categories

2. **[02_helper_functions.sql](02_helper_functions.sql)** - Basic helper functions
   - User management (create, update, ADM codes)
   - OTP management (logging, rate limiting)
   - Expense operations (create, approve)
   - Statistics functions

3. **[04_advanced_functions.sql](04_advanced_functions.sql)** - Advanced operations
   - Complex expense workflows
   - Bulk notifications
   - Session management
   - Dashboard statistics
   - Maintenance utilities

4. **[03_sample_data.sql](03_sample_data.sql)** - Test data (optional)

---

## 📊 Database Structure

### Core Tables

#### 1. **users** - Core Authentication
```sql
- id (BIGSERIAL) - Auto-generated numeric ID
- mobile_number (VARCHAR) - Unique phone number
- role (VARCHAR) - employee, owner, admin, customer
- adm_code (VARCHAR) - Auto-generated for employees (ADM25XXXXXX)
- is_verified, is_active, is_blocked
- failed_login_attempts, last_failed_login_at
- created_at, updated_at, last_login_at, deleted_at
```

**Features:**
- ✅ Phone-based authentication (no Supabase Auth)
- ✅ Auto-generated numeric IDs
- ✅ Soft delete support
- ✅ Security tracking (failed attempts)

#### 2. **user_profiles** - Extended Information
```sql
- user_id (BIGINT FK) - References users.id
- Personal: first_name, last_name, email, nic, dob, gender
- Contact: alternate_mobile, whatsapp_number
- Address: full address fields with province/city
- Employment: department, position, reporting_to
- Business: business_name, tax_id (for owners)
- Media: profile_picture_url, cover_photo_url
- Preferences: language, timezone, currency, notifications
```

**Features:**
- ✅ Separate profile for clean separation
- ✅ Reporting hierarchy support
- ✅ Notification preferences
- ✅ Business information for owners

#### 3. **otp_logs** - OTP Tracking & Security
```sql
- id (BIGSERIAL)
- phone, otp_type (login/signup/verification)
- success, error_message
- Security: ip_address, user_agent, device_info, location_data
- Provider: provider (textlk), sms_id, cost
- created_at
```

**Features:**
- ✅ Complete OTP attempt logging
- ✅ Security monitoring (IP, device, location)
- ✅ Cost tracking
- ✅ Rate limiting support

#### 4. **user_sessions** - Session Management
```sql
- id (UUID)
- user_id, session_token, refresh_token
- Device: device_id, device_name, device_type, device_os
- Connection: ip_address, user_agent, browser
- Status: is_active, expires_at, last_activity_at
- terminated_at, termination_reason
```

**Features:**
- ✅ Multi-device session tracking
- ✅ Automatic expiry
- ✅ Device fingerprinting
- ✅ Session termination tracking

#### 5. **expense_categories** - Expense Categories
```sql
- id (SERIAL)
- name, slug, description
- parent_id (for hierarchy)
- Display: icon, color, sort_order
- Rules: requires_receipt, requires_approval, max_amount
- is_active
```

**Default categories:**
- Transportation 🚗
- Meals & Entertainment 🍽️
- Office Supplies 📎
- Accommodation 🏨
- Communications 📱
- Training 📚
- Equipment ⚙️
- Marketing 📢
- Utilities ⚡
- Other 📋

#### 6. **expenses** - Main Expense Table
```sql
- id (BIGSERIAL)
- user_id, title, description, amount, currency
- category_id, expense_date, expense_time, location
- Payment: payment_method, vendor_name, vendor_contact
- Tax: tax_amount, tax_rate, is_taxable
- Status: status (draft/pending/approved/rejected/paid)
- Approval: approved_by, approved_at, approval_notes
- Rejection: rejected_by, rejected_at, rejection_reason
- Payment: is_paid, paid_at, paid_by
- Reimbursement: reimbursement_status, reimbursed_at
- Metadata: tags[], custom_fields (JSONB)
- Features: is_recurring, is_billable
- created_at, updated_at, deleted_at
```

**Features:**
- ✅ Complete expense lifecycle
- ✅ Full approval workflow
- ✅ Tax calculations
- ✅ Reimbursement tracking
- ✅ Recurring expenses
- ✅ Client billable expenses
- ✅ Soft delete

#### 7. **expense_attachments** - Receipts & Documents
```sql
- id (BIGSERIAL)
- expense_id, file_name, file_type, file_size
- file_path, file_url, storage_bucket
- is_receipt
- OCR: ocr_text, ocr_processed, ocr_confidence
```

**Features:**
- ✅ Multiple attachments per expense
- ✅ OCR support for receipt scanning
- ✅ Storage metadata

#### 8. **expense_approvals** - Approval History
```sql
- id (BIGSERIAL)
- expense_id, approver_id
- action (approved/rejected/requested_changes)
- notes, approval_level, is_final_approval
```

**Features:**
- ✅ Complete approval audit trail
- ✅ Multi-level approval support
- ✅ Approval notes

#### 9. **notifications** - In-App Notifications
```sql
- id (BIGSERIAL)
- user_id, title, message, type
- related_entity_type, related_entity_id
- action_url, action_label, priority
- is_read, read_at, is_dismissed, dismissed_at
- Delivery: sent_push, sent_email, sent_sms
- expires_at
```

**Features:**
- ✅ Multiple notification types
- ✅ Priority levels
- ✅ Action buttons
- ✅ Multi-channel delivery tracking
- ✅ Auto-expiry

#### 10. **activity_logs** - Audit Trail
```sql
- id (BIGSERIAL)
- user_id, action, entity_type, entity_id
- old_values (JSONB), new_values (JSONB)
- changes_summary
- ip_address, user_agent, device_info
- metadata (JSONB)
```

**Features:**
- ✅ Complete audit trail
- ✅ Before/after values
- ✅ Security tracking
- ✅ Flexible metadata

#### 11. **app_settings** - Configuration
```sql
- id (SERIAL)
- key, value, value_type
- description, category
- is_public, is_editable
- validation_rule, default_value
```

**Default settings:**
- App version, name, maintenance mode
- OTP settings (expiry, max attempts, rate limit)
- Expense settings (receipt requirement, auto-approval)
- Session settings (timeout, max concurrent)
- File upload settings (max size, allowed types)

#### 12. **system_logs** - System Events
```sql
- id (BIGSERIAL)
- level (debug/info/warning/error/critical)
- message, component, function_name
- error_code, error_details, stack_trace
- metadata (JSONB)
```

**Features:**
- ✅ System-level logging
- ✅ Error tracking
- ✅ Debug support

---

## 🔧 Setup Instructions

### Step 1: Run Main Schema

```sql
-- In Supabase SQL Editor
-- Copy and paste COMPLETE_SCHEMA.sql
-- Click Run (or Ctrl+Enter)
```

**Creates:**
- ✅ All 12 tables
- ✅ Indexes for performance
- ✅ Triggers for auto-updates
- ✅ Default categories
- ✅ Default settings
- ✅ RLS policies
- ✅ Views

### Step 2: Run Helper Functions

```sql
-- Copy and paste 02_helper_functions.sql
-- Click Run
```

**Creates:**
- ✅ `generate_adm_code()` - Generate employee codes
- ✅ `upsert_user()` - Create/update users
- ✅ `get_user_by_mobile()` - Get user by phone
- ✅ `check_otp_rate_limit()` - Rate limiting
- ✅ `log_otp_attempt()` - Log OTP attempts
- ✅ `create_expense()` - Create expenses
- ✅ `approve_expense()` - Approve expenses
- ✅ `get_user_expenses_summary()` - Expense stats
- ✅ And more...

### Step 3: Run Advanced Functions

```sql
-- Copy and paste 04_advanced_functions.sql
-- Click Run
```

**Creates:**
- ✅ `approve_expense_advanced()` - Full approval workflow
- ✅ `reject_expense()` - Reject with notifications
- ✅ `get_pending_expenses_for_approver()` - Approver dashboard
- ✅ `create_user_with_profile()` - Complete user creation
- ✅ `set_user_block_status()` - Block/unblock users
- ✅ `create_bulk_notification()` - Bulk notifications
- ✅ `create_user_session()` - Session management
- ✅ `validate_session()` - Session validation
- ✅ `get_dashboard_stats()` - Dashboard data
- ✅ `system_health_check()` - Health monitoring
- ✅ Maintenance utilities

### Step 4: (Optional) Insert Sample Data

```sql
-- Copy and paste 03_sample_data.sql
-- Click Run
-- ⚠️ Development/testing only!
```

---

## 📝 Common Operations

### User Management

#### Create User
```sql
SELECT create_user_with_profile(
    '0771234567',           -- mobile_number
    'employee',             -- role
    'John',                 -- first_name
    'Doe',                  -- last_name
    'john@example.com',     -- email
    '199012345678'          -- nic
);
```

#### Get User Details
```sql
SELECT * FROM vw_user_details
WHERE mobile_number = '0771234567';
```

#### Block User
```sql
SELECT set_user_block_status(
    1,                      -- user_id
    true,                   -- is_blocked
    'Suspicious activity',  -- reason
    2                       -- admin_id
);
```

### Expense Management

#### Create Expense
```sql
SELECT create_expense(
    1,                      -- user_id
    'Client Lunch',         -- title
    'Business lunch with ABC Corp',  -- description
    3500.00,               -- amount
    'meals-entertainment',  -- category
    CURRENT_DATE,          -- expense_date
    NULL                   -- receipt_path (optional)
);
```

#### Approve Expense
```sql
SELECT approve_expense_advanced(
    1,                      -- expense_id
    2,                      -- approver_id
    'Approved for payment' -- notes
);
```

#### Reject Expense
```sql
SELECT reject_expense(
    1,                      -- expense_id
    2,                      -- rejector_id
    'Missing receipt'       -- reason
);
```

#### Get User Expense Statistics
```sql
SELECT get_user_expense_stats(
    1,                      -- user_id
    '2025-01-01',          -- start_date
    '2025-12-31'           -- end_date
);
```

#### Get Expenses by Category
```sql
SELECT * FROM get_expenses_by_category(
    1,                      -- user_id (NULL for all)
    '2025-01-01',          -- start_date
    CURRENT_DATE           -- end_date
);
```

### Session Management

#### Create Session
```sql
SELECT create_user_session(
    1,                      -- user_id
    '{"device": "iPhone 13", "os": "iOS 16"}'::jsonb,  -- device_info
    '192.168.1.1'::inet,   -- ip_address
    60                      -- session_duration_minutes
);
```

#### Validate Session
```sql
SELECT validate_session('your-session-token-here');
```

### Notifications

#### Create Notification
```sql
INSERT INTO notifications (user_id, title, message, type, priority)
VALUES (1, 'Important Update', 'Your expense has been approved', 'success', 'high');
```

#### Bulk Notification
```sql
SELECT create_bulk_notification(
    ARRAY[1, 2, 3, 4, 5],  -- user_ids
    'System Maintenance',   -- title
    'Scheduled maintenance tonight',  -- message
    'warning'               -- type
);
```

#### Mark All as Read
```sql
SELECT mark_all_user_notifications_read(1);  -- user_id
```

#### Get Unread Count
```sql
SELECT get_unread_notification_count(1);  -- user_id
```

### Statistics & Reporting

#### Dashboard Stats
```sql
SELECT get_dashboard_stats(1);  -- user_id (NULL for all)
```

#### Monthly Trend
```sql
SELECT * FROM get_monthly_expense_trend(
    6,                      -- months
    1                       -- user_id (NULL for all)
);
```

#### System Health
```sql
SELECT system_health_check();
```

---

## 🔒 Security Features

### Row Level Security (RLS)

All tables have RLS enabled with policies:

1. **Service role** - Full access (for backend operations)
2. **Anonymous users** - Limited access (OTP logs only)
3. **Authenticated users** - Own data access

### OTP Security

- ✅ Tracked in `otp_logs` table
- ✅ Rate limiting via `check_otp_rate_limit()`
- ✅ IP and device tracking
- ✅ Failed attempt monitoring

### Session Security

- ✅ Token-based authentication
- ✅ Auto-expiry
- ✅ Device tracking
- ✅ Concurrent session limits
- ✅ Session termination on user block

### Audit Trail

- ✅ All actions logged in `activity_logs`
- ✅ Before/after values tracked
- ✅ IP and device information
- ✅ Expense approval history

---

## 🧹 Maintenance

### Regular Maintenance Tasks

#### Clean Expired Sessions (Run daily)
```sql
SELECT clean_expired_sessions();
```

#### Clean Old Notifications (Run weekly)
```sql
SELECT clean_old_notifications(90);  -- Days
```

#### Clean Old Activity Logs (Run monthly)
```sql
SELECT clean_old_activity_logs(180);  -- Days
```

#### Clean Old OTP Logs (Run monthly)
```sql
SELECT clean_old_otp_logs(30);  -- Days
```

### Monitoring Queries

#### Failed Login Attempts
```sql
SELECT u.mobile_number, u.failed_login_attempts, u.last_failed_login_at
FROM users u
WHERE failed_login_attempts > 3
ORDER BY last_failed_login_at DESC;
```

#### Recent OTP Failures
```sql
SELECT phone, COUNT(*) as failures
FROM otp_logs
WHERE success = false
  AND created_at > NOW() - INTERVAL '1 hour'
GROUP BY phone
HAVING COUNT(*) > 3
ORDER BY failures DESC;
```

#### Pending Expenses
```sql
SELECT COUNT(*), SUM(amount)
FROM expenses
WHERE status = 'pending'
  AND deleted_at IS NULL;
```

#### Active Sessions
```sql
SELECT COUNT(*) as active_sessions
FROM user_sessions
WHERE is_active = true
  AND expires_at > NOW();
```

---

## 📈 Performance Optimization

### Indexes Created

All tables have appropriate indexes for:
- Primary keys (automatic)
- Foreign keys
- Frequently queried columns
- Date columns
- Status fields
- Soft delete fields

### Query Optimization Tips

1. **Use views** - `vw_user_details`, `vw_expense_summary`
2. **Filter deleted records** - Always add `WHERE deleted_at IS NULL`
3. **Use indexes** - Filter on indexed columns
4. **Limit results** - Use `LIMIT` for large tables
5. **Use prepared functions** - Better performance than ad-hoc queries

---

## 🔧 Troubleshooting

### Issue: "Function does not exist"

**Solution:** Run the function SQL files:
```sql
-- Run in order:
1. COMPLETE_SCHEMA.sql
2. 02_helper_functions.sql
3. 04_advanced_functions.sql
```

### Issue: "Permission denied"

**Solution:** Check RLS policies or use service role key for backend operations.

### Issue: "Unique constraint violation"

**Common causes:**
- Duplicate mobile number
- Duplicate ADM code
- Duplicate email

**Solution:** Check existing records before insert.

### Issue: "Foreign key violation"

**Solution:** Ensure referenced records exist (user_id, category_id, etc.)

---

## 📊 Database Size Estimates

| Records | Users | Expenses | Notifications | Estimated Size |
|---------|-------|----------|---------------|----------------|
| Small   | 100   | 1,000    | 5,000        | ~50 MB         |
| Medium  | 1,000 | 10,000   | 50,000       | ~500 MB        |
| Large   | 10,000| 100,000  | 500,000      | ~5 GB          |

---

## 🚀 Next Steps

1. ✅ **Database setup complete** - All tables created
2. ⬜ **Update Flutter services** - Use new table structure
3. ⬜ **Test CRUD operations** - Create, read, update, delete
4. ⬜ **Set up monitoring** - Track performance and errors
5. ⬜ **Schedule maintenance** - Set up cron jobs for cleanup
6. ⬜ **Backup strategy** - Regular database backups

---

## 📚 Additional Resources

- **Supabase Docs:** https://supabase.com/docs
- **PostgreSQL Docs:** https://www.postgresql.org/docs/
- **Row Level Security:** https://supabase.com/docs/guides/auth/row-level-security

---

**Version:** 2.0.0
**Last Updated:** 2025-10-01
**Status:** ✅ Production Ready
