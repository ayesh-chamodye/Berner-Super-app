# OTP Architecture - Berner Super App

## ✅ OTP is 100% Handled by text.lk (NOT Supabase)

### **How OTP Works:**

```
User Enters Phone Number
         ↓
App Generates Random OTP (Locally)
         ↓
App Stores OTP in Local Device (SharedPreferences)
         ↓
App Sends OTP via text.lk SMS API ← ✅ ACTUAL SMS SENDING
         ↓
App Logs Attempt to Supabase (Audit Only) ← ℹ️ JUST FOR TRACKING
         ↓
User Receives SMS from text.lk
         ↓
User Enters OTP
         ↓
App Verifies OTP from Local Storage (NOT Supabase)
```

---

## 📱 OTP Sending Flow (auth_service.dart)

1. **Generate OTP** - Created locally using `Random.secure()` (cryptographically secure)
2. **Store OTP** - Saved in device's SharedPreferences with 5-minute expiry
3. **✅ SEND VIA text.lk** - `TextLkSmsService.sendOTP()` makes HTTP request to text.lk API
4. **Log to Supabase** - Records the attempt in `otp_logs` table (for security auditing only)

---

## 🔐 OTP Verification Flow

- OTP is **verified locally** by comparing with SharedPreferences
- OTP expires after 5 minutes
- OTP is deleted from local storage after successful verification
- **Supabase is NOT involved in verification**

---

## 🗂️ What Supabase Does (NOT OTP Sending)

Supabase is only used for:

1. **Storing user data** (`users` and `user_profiles` tables)
2. **Logging OTP attempts** (`otp_logs` table for audit trail)
3. **Storing expenses, notifications, etc.**

**Supabase does NOT:**
- ❌ Send OTP SMS
- ❌ Generate OTP
- ❌ Verify OTP

---

## 📡 text.lk Integration (textlk_sms_service.dart)

The `TextLkSmsService` class makes direct HTTP requests to text.lk API:

```dart
// ACTUAL SMS SENDING HAPPENS HERE
final response = await http.post(
  'https://api.text.lk/sms/send',
  headers: {
    'Authorization': 'Bearer YOUR_TEXTLK_TOKEN',
  },
  body: {
    'recipient': phoneNumber,
    'message': 'Your OTP is: $otp',
  },
);
```

---

## 🔧 Configuration Required

Make sure your `.env` file has:

```env
# text.lk Configuration (FOR OTP SMS)
TEXTLK_API_URL=https://api.text.lk
TEXTLK_API_TOKEN=your_textlk_api_token_here

# Supabase Configuration (FOR DATABASE ONLY)
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

---

## 📊 Debug Logs to Confirm

When you run the app and request OTP, you'll see:

```
📱 AuthService: Validating phone number
🔐 AuthService: OTP generated locally: 123456
💾 AuthService: OTP stored in local device storage
📤 AuthService: Sending OTP via text.lk SMS API...
📡 text.lk: Preparing to send OTP SMS
📡 text.lk: Sending SMS to: 94771234567
📡 text.lk: API URL: https://api.text.lk/sms/send
📡 text.lk: Response status code: 200
✅ text.lk: SMS sent successfully via text.lk API
📝 AuthService: Logging OTP attempt to Supabase (audit trail only)
✅ AuthService: OTP sent successfully via text.lk
```

The key line is: **✅ text.lk: SMS sent successfully via text.lk API**

This confirms OTP is being sent via text.lk, NOT Supabase!

---

## ✅ Summary

| Task | Service Used |
|------|-------------|
| Generate OTP | **App (Random.secure())** |
| Store OTP | **Local Device (SharedPreferences)** |
| Send OTP SMS | **✅ text.lk API** |
| Verify OTP | **Local Device (SharedPreferences)** |
| Log OTP Attempt | Supabase (audit only) |
| Store User Data | Supabase (after verification) |

**OTP is completely independent from Supabase!** 🎉
