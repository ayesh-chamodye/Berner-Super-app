import 'dart:io';
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

      // Fetch user data from users table
      final userResponse = await client
          .from('users')
          .select()
          .eq('mobile_number', phoneNumber)
          .maybeSingle();

      if (userResponse == null) {
        print('⚠️ SupabaseService: User not found in users table');
        return null;
      }

      final userId = userResponse['id'];
      print('🟢 SupabaseService: User found with ID: $userId');

      // Fetch profile data from user_profiles table
      try {
        final profileResponse = await client
            .from('user_profiles')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        if (profileResponse != null) {
          print('🟢 SupabaseService: Profile data found, merging...');
          // Merge user and profile data
          final mergedData = Map<String, dynamic>.from(userResponse);
          mergedData.addAll(profileResponse);
          print('🟢 SupabaseService: User profile fetched successfully with profile data');
          return mergedData;
        } else {
          print('⚠️ SupabaseService: No profile data found, returning user data only');
          return userResponse;
        }
      } catch (profileError) {
        print('⚠️ SupabaseService: Error fetching profile: $profileError');
        print('⚠️ Returning user data without profile');
        return userResponse;
      }
    } catch (e) {
      print('⚠️ SupabaseService: Error getting user profile: $e');
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

      final userResult = await client
          .from('users')
          .select('id')
          .eq('mobile_number', mobileNumber)
          .maybeSingle();

      if (userResult == null) {
        print('❌ SupabaseService: User not found in users table!');
        print('⚠️ This means user creation failed during registration.');
        print('⚠️ Check registration logs for errors.');
        print('⚠️ Possible causes:');
        print('   - RLS policies not applied (run FIX_RLS_POLICY.sql)');
        print('   - User was created with different phone format');
        print('   - Registration failed but continued anyway');
        throw Exception('User not found in users table. Phone: $mobileNumber');
      }

      final user = userResult;
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

  // Upload profile picture to Supabase Storage
  static Future<String?> uploadProfilePicture(String filePath, String userId) async {
    try {
      print('🔵 SupabaseService: Uploading profile picture for user $userId');

      final file = File(filePath);
      if (!await file.exists()) {
        print('❌ SupabaseService: File does not exist at $filePath');
        return null;
      }

      final bytes = await file.readAsBytes();
      final fileExt = filePath.split('.').last;
      final fileName = 'profile_$userId.${fileExt}';
      final filePath_storage = 'profile_pictures/$fileName';

      print('🔵 SupabaseService: Uploading to storage path: $filePath_storage');

      // Upload to Supabase Storage (profile-pictures bucket)
      print('🔵 SupabaseService: Starting upload - File size: ${bytes.length} bytes');
      print('🔵 SupabaseService: Content type: image/${fileExt == 'jpg' ? 'jpeg' : fileExt}');

      final uploadResult = await client.storage.from('profile-pictures').uploadBinary(
            filePath_storage,
            bytes,
            fileOptions: FileOptions(
              upsert: true, // Overwrite if exists
              contentType: 'image/${fileExt == 'jpg' ? 'jpeg' : fileExt}',
            ),
          );

      print('🟢 SupabaseService: Upload result: $uploadResult');

      // Get public URL
      final publicUrl = client.storage.from('profile-pictures').getPublicUrl(filePath_storage);

      print('🟢 SupabaseService: Profile picture uploaded successfully');
      print('🟢 SupabaseService: Public URL: $publicUrl');

      return publicUrl;
    } catch (e, stackTrace) {
      print('❌ SupabaseService: Error uploading profile picture: $e');
      print('❌ SupabaseService: Stack trace: $stackTrace');
      print('❌ SupabaseService: File path attempted: $filePath');
      return null;
    }
  }

  // Delete profile picture from Supabase Storage
  static Future<bool> deleteProfilePicture(String userId) async {
    try {
      print('🔵 SupabaseService: Deleting profile picture for user $userId');

      // Try to delete all common extensions
      final extensions = ['jpg', 'jpeg', 'png', 'webp'];
      for (final ext in extensions) {
        try {
          await client.storage.from('profile-pictures').remove(['profile_pictures/profile_$userId.$ext']);
        } catch (e) {
          // Ignore if file doesn't exist
        }
      }

      print('🟢 SupabaseService: Profile picture deleted successfully');
      return true;
    } catch (e) {
      print('❌ SupabaseService: Error deleting profile picture: $e');
      return false;
    }
  }

  // =====================================================
  // EXPENSE OPERATIONS
  // =====================================================

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
  }) async {
    try {
      print('🔵 SupabaseService: Creating expense for user $userId');

      final expenseData = {
        'user_id': int.parse(userId),
        'title': title,
        'description': description,
        'amount': amount,
        'currency': 'LKR',
        'category_name': categoryName,
        'expense_date': (expenseDate ?? DateTime.now()).toIso8601String().split('T')[0],
        'status': 'pending',
        'is_approved': false,
        'is_reimbursable': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await client
          .from('expenses')
          .insert(expenseData)
          .select('id')
          .single();

      final expenseId = response['id'] as int;
      print('🟢 SupabaseService: Expense created with ID: $expenseId');

      // Upload attachments if provided
      if (receiptUrl != null || mileageImageUrl != null) {
        await _createExpenseAttachments(
          expenseId: expenseId,
          receiptUrl: receiptUrl,
          mileageImageUrl: mileageImageUrl,
        );
      }

      return expenseId;
    } catch (e) {
      print('❌ SupabaseService: Error creating expense: $e');
      return null;
    }
  }

  /// Create expense attachments
  static Future<void> _createExpenseAttachments({
    required int expenseId,
    String? receiptUrl,
    String? mileageImageUrl,
  }) async {
    try {
      final attachments = <Map<String, dynamic>>[];

      if (receiptUrl != null) {
        final storagePath = 'expense_receipts/receipt_$expenseId.jpg';
        attachments.add({
          'expense_id': expenseId,
          'file_name': 'receipt_$expenseId.jpg',
          'file_path': storagePath,
          'file_url': receiptUrl,
          'storage_bucket': 'expense-receipts',
          'storage_path': storagePath,
          'is_receipt': true,
          'uploaded_at': DateTime.now().toIso8601String(),
        });
      }

      if (mileageImageUrl != null) {
        final storagePath = 'expense_receipts/mileage_$expenseId.jpg';
        attachments.add({
          'expense_id': expenseId,
          'file_name': 'mileage_$expenseId.jpg',
          'file_path': storagePath,
          'file_url': mileageImageUrl,
          'storage_bucket': 'expense-receipts',
          'storage_path': storagePath,
          'is_receipt': false,
          'uploaded_at': DateTime.now().toIso8601String(),
        });
      }

      if (attachments.isNotEmpty) {
        await client.from('expense_attachments').insert(attachments);
        print('🟢 SupabaseService: Expense attachments created');
      }
    } catch (e) {
      print('⚠️ SupabaseService: Error creating expense attachments: $e');
    }
  }

  /// Get expenses for a user
  static Future<List<Map<String, dynamic>>> getUserExpenses(String userId, {int limit = 50}) async {
    try {
      print('🔵 SupabaseService: Fetching expenses for user $userId');

      final response = await client
          .from('expenses')
          .select('*, expense_attachments(*)')
          .eq('user_id', int.parse(userId))
          .order('created_at', ascending: false)
          .limit(limit);

      print('🟢 SupabaseService: Found ${response.length} expenses');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ SupabaseService: Error getting expenses: $e');
      return [];
    }
  }

  /// Upload expense receipt to Supabase Storage
  static Future<String?> uploadExpenseReceipt(String filePath, int expenseId) async {
    try {
      print('🔵 SupabaseService: Uploading expense receipt for expense $expenseId');

      final file = File(filePath);
      if (!await file.exists()) {
        print('❌ SupabaseService: File does not exist at $filePath');
        return null;
      }

      final bytes = await file.readAsBytes();
      final fileExt = filePath.split('.').last;
      final fileName = 'expense_${expenseId}_receipt.$fileExt';
      final storagePath = 'expense_receipts/$fileName';

      // Upload to Supabase Storage (expense-receipts bucket)
      print('🔵 SupabaseService: Starting upload - File size: ${bytes.length} bytes');
      print('🔵 SupabaseService: Content type: image/${fileExt == 'jpg' ? 'jpeg' : fileExt}');

      final uploadResult = await client.storage.from('expense-receipts').uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/${fileExt == 'jpg' ? 'jpeg' : fileExt}',
            ),
          );

      print('🟢 SupabaseService: Upload result: $uploadResult');

      // Get public URL
      final publicUrl = client.storage.from('expense-receipts').getPublicUrl(storagePath);

      print('🟢 SupabaseService: Expense receipt uploaded successfully');
      print('🟢 SupabaseService: Public URL: $publicUrl');
      return publicUrl;
    } catch (e, stackTrace) {
      print('❌ SupabaseService: Error uploading expense receipt: $e');
      print('❌ SupabaseService: Stack trace: $stackTrace');
      print('❌ SupabaseService: File path attempted: $filePath');
      return null;
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

  // =====================================================
  // AD BANNERS OPERATIONS
  // =====================================================

  /// Get active ad banners for home page slider
  static Future<List<Map<String, dynamic>>> getActiveBanners({String? userRole}) async {
    try {
      print('🔵 SupabaseService: Fetching active ad banners');

      final response = await client
          .from('ad_banners')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true)
          .order('created_at', ascending: false);

      print('🟢 SupabaseService: Found ${response.length} active banners');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ SupabaseService: Error fetching ad banners: $e');
      return [];
    }
  }

  /// Increment banner view count
  static Future<void> incrementBannerViewCount(int bannerId) async {
    try {
      await client.rpc('increment_banner_views', params: {'banner_id': bannerId});
    } catch (e) {
      print('⚠️ SupabaseService: Error incrementing banner view count: $e');
    }
  }

  /// Increment banner click count
  static Future<void> incrementBannerClickCount(int bannerId) async {
    try {
      await client.rpc('increment_banner_clicks', params: {'banner_id': bannerId});
    } catch (e) {
      print('⚠️ SupabaseService: Error incrementing banner click count: $e');
    }
  }

  // =====================================================
  // SUPPORT CHAT OPERATIONS
  // =====================================================

  /// Create a new support ticket
  static Future<Map<String, dynamic>?> createSupportTicket({
    required int userId,
    required String subject,
    String category = 'general',
    String? initialMessage,
  }) async {
    try {
      print('🔵 SupabaseService: Creating support ticket');

      // Generate ticket number
      final ticketNumberResult = await client.rpc('generate_ticket_number');
      final ticketNumber = ticketNumberResult as String;

      // Create ticket
      final ticketResponse = await client
          .from('support_tickets')
          .insert({
            'ticket_number': ticketNumber,
            'subject': subject,
            'category': category,
            'user_id': userId,
            'status': 'open',
            'priority': 'normal',
          })
          .select()
          .single();

      print('🟢 SupabaseService: Ticket created: $ticketNumber');

      // Add initial message if provided
      if (initialMessage != null && initialMessage.isNotEmpty) {
        await sendSupportMessage(
          ticketId: ticketResponse['id'],
          senderId: userId,
          message: initialMessage,
          senderType: 'customer',
        );
      }

      return ticketResponse;
    } catch (e) {
      print('❌ SupabaseService: Error creating support ticket: $e');
      return null;
    }
  }

  /// Get user's support tickets
  static Future<List<Map<String, dynamic>>> getUserSupportTickets(int userId) async {
    try {
      print('🔵 SupabaseService: Fetching support tickets for user $userId');

      final response = await client
          .from('support_tickets')
          .select()
          .eq('user_id', userId)
          .order('last_message_at', ascending: false);

      print('🟢 SupabaseService: Found ${response.length} tickets');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ SupabaseService: Error fetching support tickets: $e');
      return [];
    }
  }

  /// Get messages for a ticket
  static Future<List<Map<String, dynamic>>> getTicketMessages(int ticketId) async {
    try {
      print('🔵 SupabaseService: Fetching messages for ticket $ticketId');

      final response = await client
          .from('support_messages')
          .select()
          .eq('ticket_id', ticketId)
          .eq('is_deleted', false)
          .order('created_at', ascending: true);

      print('🟢 SupabaseService: Found ${response.length} messages');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ SupabaseService: Error fetching messages: $e');
      return [];
    }
  }

  /// Send a support message
  static Future<Map<String, dynamic>?> sendSupportMessage({
    required int ticketId,
    required int senderId,
    required String message,
    required String senderType,
    int? replyToId,
    String? attachmentUrl,
    String? attachmentPath,
  }) async {
    try {
      print('🔵 SupabaseService: Sending support message');

      final messageData = {
        'ticket_id': ticketId,
        'sender_id': senderId,
        'message': message,
        'sender_type': senderType,
        'message_type': 'text',
        'is_reply': replyToId != null,
        'reply_to_id': replyToId,
        'attachment_url': attachmentUrl,
        'attachment_path': attachmentPath,
        'is_read': false,
      };

      final response = await client
          .from('support_messages')
          .insert(messageData)
          .select()
          .single();

      print('🟢 SupabaseService: Message sent successfully');
      return response;
    } catch (e) {
      print('❌ SupabaseService: Error sending message: $e');
      return null;
    }
  }

  /// Mark message as read
  static Future<void> markMessageAsRead(int messageId) async {
    try {
      await client.rpc('mark_message_as_read', params: {'message_id': messageId});
    } catch (e) {
      print('⚠️ SupabaseService: Error marking message as read: $e');
    }
  }

  /// Get unread message count for a ticket
  static Future<int> getUnreadMessageCount(int ticketId, int userId) async {
    try {
      final result = await client.rpc('get_unread_count', params: {
        'ticket_id_param': ticketId,
        'user_id_param': userId,
      });
      return result as int;
    } catch (e) {
      print('⚠️ SupabaseService: Error getting unread count: $e');
      return 0;
    }
  }

  /// Update ticket status
  static Future<void> updateTicketStatus(int ticketId, String status) async {
    try {
      await client.from('support_tickets').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', ticketId);

      print('🟢 SupabaseService: Ticket status updated to $status');
    } catch (e) {
      print('❌ SupabaseService: Error updating ticket status: $e');
    }
  }

  /// Upload support attachment
  static Future<String?> uploadSupportAttachment(String filePath, int ticketId) async {
    try {
      print('🔵 SupabaseService: Uploading support attachment');

      final file = File(filePath);
      if (!await file.exists()) {
        print('❌ SupabaseService: File does not exist at $filePath');
        return null;
      }

      final bytes = await file.readAsBytes();
      final fileExt = filePath.split('.').last;
      final fileName = 'ticket_${ticketId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final storagePath = 'support_attachments/$fileName';

      await client.storage.from('support-attachments').uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/${fileExt == 'jpg' ? 'jpeg' : fileExt}',
            ),
          );

      final publicUrl = client.storage.from('support-attachments').getPublicUrl(storagePath);

      print('🟢 SupabaseService: Attachment uploaded successfully');
      return publicUrl;
    } catch (e) {
      print('❌ SupabaseService: Error uploading attachment: $e');
      return null;
    }
  }

  /// Subscribe to new messages in a ticket (real-time)
  static RealtimeChannel subscribeToTicketMessages(
    int ticketId,
    Function(Map<String, dynamic>) onNewMessage,
  ) {
    return client
        .channel('ticket_messages_$ticketId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'support_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'ticket_id',
            value: ticketId,
          ),
          callback: (payload) {
            onNewMessage(payload.newRecord);
          },
        )
        .subscribe();
  }

  // ============================================================================
  // NOTIFICATIONS METHODS
  // ============================================================================

  /// Get all notifications for a user
  static Future<List<Map<String, dynamic>>> getNotifications(String userId, {int limit = 50}) async {
    try {
      print('🔵 SupabaseService: Fetching notifications for user $userId');

      final response = await client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      print('🟢 SupabaseService: Fetched ${response.length} notifications');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ SupabaseService: Error fetching notifications: $e');
      return [];
    }
  }

  /// Get unread notifications count
  static Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final result = await client.rpc('get_unread_notification_count', params: {
        'p_user_id': userId,
      });

      return result as int? ?? 0;
    } catch (e) {
      print('❌ SupabaseService: Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark a notification as read
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await client.rpc('mark_notification_read', params: {
        'notification_id': notificationId,
      });

      print('🟢 SupabaseService: Notification marked as read');
      return true;
    } catch (e) {
      print('❌ SupabaseService: Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read for a user
  static Future<int> markAllNotificationsAsRead(String userId) async {
    try {
      final result = await client.rpc('mark_all_notifications_read', params: {
        'p_user_id': userId,
      });

      print('🟢 SupabaseService: Marked ${result ?? 0} notifications as read');
      return result as int? ?? 0;
    } catch (e) {
      print('❌ SupabaseService: Error marking all notifications as read: $e');
      return 0;
    }
  }

  /// Create a new notification
  static Future<String?> createNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'general',
    String? icon,
    String? imageUrl,
    String? actionType,
    Map<String, dynamic>? actionData,
    bool isImportant = false,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await client
          .from('notifications')
          .insert({
            'user_id': userId,
            'title': title,
            'message': message,
            'type': type,
            'icon': icon,
            'image_url': imageUrl,
            'action_type': actionType,
            'action_data': actionData,
            'is_important': isImportant,
            'expires_at': expiresAt?.toIso8601String(),
            'metadata': metadata,
          })
          .select('id')
          .single();

      print('🟢 SupabaseService: Notification created successfully');
      return response['id'] as String;
    } catch (e) {
      print('❌ SupabaseService: Error creating notification: $e');
      return null;
    }
  }

  /// Delete a notification
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      await client
          .from('notifications')
          .delete()
          .eq('id', notificationId);

      print('🟢 SupabaseService: Notification deleted successfully');
      return true;
    } catch (e) {
      print('❌ SupabaseService: Error deleting notification: $e');
      return false;
    }
  }

  /// Delete all read notifications for a user
  static Future<bool> deleteAllReadNotifications(String userId) async {
    try {
      await client
          .from('notifications')
          .delete()
          .eq('user_id', userId)
          .eq('is_read', true);

      print('🟢 SupabaseService: All read notifications deleted');
      return true;
    } catch (e) {
      print('❌ SupabaseService: Error deleting read notifications: $e');
      return false;
    }
  }

  /// Subscribe to new notifications in real-time
  static RealtimeChannel subscribeToNotifications(
    String userId,
    Function(Map<String, dynamic>) onNewNotification,
  ) {
    return client
        .channel('notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            onNewNotification(payload.newRecord);
          },
        )
        .subscribe();
  }
}
