# Flutter SDK Setup Guide for Charlie Chat

## 🚀 Step-by-Step Installation

### Step 1: Download Flutter SDK

1. Go to [Flutter SDK Releases](https://flutter.dev/docs/development/tools/sdk-releases#windows)
2. Download the latest **stable** release (e.g., `flutter_windows_3.19.6-stable.zip`)
3. Save the zip file to your Downloads folder

### Step 2: Extract Flutter SDK

1. Open File Explorer
2. Navigate to `C:\` drive
3. Create a new folder named `flutter`
4. Right-click the downloaded zip file and select "Extract All..."
5. Extract to: `C:\flutter`
6. Verify the structure: `C:\flutter\bin\flutter.bat` should exist

### Step 3: Add Flutter to PATH

#### Method A: Using System Properties (Recommended)
1. Press `Windows + R`
2. Type `sysdm.cpl` and press Enter
3. Go to "Advanced" tab
4. Click "Environment Variables..."
5. Under "System variables", find "Path" and click "Edit..."
6. Click "New"
7. Add: `C:\flutter\bin`
8. Click "New" again
9. Add: `C:\flutter\bin\cache\dart-sdk\bin`
10. Click OK on all windows
11. **Restart Command Prompt/PowerShell**

#### Method B: Using Command Prompt (Temporary)
```cmd
set PATH=%PATH%;C:\flutter\bin;C:\flutter\bin\cache\dart-sdk\bin
```

### Step 4: Verify Installation

1. Open a **new** Command Prompt or PowerShell window
2. Run: `flutter --version`
3. You should see output like:
   ```
   Flutter 3.19.6 • channel stable • https://github.com/flutter/flutter.git
   Framework • revision 54e66469f9 (3 weeks ago) • 2024-04-15 13:06:48 -0500
   Engine • revision 8c0c1c9d7a
   Tools • Dart 3.3.3 • DevTools 2.34.3
   ```

4. Run: `flutter doctor`
5. Follow any additional instructions shown

### Step 5: Install Required Components

Based on `flutter doctor` output, install missing components:

#### For Windows Development:
- Install Visual Studio 2022 Community
- Select "Desktop development with C++" workload
- Include Windows 10 SDK

#### For Web Development:
- Install Google Chrome browser

#### For Android Development:
- Install Android Studio
- Install Android SDK
- Create an Android Virtual Device (AVD)

### Step 6: Configure Flutter

1. Enable required platforms:
   ```cmd
   flutter config --enable-web
   flutter config --enable-windows-desktop
   ```

2. Accept Android licenses (if developing for Android):
   ```cmd
   flutter doctor --android-licenses
   ```

### Step 7: Test with Charlie Chat

1. Navigate to Charlie Chat project:
   ```cmd
   cd C:\Users\Craig\Downloads\Charlie Chat
   ```

2. Install dependencies:
   ```cmd
   flutter pub get
   ```

3. Check available devices:
   ```cmd
   flutter devices
   ```

4. Test web preview:
   ```cmd
   flutter run -d chrome
   ```

## 🔧 Troubleshooting

### Common Issues:

#### "Flutter command not found"
**Cause**: Flutter not in PATH or Command Prompt not restarted
**Solution**: 
1. Verify PATH was set correctly
2. Restart Command Prompt/PowerShell
3. Check if `C:\flutter\bin\flutter.bat` exists

#### "Unable to locate adb"
**Cause**: Android SDK not installed or not in PATH
**Solution**: Install Android Studio and Android SDK

#### "Chrome not found"
**Cause**: Chrome browser not installed
**Solution**: Install Google Chrome

#### "Visual Studio not installed"
**Cause**: Missing Visual Studio with C++ workload
**Solution**: Install Visual Studio 2022 with "Desktop development with C++"

#### "License not accepted"
**Cause**: Android licenses not accepted
**Solution**: Run `flutter doctor --android-licenses`

#### "Windows desktop not enabled"
**Cause**: Windows platform not enabled
**Solution**: Run `flutter config --enable-windows-desktop`

### Verification Commands:
```cmd
# Check Flutter version
flutter --version

# Check system requirements
flutter doctor -v

# Check connected devices
flutter devices

# Test web setup
flutter config --enable-web
```

## 📋 Installation Checklist

- [ ] Flutter SDK downloaded from official site
- [ ] Extracted to `C:\flutter`
- [ ] Added `C:\flutter\bin` to PATH
- [ ] Added `C:\flutter\bin\cache\dart-sdk\bin` to PATH
- [ ] Restarted Command Prompt/PowerShell
- [ ] `flutter --version` works
- [ ] `flutter doctor` shows minimal issues
- [ ] Required development tools installed (VS Code/Android Studio/Chrome)
- [ ] Platform support enabled (web, windows, android as needed)
- [ ] Android licenses accepted (if developing for Android)
- [ ] `flutter pub get` works in Charlie Chat project
- [ ] `flutter run -d chrome` works

## 🎯 Post-Installation Steps

After successful installation:

1. **Update Charlie Chat Dependencies**
   ```cmd
   cd C:\Users\Craig\Downloads\Charlie Chat
   flutter pub get
   ```

2. **Test the Application**
   ```cmd
   flutter run -d chrome
   ```

3. **Check IDE Errors**
   - Most Firebase import errors should disappear
   - Remaining type errors should be resolved

## 📞 Additional Resources

- [Flutter Official Installation Guide](https://flutter.dev/docs/get-started/install/windows)
- [Flutter Doctor Troubleshooting](https://flutter.dev/docs/get-started/install/windows#troubleshooting)
- [Android Studio Setup](https://flutter.dev/docs/get-started/install/windows#android-setup)
- [Visual Studio Setup](https://flutter.dev/docs/get-started/install/windows#visual-studio)

## ⚠️ Important Notes

- Always restart Command Prompt/PowerShell after changing PATH
- Use stable Flutter releases for production development
- Keep Flutter updated with `flutter upgrade`
- Run `flutter doctor` regularly to check for issues
- Install Visual Studio 2022 (not 2019) for best compatibility
- Delete the old `flutter` folder in Charlie Chat directory if it still exists

## 🚀 Quick Start Commands

After installation:
```cmd
# Verify installation
flutter --version
flutter doctor

# Setup Charlie Chat
cd C:\Users\Craig\Downloads\Charlie Chat
flutter pub get
flutter devices

# Test app
flutter run -d chrome
```

If all commands work successfully, Flutter is properly installed and ready for Charlie Chat development!
