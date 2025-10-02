import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';
import 'textlk_sms_service.dart';

class AuthService {
  static const String _userKey = 'current_user';
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

      // Store OTP temporarily in SharedPreferences (local storage)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('temp_otp_$mobileNumber', otp);
      await prefs.setInt('otp_timestamp_$mobileNumber', DateTime.now().millisecondsSinceEpoch);
      print('💾 AuthService: OTP stored in local device storage');

      // ✅ SEND OTP VIA TEXT.LK SMS API (EXTERNAL SERVICE, NOT SUPABASE)
      print('📤 AuthService: Sending OTP via text.lk SMS API...');
      final result = await TextLkSmsService.sendOTP(
        phoneNumber: mobileNumber,
        otp: otp,
      );
      print('📤 text.lk Response: ${result['success'] ? 'SMS sent successfully' : 'SMS failed'}');

      // Log OTP attempt in Supabase (FOR AUDIT ONLY, NOT FOR SENDING)
      try {
        print('📝 AuthService: Logging OTP attempt to Supabase (audit trail only)');
        await SupabaseService.logOTPAttempt(
          phone: mobileNumber,
          success: result['success'] ?? false,
          errorMessage: result['success'] ? null : result['message'],
        );
      } catch (e) {
        // Log error but don't fail the operation
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

  // Register new user with Supabase (creates user without profile initially)
  static Future<UserModel> registerUser(String mobileNumber, UserRole role) async {
    try {
      print('🔵 Starting user registration for: $mobileNumber');

      // Check if user already exists in Supabase
      final existingUser = await SupabaseService.getUserByPhone(mobileNumber);

      if (existingUser != null) {
        print('🟢 User already exists, marking as verified');
        // User already exists, mark as verified after OTP
        await SupabaseService.markUserAsVerified(mobileNumber);
        final user = UserModel.fromJson(existingUser);
        await saveUser(user);
        return user;
      }

      print('🔵 Creating new user in Supabase with role: ${role.toString().split('.').last}');

      // Create basic user record (profile will be created in profile_setup_page)
      final userId = await SupabaseService.createBasicUser(
        mobileNumber: mobileNumber,
        role: role.toString().split('.').last,
      );

      print('🟢 User created with ID: $userId');

      // Mark user as verified after successful OTP
      await SupabaseService.markUserAsVerified(mobileNumber);
      print('🟢 User marked as verified');

      // Fetch the created user
      final userData = await SupabaseService.getUserByPhone(mobileNumber);
      if (userData != null) {
        print('🟢 User data fetched from Supabase');
        final user = UserModel.fromJson(userData);
        await saveUser(user);
        return user;
      }

      // Fallback: create user model locally
      print('⚠️ Fallback: Creating user model locally');
      final user = UserModel(
        id: userId.toString(),
        mobileNumber: mobileNumber,
        admCode: role == UserRole.employee ? generateAdmCode() : null,
        role: role,
        isVerified: true,
        createdAt: DateTime.now(),
      );
      await saveUser(user);
      return user;
    } catch (e) {
      print('❌ Registration error: $e');
      // Fallback to local storage
      final user = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        mobileNumber: mobileNumber,
        admCode: role == UserRole.employee ? generateAdmCode() : null,
        role: role,
        isVerified: true,
        createdAt: DateTime.now(),
      );
      await saveUser(user);
      return user;
    }
  }

  // Login user
  static Future<UserModel?> loginUser(String mobileNumber) async {
    try {
      // Try to get user from Supabase
      final userData = await SupabaseService.getUserByPhone(mobileNumber);

      if (userData != null) {
        final user = UserModel.fromJson(userData);

        // Update last login timestamp
        try {
          await SupabaseService.updateUserLastLogin(mobileNumber);
        } catch (e) {
          // Non-critical error, continue with login
          print('Failed to update last login: $e');
        }

        await setCurrentUser(user);
        return user;
      }

      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_$mobileNumber');

      if (userJson != null) {
        final user = UserModel.fromJson(json.decode(userJson));
        await setCurrentUser(user);
        return user;
      }

      return null;
    } catch (e) {
      print('Login error: $e');
      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_$mobileNumber');

      if (userJson != null) {
        final user = UserModel.fromJson(json.decode(userJson));
        await setCurrentUser(user);
        return user;
      }

      return null;
    }
  }

  // Save user data
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_${user.mobileNumber}', json.encode(user.toJson()));
    await setCurrentUser(user);
  }

  // Set current user
  static Future<void> setCurrentUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
    await prefs.setBool(_isLoggedInKey, true);
  }

  // Get current user
  static Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (userJson != null) {
        return UserModel.fromJson(json.decode(userJson));
      }

      return null;
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

  // Logout user
  static Future<void> logout() async {
    // Clear local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  // Update user profile
  static Future<void> updateUserProfile(UserModel user) async {
    try {
      // Update in Supabase (using phone number to identify user)
      await SupabaseService.updateUserProfile(user.mobileNumber, {
        'name': user.name,
        'nic': user.nic,
        'date_of_birth': user.dateOfBirth?.toIso8601String(),
        'gender': user.gender,
        'profile_picture_path': user.profilePicturePath,
      });

      // Update last login
      await SupabaseService.updateUserLastLogin(user.mobileNumber);

      // Update locally
      await saveUser(user);
    } catch (e) {
      print('Update profile error: $e');
      // Fallback to local update
      await saveUser(user);
    }
  }

  // Check if mobile number is registered
  static Future<bool> isMobileRegistered(String mobileNumber) async {
    try {
      // Check in Supabase
      final userData = await SupabaseService.getUserByPhone(mobileNumber);
      if (userData != null) {
        return true;
      }

      // Fallback to local check
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('user_$mobileNumber');
    } catch (e) {
      print('Check registration error: $e');
      // Fallback to local check
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('user_$mobileNumber');
    }
  }

  // Sync local user to Supabase (useful for migration)
  static Future<void> syncLocalUserToSupabase(UserModel user) async {
    try {
      final exists = await SupabaseService.userProfileExists(user.mobileNumber);
      if (!exists) {
        await SupabaseService.createUserProfile({
          'mobile_number': user.mobileNumber,
          'adm_code': user.admCode,
          'role': user.role.toString().split('.').last,
          'is_verified': user.isVerified,
          'created_at': user.createdAt.toIso8601String(),
          'name': user.name,
          'nic': user.nic,
          'date_of_birth': user.dateOfBirth?.toIso8601String(),
          'gender': user.gender,
          'profile_picture_path': user.profilePicturePath,
        });
      }
    } catch (e) {
      print('Sync error: $e');
    }
  }

  // Update phone number (requires OTP verification)
  static Future<void> updatePhoneNumber(String oldPhone, String newPhone) async {
    try {
      // Update in database
      await SupabaseService.updatePhoneNumber(oldPhone, newPhone);

      // Update locally
      final prefs = await SharedPreferences.getInstance();
      final currentUserJson = prefs.getString(_userKey);
      if (currentUserJson != null) {
        final userData = json.decode(currentUserJson);
        userData['mobile_number'] = newPhone;
        await prefs.setString(_userKey, json.encode(userData));
      }

      // Clear old user data
      await prefs.remove('user_$oldPhone');
    } catch (e) {
      print('Update phone number error: $e');
      rethrow;
    }
  }
}
