import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';
import 'textlk_sms_service.dart';

class AuthService {
  // Session management (minimal - just for OTP and current user ID)
  static const String _currentUserIdKey = 'current_user_id';
  static const String _currentUserPhoneKey = 'current_user_phone';
  static const String _isLoggedInKey = 'is_logged_in';

  // Generate ADM Code (Administrative Code)
  static String generateAdmCode() {
    final random = Random.secure();
    final year = DateTime.now().year.toString().substring(2);
    final randomNumbers = List.generate(6, (index) => random.nextInt(10)).join();
    return 'ADM$year$randomNumbers';
  }

  // Generate 6-digit OTP using cryptographically secure random
  static String _generateOTP() {
    final random = Random.secure();
    return List.generate(6, (index) => random.nextInt(10)).join();
  }

  // Send OTP using text.lk SMS API (NOT Supabase)
  static Future<Map<String, dynamic>> sendOTP(String mobileNumber) async {
    try {
      print('📱 AuthService: Validating phone number');

      // Validate phone number
      if (!TextLkSmsService.isValidSriLankanPhone(mobileNumber)) {
        return {
          'success': false,
          'message': 'Invalid phone number format',
        };
      }

      // Generate OTP locally (cryptographically secure)
      final otp = _generateOTP();
      print('🔐 AuthService: OTP generated locally: $otp');

      // Store OTP temporarily in SharedPreferences (ONLY for OTP verification)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('temp_otp_$mobileNumber', otp);
      await prefs.setInt('otp_timestamp_$mobileNumber', DateTime.now().millisecondsSinceEpoch);
      print('💾 AuthService: OTP stored temporarily');

      // ✅ SEND OTP VIA TEXT.LK SMS API (EXTERNAL SERVICE, NOT SUPABASE)
      print('📤 AuthService: Sending OTP via text.lk SMS API...');
      final result = await TextLkSmsService.sendOTP(
        phoneNumber: mobileNumber,
        otp: otp,
      );
      print('📤 text.lk Response: ${result['success'] ? 'SMS sent successfully' : 'SMS failed'}');

      // Log OTP attempt in Supabase (FOR AUDIT ONLY)
      try {
        print('📝 AuthService: Logging OTP attempt to Supabase (audit trail only)');
        await SupabaseService.logOTPAttempt(
          phone: mobileNumber,
          success: result['success'] ?? false,
          errorMessage: result['success'] ? null : result['message'],
        );
      } catch (e) {
        print('⚠️ Failed to log OTP attempt to Supabase: $e (non-critical)');
      }

      if (result['success']) {
        print('✅ AuthService: OTP sent successfully via text.lk');
        return {
          'success': true,
          'message': 'OTP sent successfully',
        };
      } else {
        print('❌ AuthService: Failed to send OTP via text.lk');
        return {
          'success': false,
          'message': result['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      print('❌ AuthService: Error in sendOTP: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Verify OTP
  static Future<bool> verifyOTP(String mobileNumber, String enteredOTP) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedOTP = prefs.getString('temp_otp_$mobileNumber');
      final timestamp = prefs.getInt('otp_timestamp_$mobileNumber');

      if (storedOTP == null || timestamp == null) {
        return false;
      }

      // Check if OTP is expired (5 minutes)
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final otpAge = currentTime - timestamp;
      if (otpAge > 5 * 60 * 1000) { // 5 minutes in milliseconds
        await prefs.remove('temp_otp_$mobileNumber');
        await prefs.remove('otp_timestamp_$mobileNumber');
        return false;
      }

      // Verify OTP
      final isValid = storedOTP == enteredOTP;

      // Clear OTP after verification attempt
      if (isValid) {
        await prefs.remove('temp_otp_$mobileNumber');
        await prefs.remove('otp_timestamp_$mobileNumber');
      }

      return isValid;
    } catch (e) {
      print('OTP verification error: $e');
      return false;
    }
  }

  // Register new user (creates user in database ONLY)
  static Future<UserModel> registerUser(String mobileNumber, UserRole role) async {
    try {
      print('🔵 Starting user registration for: $mobileNumber');

      // Check if user already exists in database
      final existingUser = await SupabaseService.getUserByPhone(mobileNumber);

      if (existingUser != null) {
        print('🟢 User already exists, marking as verified');
        await SupabaseService.markUserAsVerified(mobileNumber);
        final user = UserModel.fromJson(existingUser);
        await _setCurrentUserSession(user);
        return user;
      }

      print('🔵 Creating new user in database with role: ${role.toString().split('.').last}');

      // Create basic user record in database
      final userId = await SupabaseService.createBasicUser(
        mobileNumber: mobileNumber,
        role: role.toString().split('.').last,
      );

      print('🟢 User created with ID: $userId');

      // Mark user as verified after successful OTP
      await SupabaseService.markUserAsVerified(mobileNumber);
      print('🟢 User marked as verified');

      // Fetch the created user from database
      final userData = await SupabaseService.getUserByPhone(mobileNumber);
      if (userData == null) {
        throw Exception('Failed to fetch user after creation');
      }

      final user = UserModel.fromJson(userData);
      await _setCurrentUserSession(user);
      return user;
    } catch (e) {
      print('❌ Registration error: $e');
      rethrow;
    }
  }

  // Login user (fetch from database ONLY)
  static Future<UserModel?> loginUser(String mobileNumber) async {
    try {
      print('🔵 AuthService: Logging in user: $mobileNumber');

      // Get user from database
      final userData = await SupabaseService.getUserByPhone(mobileNumber);

      if (userData == null) {
        print('❌ AuthService: User not found in database');
        return null;
      }

      final user = UserModel.fromJson(userData);

      // Update last login timestamp in database
      try {
        await SupabaseService.updateUserLastLogin(mobileNumber);
      } catch (e) {
        print('⚠️ Failed to update last login: $e (non-critical)');
      }

      await _setCurrentUserSession(user);
      print('🟢 AuthService: User logged in successfully');
      return user;
    } catch (e) {
      print('❌ Login error: $e');
      return null;
    }
  }

  // Set current user session (minimal - just ID and phone)
  static Future<void> _setCurrentUserSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserIdKey, user.id);
    await prefs.setString(_currentUserPhoneKey, user.mobileNumber);
    await prefs.setBool(_isLoggedInKey, true);
  }

  // Get current user (fetch fresh from database every time)
  static Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString(_currentUserPhoneKey);

      if (phoneNumber == null) {
        return null;
      }

      // Always fetch fresh data from database
      final userData = await SupabaseService.getUserByPhone(phoneNumber);
      if (userData == null) {
        return null;
      }

      return UserModel.fromJson(userData);
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Logout user (clear session only)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserIdKey);
    await prefs.remove(_currentUserPhoneKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  // Update user profile (database ONLY)
  static Future<void> updateUserProfile(UserModel user) async {
    try {
      print('🔵 AuthService: Updating user profile in database');

      // Update in database using the correct schema
      await SupabaseService.createOrUpdateUserProfile(
        mobileNumber: user.mobileNumber,
        firstName: user.firstName,
        lastName: user.lastName,
        fullName: user.fullName,
        nic: user.nic,
        dateOfBirth: user.dateOfBirth,
        gender: user.gender,
        profilePictureUrl: user.profilePictureUrl,
      );

      print('🟢 AuthService: Profile updated successfully in database');
    } catch (e) {
      print('❌ Update profile error: $e');
      rethrow;
    }
  }

  // Check if mobile number is registered (database check)
  static Future<bool> isMobileRegistered(String mobileNumber) async {
    try {
      final userData = await SupabaseService.getUserByPhone(mobileNumber);
      return userData != null;
    } catch (e) {
      print('Check registration error: $e');
      return false;
    }
  }

  // Update phone number (requires OTP verification)
  static Future<void> updatePhoneNumber(String oldPhone, String newPhone) async {
    try {
      print('🔵 AuthService: Updating phone number from $oldPhone to $newPhone');

      // Update in database
      await SupabaseService.updatePhoneNumber(oldPhone, newPhone);

      // Update session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserPhoneKey, newPhone);

      print('🟢 AuthService: Phone number updated successfully');
    } catch (e) {
      print('❌ Update phone number error: $e');
      rethrow;
    }
  }
}
