# Play Store Preparation Guide

## ✅ Completed Tasks

1. **App Name Updated**: Changed from "berner_super_app" to "Berner Super App" in AndroidManifest.xml
2. **Debug Banner Removed**: Already configured in main.dart with `debugShowCheckedModeBanner: false`
3. **Native Splash Screen**: Configured with app branding colors (orange background)
4. **Custom Splash Screen**: Already implemented in splash_screen.dart with animations

## 🎨 App Icon Setup

### Option 1: Using Online Icon Generator (Recommended)

1. **Visit**: https://icon.kitchen or https://appicon.co
2. **Upload**: The image you provided (the orange background with the B logo)
3. **Configure**:
   - Background: #F47D4A (orange)
   - Style: Adaptive Icon
   - Platform: Android
4. **Download**: The generated icon package
5. **Extract**: The downloaded ZIP file
6. **Copy**: All mipmap folders to `android/app/src/main/res/`

### Option 2: Using Flutter Launcher Icons Package

Since SVG isn't supported, you need to convert your logo to PNG first:

1. **Convert SVG to PNG**:
   - Visit: https://svgtopng.com or use GIMP/Inkscape
   - Upload: `assets/images/app_icon.svg`
   - Size: 1024x1024 pixels
   - Save as: `assets/images/app_icon.png`

2. **Generate Icons**:
   ```bash
   flutter pub get
   dart run flutter_launcher_icons
   ```

### Option 3: Manual Icon Placement

If you have PNG icons in different sizes, place them manually:

- `mipmap-mdpi/ic_launcher.png` - 48x48
- `mipmap-hdpi/ic_launcher.png` - 72x72
- `mipmap-xhdpi/ic_launcher.png` - 96x96
- `mipmap-xxhdpi/ic_launcher.png` - 144x144
- `mipmap-xxxhdpi/ic_launcher.png` - 192x192

## 📱 Build Release APK/AAB

### For APK (Testing):
```bash
flutter build apk --release
```

### For App Bundle (Play Store Upload):
```bash
flutter build appbundle --release
```

The output will be in:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

## 🔑 App Signing (Required for Play Store)

### 1. Generate Keystore (First Time Only):
```bash
keytool -genkey -v -keystore e:\Berner Super app\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 2. Create key.properties:
Create `android/key.properties`:
```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=e:\\Berner Super app\\upload-keystore.jks
```

### 3. Update build.gradle:
Edit `android/app/build.gradle` - add before `android {`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

Then update `buildTypes`:
```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
buildTypes {
    release {
        signingConfig signingConfigs.release
    }
}
```

## 📋 Pre-Upload Checklist

- [ ] App icon replaced with custom logo
- [ ] App name is "Berner Super App"
- [ ] Debug banner removed ✅
- [ ] Splash screen customized ✅
- [ ] App signed with release keystore
- [ ] Version number set correctly in pubspec.yaml (currently 1.0.0+1)
- [ ] All permissions in AndroidManifest.xml are necessary
- [ ] Privacy policy URL ready (if using permissions)
- [ ] Screenshots prepared (phone and tablet)
- [ ] Feature graphic (1024x500) created
- [ ] App description written
- [ ] Test release build on real device

## 🚀 Play Store Requirements

1. **Screenshots**: Minimum 2, maximum 8 (phone: 16:9 or 9:16)
2. **Feature Graphic**: 1024x500 PNG/JPG
3. **High-res Icon**: 512x512 PNG (32-bit with alpha)
4. **Privacy Policy**: Required if app uses sensitive permissions
5. **Content Rating**: Complete questionnaire
6. **Target API Level**: Minimum API 21 (already set)

## 🛠️ Testing Before Upload

```bash
# Build release APK
flutter build apk --release

# Install on device
adb install build/app/outputs/flutter-apk/app-release.apk

# Test all features:
- OTP login
- Profile setup
- Expense tracking
- Weather feature
- Theme switching
- All navigation flows
```

## 📝 Notes

- Keep your keystore file safe! Loss means you can't update your app
- Add keystore to .gitignore
- Store passwords securely (password manager)
- Test signing before uploading to Play Store

## 🎯 Current Status

✅ App is ready for Play Store EXCEPT:
- Need to replace default Flutter icon with your custom logo
- Need to sign the app with release keystore

Once you complete these two steps, you can upload to Play Store!
