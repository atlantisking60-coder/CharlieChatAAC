# Platform Configuration for Cross-Device Support

## Android Configuration

To enable broad Android device support (API 21+), run:

```bash
cd "C:\Users\Craig\Downloads\AppCreation"
flutter create --platforms android .
```

Then edit `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.example.charliechat"
        minSdkVersion 21        # Android 5.0+ (supports 99% of devices)
        targetSdkVersion 34
        versionCode 1
        versionName "0.1.0"
    }
}
```

### Android Permissions (android/app/src/main/AndroidManifest.xml)

Add these permissions for file access and storage:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.INTERNET" />
```

For Android 6.0+, runtime permissions are handled by Flutter plugins automatically.

---

## iOS Configuration

To enable broad iOS device support (iOS 12.0+), run:

```bash
cd "C:\Users\Craig\Downloads\AppCreation"
flutter create --platforms ios .
```

Then edit `ios/Podfile`:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
      ]
    end
  end
end
```

### iOS Info.plist

Add these keys to `ios/Runner/Info.plist`:

```xml
<!-- Microphone usage for TTS input -->
<key>NSMicrophoneUsageDescription</key>
<string>Charlie Chat needs microphone access for voice communication features.</string>

<!-- File access -->
<key>NSDocumentUsageDescription</key>
<string>Charlie Chat needs access to files on your device.</string>

<!-- Camera for potential future features -->
<key>NSCameraUsageDescription</key>
<string>Charlie Chat needs camera access for symbol creation.</string>

<!-- Deployment target -->
<key>MinimumOSVersion</key>
<string>12.0</string>
```

Also update `ios/Podfile`:

```ruby
platform :ios, '12.0'
```

---

## Web Configuration

Web support is already configured. To build for web:

```bash
flutter build web --web-renderer canvaskit
```

The app supports:
- **Chrome** 90+
- **Firefox** 88+
- **Safari** 14+
- **Edge** 90+
- **Mobile browsers** (iOS Safari 12+, Chrome Mobile 90+)

---

## Summary of Supported Versions

| Platform | Minimum Version | Market Share |
|----------|-----------------|--------------|
| Android  | 5.0 (API 21)    | ~99%         |
| iOS      | 12.0            | ~95%         |
| Web      | All modern      | 100%         |

---

## How to Run on Each Platform

### Web (Easiest - works now)
```bash
flutter run -d chrome
```

### Android (requires Android Studio + emulator or device)
```bash
flutter run -d android
```

### iOS (requires macOS + Xcode)
```bash
flutter run -d ios
```

---

## Next Steps

1. Run `flutter create --platforms android,ios .` to generate native project directories
2. Follow the Android and iOS configuration steps above
3. Update `android/app/build.gradle` with minSdkVersion 21
4. Update `ios/Podfile` with platform :ios, '12.0'
5. Run `flutter pub get` to sync dependencies
6. Test on each platform using `flutter run -d <device>`
