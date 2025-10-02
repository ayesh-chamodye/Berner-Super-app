import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Supabase Configuration
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Text.lk SMS API Configuration
  static String get textlkApiToken => dotenv.env['TEXTLK_API_TOKEN'] ?? '';
  static String get textlkApiUrl => dotenv.env['TEXTLK_API_URL'] ?? 'https://app.text.lk/api/v3';
  static String get textlkHttpApiUrl => dotenv.env['TEXTLK_HTTP_API_URL'] ?? 'https://app.text.lk/api/http';

  // Validate configuration
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
           supabaseAnonKey.isNotEmpty &&
           textlkApiToken.isNotEmpty;
  }

  // Initialize configuration
  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
  }
}
