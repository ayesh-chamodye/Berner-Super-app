@echo off
echo ================================================
echo Building Berner Super App - RELEASE APP BUNDLE
echo (For Google Play Store Upload)
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

echo Building App Bundle with configuration...
echo.

cd berner_super_app

flutter build appbundle --release ^
  --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
  --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY% ^
  --dart-define=TEXTLK_API_TOKEN=%TEXTLK_API_TOKEN% ^
  --dart-define=TEXTLK_API_URL=%TEXTLK_API_URL% ^
  --dart-define=TEXTLK_HTTP_API_URL=%TEXTLK_HTTP_API_URL%

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ================================================
    echo ✅ SUCCESS! Release App Bundle built successfully!
    echo ================================================
    echo.
    echo 📦 App Bundle Location:
    echo    build\app\outputs\bundle\release\app-release.aab
    echo.
    echo 🚀 Next Steps:
    echo    1. Upload to Google Play Console
    echo    2. Create new release
    echo    3. Upload the .aab file
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
