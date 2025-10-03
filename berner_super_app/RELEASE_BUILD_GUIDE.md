# 🚀 Release Build Guide - API Keys & Environment Variables

## ⚠️ Problem: `.env` Files Don't Work in Release Builds

The `.env` file is:
- ❌ NOT included in release APK/IPA builds
- ❌ NOT secure (can be extracted from app bundle)
- ❌ Only works in development mode

## ✅ Solution: Use `--dart-define` for Release Builds

Flutter provides `--dart-define` to pass compile-time constants securely.

---

## 📱 Building for Release

### **Option 1: Command Line (One-time build)**

#### Android APK:
```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key-here \
  --dart-define=TEXTLK_API_TOKEN=your-textlk-token-here \
  --dart-define=TEXTLK_API_URL=https://app.text.lk/api/v3 \
  --dart-define=TEXTLK_HTTP_API_URL=https://app.text.lk/api/http
```

#### Android App Bundle (for Google Play):
```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key-here \
  --dart-define=TEXTLK_API_TOKEN=your-textlk-token-here \
  --dart-define=TEXTLK_API_URL=https://app.text.lk/api/v3 \
  --dart-define=TEXTLK_HTTP_API_URL=https://app.text.lk/api/http
```

#### iOS:
```bash
flutter build ios --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key-here \
  --dart-define=TEXTLK_API_TOKEN=your-textlk-token-here \
  --dart-define=TEXTLK_API_URL=https://app.text.lk/api/v3 \
  --dart-define=TEXTLK_HTTP_API_URL=https://app.text.lk/api/http
```

---

### **Option 2: Create Build Script (Recommended)**

Create a file: `build_release.sh` (Linux/Mac) or `build_release.bat` (Windows)

#### Linux/Mac (`build_release.sh`):
```bash
#!/bin/bash

# Load environment variables from .env
export $(cat .env | xargs)

# Build Android APK
flutter build apk --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=TEXTLK_API_TOKEN=$TEXTLK_API_TOKEN \
  --dart-define=TEXTLK_API_URL=$TEXTLK_API_URL \
  --dart-define=TEXTLK_HTTP_API_URL=$TEXTLK_HTTP_API_URL

echo "✅ Release APK built successfully!"
echo "📦 Location: build/app/outputs/flutter-apk/app-release.apk"
```

Make it executable:
```bash
chmod +x build_release.sh
```

Run it:
```bash
./build_release.sh
```

#### Windows (`build_release.bat`):
```batch
@echo off
echo Building Release APK...

REM Read .env file manually or set variables here
set SUPABASE_URL=https://your-project.supabase.co
set SUPABASE_ANON_KEY=your-anon-key-here
set TEXTLK_API_TOKEN=your-textlk-token-here
set TEXTLK_API_URL=https://app.text.lk/api/v3
set TEXTLK_HTTP_API_URL=https://app.text.lk/api/http

flutter build apk --release ^
  --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
  --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY% ^
  --dart-define=TEXTLK_API_TOKEN=%TEXTLK_API_TOKEN% ^
  --dart-define=TEXTLK_API_URL=%TEXTLK_API_URL% ^
  --dart-define=TEXTLK_HTTP_API_URL=%TEXTLK_HTTP_API_URL%

echo ✅ Release APK built successfully!
echo 📦 Location: build\app\outputs\flutter-apk\app-release.apk
pause
```

---

### **Option 3: VS Code Launch Configuration**

Create/update `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter (Dev)",
      "request": "launch",
      "type": "dart",
      "flutterMode": "debug"
    },
    {
      "name": "Flutter (Release)",
      "request": "launch",
      "type": "dart",
      "flutterMode": "release",
      "args": [
        "--dart-define=SUPABASE_URL=https://your-project.supabase.co",
        "--dart-define=SUPABASE_ANON_KEY=your-anon-key-here",
        "--dart-define=TEXTLK_API_TOKEN=your-textlk-token-here",
        "--dart-define=TEXTLK_API_URL=https://app.text.lk/api/v3",
        "--dart-define=TEXTLK_HTTP_API_URL=https://app.text.lk/api/http"
      ]
    }
  ]
}
```

---

## 🔧 Update `app_config.dart`

Your `app_config.dart` needs to support both `.env` (dev) and `--dart-define` (release):

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Helper to get value from dart-define or .env
  static String _getConfig(String key, {String defaultValue = ''}) {
    // First try dart-define (compile-time)
    const dartDefineValue = String.fromEnvironment(key);
    if (dartDefineValue.isNotEmpty) {
      return dartDefineValue;
    }

    // Fallback to .env (runtime - dev only)
    return dotenv.env[key] ?? defaultValue;
  }

  // Supabase Configuration
  static String get supabaseUrl => _getConfig('SUPABASE_URL');
  static String get supabaseAnonKey => _getConfig('SUPABASE_ANON_KEY');

  // Text.lk SMS API Configuration
  static String get textlkApiToken => _getConfig('TEXTLK_API_TOKEN');
  static String get textlkApiUrl => _getConfig('TEXTLK_API_URL', defaultValue: 'https://app.text.lk/api/v3');
  static String get textlkHttpApiUrl => _getConfig('TEXTLK_HTTP_API_URL', defaultValue: 'https://app.text.lk/api/http');

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
      print('⚠️ .env file not found (this is OK for release builds)');
    }
  }
}
```

---

## 🛡️ Security Best Practices

### ✅ DO:
- Use `--dart-define` for release builds
- Keep `.env` file in `.gitignore`
- Store secrets in CI/CD environment variables
- Use different API keys for dev/staging/production
- Rotate API keys regularly

### ❌ DON'T:
- Commit `.env` to git
- Hardcode API keys in source code
- Use production keys in development
- Share API keys in screenshots/logs
- Include `.env` in release builds

---

## 🚀 CI/CD Integration

### GitHub Actions Example:

```yaml
name: Build Release APK

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'

      - name: Install dependencies
        run: flutter pub get

      - name: Build APK
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
          TEXTLK_API_TOKEN: ${{ secrets.TEXTLK_API_TOKEN }}
        run: |
          flutter build apk --release \
            --dart-define=SUPABASE_URL=$SUPABASE_URL \
            --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
            --dart-define=TEXTLK_API_TOKEN=$TEXTLK_API_TOKEN

      - name: Upload APK
        uses: actions/upload-artifact@v3
        with:
          name: app-release.apk
          path: build/app/outputs/flutter-apk/app-release.apk
```

---

## 📝 Quick Reference

| Environment | How to Load Config |
|-------------|-------------------|
| **Development** | `.env` file (loaded via `flutter_dotenv`) |
| **Release Build** | `--dart-define` flags |
| **CI/CD** | Environment secrets → `--dart-define` |

---

## ✅ Verification Checklist

After building for release:

1. [ ] Remove/uninstall any debug version from device
2. [ ] Install release APK
3. [ ] Check logs: No "⚠️ .env file not found" errors
4. [ ] Test OTP sending (text.lk API works)
5. [ ] Test registration (Supabase connection works)
6. [ ] Verify all API calls succeed

---

## 🆘 Troubleshooting

**Problem**: App crashes on startup in release mode
- **Solution**: Check if all required `--dart-define` values are provided

**Problem**: API calls fail with empty URLs
- **Solution**: Verify `--dart-define` values are passed correctly

**Problem**: Build succeeds but config is empty
- **Solution**: Update `app_config.dart` to use `String.fromEnvironment()`

---

## 📚 Additional Resources

- [Flutter Compilation Environment Variables](https://docs.flutter.dev/deployment/flavors#using-environment-variables)
- [Supabase Security Best Practices](https://supabase.com/docs/guides/auth/auth-helpers/flutter)
- [Flutter Release Build Guide](https://docs.flutter.dev/deployment/android)
