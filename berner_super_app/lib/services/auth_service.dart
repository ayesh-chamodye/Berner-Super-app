import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';

  // Generate ADM Code (Administrative Code)
  static String generateAdmCode() {
    final random = Random();
    final year = DateTime.now().year.toString().substring(2);
    final randomNumbers = List.generate(6, (index) => random.nextInt(10)).join();
    return 'ADM$year$randomNumbers';
  }

  // Simulate OTP sending (in real app, this would call SMS API)
  static Future<String> sendOTP(String mobileNumber) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

    // Generate 6-digit OTP
    final random = Random();
    final otp = List.generate(6, (index) => random.nextInt(10)).join();

    // In real app, send SMS here
    print('OTP for $mobileNumber: $otp'); // For debugging

    // Store OTP temporarily (in real app, store server-side)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('temp_otp_$mobileNumber', otp);
    await prefs.setInt('otp_timestamp_$mobileNumber', DateTime.now().millisecondsSinceEpoch);

    return otp; // Return for demo purposes only
  }

  // Verify OTP
  static Future<bool> verifyOTP(String mobileNumber, String enteredOTP) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

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
      return false;
    }

    // Clear OTP after verification attempt
    await prefs.remove('temp_otp_$mobileNumber');
    await prefs.remove('otp_timestamp_$mobileNumber');

    return storedOTP == enteredOTP;
  }

  // Register new user
  static Future<UserModel> registerUser(String mobileNumber, UserRole role) async {
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

  // Login user
  static Future<UserModel?> loginUser(String mobileNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_$mobileNumber');

    if (userJson != null) {
      final user = UserModel.fromJson(json.decode(userJson));
      await setCurrentUser(user);
      return user;
    }

    return null;
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
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    if (userJson != null) {
      return UserModel.fromJson(json.decode(userJson));
    }

    return null;
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  // Update user profile
  static Future<void> updateUserProfile(UserModel user) async {
    await saveUser(user);
  }

  // Check if mobile number is registered
  static Future<bool> isMobileRegistered(String mobileNumber) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('user_$mobileNumber');
  }
}