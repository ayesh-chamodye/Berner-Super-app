import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class SupabaseService {
  static SupabaseClient? _client;

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  // Get Supabase client
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call SupabaseService.initialize() first.');
    }
    return _client!;
  }

  // Get user with profile (joins users and user_profiles)
  static Future<Map<String, dynamic>?> getUserProfile(String phoneNumber) async {
    try {
      print('🔵 SupabaseService: Fetching user profile for $phoneNumber');

      // Use the view for joined data
      final response = await client
          .from('vw_user_details')
          .select()
          .eq('mobile_number', phoneNumber)
          .maybeSingle();

      print('🟢 SupabaseService: User profile fetched successfully');
      return response;
    } catch (e) {
      print('⚠️ SupabaseService: Error getting user profile: $e');
      print('⚠️ This is OK - app will use local storage instead');
      print('⚠️ To fix: Run database scripts in Supabase SQL Editor');
      return null;
    }
  }

  // Create user with profile using database function
  static Future<int> createUserProfile(Map<String, dynamic> userData) async {
    try {
      final response = await client.rpc('create_user_with_profile', params: {
        'p_mobile_number': userData['mobile_number'],
        'p_role': userData['role'],
        'p_first_name': userData['first_name'],
        'p_last_name': userData['last_name'],
        'p_email': userData['email'],
        'p_nic': userData['nic'],
      });

      // Extract user_id from response
      if (response is Map && response['success'] == true) {
        return response['user_id'] as int;
      }
      throw Exception('Failed to create user');
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  // Create or update user profile (inserts or updates user_profiles table)
  static Future<void> createOrUpdateUserProfile({
    required String mobileNumber,
    String? firstName,
    String? lastName,
    String? fullName,
    String? nic,
    DateTime? dateOfBirth,
    String? gender,
    String? profilePictureUrl,
  }) async {
    try {
      print('🔵 SupabaseService: Creating/updating profile for $mobileNumber');

      // Get user_id from phone number
      print('🔵 SupabaseService: Querying users table for phone: $mobileNumber');
      final user = await client
          .from('users')
          .select('id')
          .eq('mobile_number', mobileNumber)
          .single();

      final userId = user['id'];
      print('🟢 SupabaseService: Found user ID: $userId');

      // Check if profile already exists
      print('🔵 SupabaseService: Checking if profile exists for user ID: $userId');
      final existingProfile = await client
          .from('user_profiles')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();

      final profileData = {
        'user_id': userId,
        'first_name': firstName,
        'last_name': lastName,
        'full_name': fullName,
        'nic': nic,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'gender': gender,
        'profile_picture_url': profilePictureUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('🔵 SupabaseService: Profile data prepared: ${profileData.keys.toList()}');

      if (existingProfile == null) {
        // Create new profile
        print('🔵 SupabaseService: No existing profile found - creating new one');
        await client.from('user_profiles').insert(profileData);
        print('🟢 SupabaseService: Profile created successfully!');
      } else {
        // Update existing profile
        print('🔵 SupabaseService: Existing profile found - updating');
        await client.from('user_profiles').update(profileData).eq('user_id', userId);
        print('🟢 SupabaseService: Profile updated successfully!');
      }
    } catch (e, stackTrace) {
      print('❌ SupabaseService: Error creating/updating user profile');
      print('❌ Error details: $e');
      print('❌ Stack trace: $stackTrace');
      print('⚠️ Common causes:');
      print('   1. Supabase tables not created (run SQL scripts)');
      print('   2. User does not exist in users table');
      print('   3. Network connection issue');
      print('   4. Invalid Supabase credentials in .env');
      rethrow;
    }
  }

  // Update user profile (updates user_profiles table)
  static Future<void> updateUserProfile(String phoneNumber, Map<String, dynamic> updates) async {
    try {
      // Get user_id from phone number
      final user = await client
          .from('users')
          .select('id')
          .eq('mobile_number', phoneNumber)
          .single();

      if (user == null) {
        throw Exception('User not found');
      }

      final userId = user['id'];

      // Update user_profiles table
      await client
          .from('user_profiles')
          .update(updates)
          .eq('user_id', userId);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Update user last login timestamp
  static Future<void> updateUserLastLogin(String phoneNumber) async {
    try {
      await client.from('users').update({
        'last_login_at': DateTime.now().toIso8601String(),
      }).eq('mobile_number', phoneNumber);
    } catch (e) {
      print('Error updating last login: $e');
      // Don't rethrow - login should succeed even if timestamp update fails
    }
  }

  // Mark user as verified after OTP verification
  static Future<void> markUserAsVerified(String phoneNumber) async {
    try {
      await client.from('users').update({
        'is_verified': true,
      }).eq('mobile_number', phoneNumber);
    } catch (e) {
      print('Error marking user as verified: $e');
      rethrow;
    }
  }

  // Check if user profile exists by phone number
  static Future<bool> userProfileExists(String phoneNumber) async {
    try {
      final response = await client
          .from('users')
          .select('mobile_number')
          .eq('mobile_number', phoneNumber)
          .maybeSingle();
      return response != null;
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }

  // Get user by phone number (same as getUserProfile for consistency)
  static Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    return await getUserProfile(phone);
  }

  // Create basic user (without profile) - inserts into users table only
  static Future<int> createBasicUser({
    required String mobileNumber,
    required String role,
  }) async {
    try {
      print('🔵 SupabaseService: Creating basic user in users table');

      // Generate ADM code for employees
      String? admCode;
      if (role == 'employee') {
        final random = Random.secure();
        final year = DateTime.now().year.toString().substring(2);
        final randomNumbers = List.generate(6, (index) => random.nextInt(10)).join();
        admCode = 'ADM$year$randomNumbers';
      }

      final response = await client.from('users').insert({
        'mobile_number': mobileNumber,
        'role': role,
        'adm_code': admCode,
        'is_verified': false, // Will be set to true after OTP
        'is_active': true,
      }).select('id').single();

      print('🟢 SupabaseService: User created with ID: ${response['id']}');
      return response['id'] as int;
    } catch (e) {
      print('❌ Error creating basic user: $e');
      rethrow;
    }
  }

  // Delete user profile
  static Future<void> deleteUserProfile(String phoneNumber) async {
    try {
      await client.from('users').delete().eq('mobile_number', phoneNumber);
    } catch (e) {
      print('Error deleting user profile: $e');
      rethrow;
    }
  }

  // Get all users (admin feature)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await client
          .from('users')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Get users by role
  static Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('role', role)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting users by role: $e');
      return [];
    }
  }

  // OTP table operations (for tracking OTP attempts)
  static Future<void> logOTPAttempt({
    required String phone,
    required bool success,
    String? errorMessage,
  }) async {
    try {
      await client.from('otp_logs').insert({
        'phone': phone,
        'success': success,
        'error_message': errorMessage,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error logging OTP attempt: $e');
      // Don't rethrow - logging failure shouldn't break the flow
    }
  }

  // Get OTP logs for a phone number
  static Future<List<Map<String, dynamic>>> getOTPLogs(String phone, {int limit = 10}) async {
    try {
      final response = await client
          .from('otp_logs')
          .select()
          .eq('phone', phone)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting OTP logs: $e');
      return [];
    }
  }

  // Count OTP attempts in last N minutes
  static Future<int> countRecentOTPAttempts(String phone, int minutes) async {
    try {
      final cutoffTime = DateTime.now().subtract(Duration(minutes: minutes)).toIso8601String();
      final response = await client
          .from('otp_logs')
          .select('id')
          .eq('phone', phone)
          .gte('created_at', cutoffTime);
      return (response as List).length;
    } catch (e) {
      print('Error counting OTP attempts: $e');
      return 0;
    }
  }

  // Clean old OTP logs (admin maintenance)
  static Future<void> cleanOldOTPLogs({int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld)).toIso8601String();
      await client.from('otp_logs').delete().lt('created_at', cutoffDate);
    } catch (e) {
      print('Error cleaning old OTP logs: $e');
    }
  }

  // Update phone number after OTP verification
  static Future<void> updatePhoneNumber(String oldPhone, String newPhone) async {
    try {
      await client.from('users').update({
        'mobile_number': newPhone,
      }).eq('mobile_number', oldPhone);
    } catch (e) {
      print('Error updating phone number: $e');
      rethrow;
    }
  }

  // Health check - test if Supabase is accessible
  static Future<bool> healthCheck() async {
    try {
      await client.from('users').select('mobile_number').limit(1);
      return true;
    } catch (e) {
      print('Supabase health check failed: $e');
      return false;
    }
  }
}
