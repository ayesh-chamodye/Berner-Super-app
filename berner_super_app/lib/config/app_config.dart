import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Supabase Configuration
  // Tries dart-define first (release), then .env (dev)
  static String get supabaseUrl {
    const fromDefine = String.fromEnvironment('SUPABASE_URL');
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  static String get supabaseAnonKey {
    const fromDefine = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  // Text.lk SMS API Configuration
  static String get textlkApiToken {
    const fromDefine = String.fromEnvironment('TEXTLK_API_TOKEN');
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.env['TEXTLK_API_TOKEN'] ?? '';
  }

  static String get textlkApiUrl {
    const fromDefine = String.fromEnvironment('TEXTLK_API_URL');
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.env['TEXTLK_API_URL'] ?? 'https://app.text.lk/api/v3';
  }

  static String get textlkHttpApiUrl {
    const fromDefine = String.fromEnvironment('TEXTLK_HTTP_API_URL');
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.env['TEXTLK_HTTP_API_URL'] ?? 'https://app.text.lk/api/http';
  }

  // Validate configuration
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
           supabaseAnonKey.isNotEmpty &&
           textlkApiToken.isNotEmpty;
  }

  // Initialize configuration (loads .env in dev mode)
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      // .env not found - using dart-define values (release mode)
    }
  }
}
