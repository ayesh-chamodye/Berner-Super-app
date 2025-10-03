@echo off
echo ================================================
echo Building Berner Super App - RELEASE APK
echo ================================================
echo.

REM Check if .env exists
if not exist "berner_super_app\.env" (
    echo ERROR: .env file not found!
    echo Please create berner_super_app\.env with your API keys
    pause
    exit /b 1
)

echo Loading environment variables from .env...
echo.

REM Load .env file and set variables
for /f "usebackq tokens=1,2 delims==" %%a in ("berner_super_app\.env") do (
    set %%a=%%b
)

echo Building APK with configuration...
echo.

cd berner_super_app

flutter build apk --release ^
  --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
  --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY% ^
  --dart-define=TEXTLK_API_TOKEN=%TEXTLK_API_TOKEN% ^
  --dart-define=TEXTLK_API_URL=%TEXTLK_API_URL% ^
  --dart-define=TEXTLK_HTTP_API_URL=%TEXTLK_HTTP_API_URL%

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ================================================
    echo ✅ SUCCESS! Release APK built successfully!
    echo ================================================
    echo.
    echo 📦 APK Location:
    echo    build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo 📱 Install on device:
    echo    adb install build\app\outputs\flutter-apk\app-release.apk
    echo.
) else (
    echo.
    echo ================================================
    echo ❌ BUILD FAILED!
    echo ================================================
    echo.
)

cd ..
pause
