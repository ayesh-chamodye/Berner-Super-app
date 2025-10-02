import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class TextLkSmsService {
  // Send OTP SMS using text.lk API (EXTERNAL SMS GATEWAY - NOT SUPABASE)
  static Future<Map<String, dynamic>> sendOTP({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      print('📡 text.lk: Preparing to send OTP SMS');
      final url = Uri.parse('${AppConfig.textlkApiUrl}/sms/send');

      // Format phone number (ensure it starts with country code)
      String formattedPhone = phoneNumber;
      if (phoneNumber.startsWith('0')) {
        formattedPhone = '94${phoneNumber.substring(1)}'; // Sri Lanka country code
      } else if (!phoneNumber.startsWith('94')) {
        formattedPhone = '94$phoneNumber';
      }

      print('📡 text.lk: Sending SMS to: $formattedPhone');
      print('📡 text.lk: API URL: ${AppConfig.textlkApiUrl}/sms/send');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${AppConfig.textlkApiToken}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'recipient': formattedPhone,
          'sender_id': 'BernerLanka', // You can customize this
          'message': 'Your Berner Super App verification code is: $otp. Valid for 5 minutes.',
        }),
      );

      final responseData = jsonDecode(response.body);
      print('📡 text.lk: Response status code: ${response.statusCode}');
      print('📡 text.lk: Response body: $responseData');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ text.lk: SMS sent successfully via text.lk API');
        return {
          'success': true,
          'message': 'OTP sent successfully',
          'data': responseData,
        };
      } else {
        print('❌ text.lk: SMS sending failed');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to send OTP',
          'error': responseData,
        };
      }
    } catch (e) {
      print('❌ text.lk: Error occurred: $e');
      return {
        'success': false,
        'message': 'Error sending OTP: $e',
        'error': e.toString(),
      };
    }
  }

  // Send custom SMS
  static Future<Map<String, dynamic>> sendSMS({
    required String phoneNumber,
    required String message,
    String? senderId,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.textlkApiUrl}/sms/send');

      // Format phone number
      String formattedPhone = phoneNumber;
      if (phoneNumber.startsWith('0')) {
        formattedPhone = '94${phoneNumber.substring(1)}';
      } else if (!phoneNumber.startsWith('94')) {
        formattedPhone = '94$phoneNumber';
      }

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${AppConfig.textlkApiToken}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'recipient': formattedPhone,
          'sender_id': senderId ?? 'BernerApp',
          'message': message,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'SMS sent successfully',
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to send SMS',
          'error': responseData,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error sending SMS: $e',
        'error': e.toString(),
      };
    }
  }

  // Send bulk SMS
  static Future<Map<String, dynamic>> sendBulkSMS({
    required List<String> phoneNumbers,
    required String message,
    String? senderId,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.textlkApiUrl}/sms/send-bulk');

      // Format all phone numbers
      final formattedPhones = phoneNumbers.map((phone) {
        if (phone.startsWith('0')) {
          return '94${phone.substring(1)}';
        } else if (!phone.startsWith('94')) {
          return '94$phone';
        }
        return phone;
      }).toList();

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${AppConfig.textlkApiToken}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'recipients': formattedPhones,
          'sender_id': senderId ?? 'BernerApp',
          'message': message,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Bulk SMS sent successfully',
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to send bulk SMS',
          'error': responseData,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error sending bulk SMS: $e',
        'error': e.toString(),
      };
    }
  }

  // Check SMS balance (if API supports it)
  static Future<Map<String, dynamic>> checkBalance() async {
    try {
      final url = Uri.parse('${AppConfig.textlkApiUrl}/account/balance');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${AppConfig.textlkApiToken}',
          'Accept': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to check balance',
          'error': responseData,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error checking balance: $e',
        'error': e.toString(),
      };
    }
  }

  // Format phone number helper
  static String formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.startsWith('0')) {
      return '94${phoneNumber.substring(1)}';
    } else if (!phoneNumber.startsWith('94')) {
      return '94$phoneNumber';
    }
    return phoneNumber;
  }

  // Validate Sri Lankan phone number
  static bool isValidSriLankanPhone(String phoneNumber) {
    // Remove spaces and special characters
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Check various formats
    if (cleanNumber.startsWith('0') && cleanNumber.length == 10) {
      return true; // 0771234567
    } else if (cleanNumber.startsWith('94') && cleanNumber.length == 11) {
      return true; // 94771234567
    } else if (cleanNumber.startsWith('+94') && cleanNumber.length == 12) {
      return true; // +94771234567
    }

    return false;
  }
}
