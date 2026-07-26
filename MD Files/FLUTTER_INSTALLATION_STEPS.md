# Flutter Installation Steps for Charlie Chat

## 🚀 Quick Installation Guide

### Step 1: Download Flutter SDK
1. Go to [Flutter SDK Archive](https://flutter.dev/docs/development/tools/sdk-releases#windows)
2. Download the latest **stable** Flutter SDK zip file (e.g., `flutter_windows_3.19.6-stable.zip`)
3. Save it to your Downloads folder

### Step 2: Extract Flutter SDK
1. Create a folder `C:\flutter` if it doesn't exist
2. Right-click the downloaded zip file and select "Extract All..."
3. Extract to `C:\flutter`
4. Verify the structure: `C:\flutter\bin\flutter.bat` should exist

### Step 3: Add Flutter to PATH
1. Press `Windows + R`, type `sysdm.cpl`, press Enter
2. Go to "Advanced" tab → "Environment Variables..."
3. Under "System variables", find "Path" and click "Edit..."
4. Click "New" and add: `C:\flutter\bin`
5. Click "New" and add: `C:\flutter\bin\cache\dart-sdk\bin`
6. Click OK on all windows
7. **Restart Command Prompt/PowerShell** (important!)

### Step 4: Verify Installation
1. Open a **new** Command Prompt or PowerShell window
2. Run: `flutter --version`
3. You should see Flutter version information
4. Run: `flutter doctor`
5. Follow any additional instructions shown

### Step 5: Install Required Components
Based on `flutter doctor` output, install any missing components:

#### For Windows Development:
- Install Visual Studio 2022 with "Desktop development with C++" workload
- Install Windows 10 SDK

#### For Web Development:
- Install Google Chrome browser

#### For Android Development:
- Install Android Studio
- Install Android SDK
- Create an Android Virtual Device (AVD)

### Step 6: Configure Flutter
1. Run: `flutter doctor --android-licenses` (for Android development)
2. Accept all licenses by typing 'y'
3. Enable required platforms:
   ```bash
   flutter config --enable-web
   flutter config --enable-windows-desktop
   ```

### Step 7: Test Installation
1. Navigate to Charlie Chat project:
   ```bash
   cd C:\Users\Craig\Downloads\Charlie Chat
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Test web preview:
   ```bash
   launch_preview_web.bat
   ```

## 🔧 Troubleshooting

### Common Issues:

#### "Flutter command not found"
- **Cause**: Flutter not in PATH
- **Solution**: 
  1. Verify PATH was set correctly
  2. Restart Command Prompt/PowerShell
  3. Check if `C:\flutter\bin\flutter.bat` exists

#### "Unable to locate adb"
- **Cause**: Android SDK not installed or not in PATH
- **Solution**: Install Android Studio and Android SDK

#### "Chrome not found"
- **Cause**: Chrome browser not installed
- **Solution**: Install Google Chrome

#### "Visual Studio not installed"
- **Cause**: Missing Visual Studio with C++ workload
- **Solution**: Install Visual Studio 2022 with "Desktop development with C++"

#### "License not accepted"
- **Cause**: Android licenses not accepted
- **Solution**: Run `flutter doctor --android-licenses`

### Verification Commands:
```bash
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
- [ ] `launch_preview_web.bat` works

## 🎯 Next Steps After Installation

1. **Install Charlie Chat Dependencies**
   ```bash
   cd C:\Users\Craig\Downloads\Charlie Chat
   flutter pub get
   ```

2. **Fix Remaining Type Errors**
   - The IDE should now show fewer errors
   - Fix remaining AuthProvider type issues

3. **Test the Application**
   ```bash
   launch_preview_web.bat
   ```

4. **Configure Firebase** (if using real authentication)
   - Follow `FIREBASE_SETUP_GUIDE.md`

## 📞 Additional Resources

- [Flutter Official Installation Guide](https://flutter.dev/docs/get-started/install/windows)
- [Flutter Doctor Troubleshooting](https://flutter.dev/docs/get-started/install/windows#troubleshooting)
- [Android Studio Setup](https://flutter.dev/docs/get-started/install/windows#android-setup)

## ⚠️ Important Notes

- Always restart Command Prompt/PowerShell after changing PATH
- Use stable Flutter releases for production development
- Keep Flutter updated with `flutter upgrade`
- Run `flutter doctor` regularly to check for issues
- Install Visual Studio 2022 (not 2019) for best compatibility

## 🚀 Quick Test Commands

After installation, test with these commands:
```bash
# Basic test
flutter --version

# Comprehensive check
flutter doctor

# Test in Charlie Chat project
cd C:\Users\Craig\Downloads\Charlie Chat
flutter pub get
flutter devices
launch_preview_web.bat
```

If all commands work successfully, Flutter is properly installed and ready for Charlie Chat development!
