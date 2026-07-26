# Flutter Installation Guide for Charlie Chat

## Prerequisites

Before installing Flutter, ensure you have:
- Windows 10 or later
- Git for Windows (if not already installed)
- Visual Studio 2022 or Visual Studio Build Tools (for Windows development)
- Android Studio (for Android development)
- Xcode (for iOS development - macOS only)

## Step 1: Download Flutter SDK

1. Go to [Flutter SDK Archive](https://flutter.dev/docs/development/tools/sdk-releases#windows)
2. Download the latest stable Flutter SDK zip file
3. Extract the zip file to `C:\flutter` (recommended location)

## Step 2: Update PATH Environment Variable

1. Press `Windows + R` and type `sysdm.cpl`
2. Go to "Advanced" tab → "Environment Variables"
3. Under "System variables", find "Path" and click "Edit"
4. Click "New" and add `C:\flutter\bin`
5. Click "New" and add `C:\flutter\bin\cache\dart-sdk\bin`
6. Click OK on all windows

## Step 3: Verify Installation

1. Open a new Command Prompt or PowerShell window
2. Run: `flutter doctor`
3. Follow the instructions to fix any issues

## Step 4: Install Required Components

### For Android Development:
1. Install Android Studio
2. Install Android SDK (API level 33 or higher)
3. Create an Android Virtual Device (AVD) or connect a physical device

### For Windows Development:
1. Install Visual Studio 2022 with "Desktop development with C++" workload
2. Ensure Windows 10 SDK is installed

### For Web Development:
1. Install Chrome browser (required for web development)

## Step 5: Configure Flutter

1. Run: `flutter doctor --android-licenses`
2. Accept all Android licenses
3. Run: `flutter doctor` again to verify setup

## Step 6: Install Charlie Chat Dependencies

1. Navigate to Charlie Chat project directory
2. Run: `flutter pub get`
3. Run: `flutter doctor` to verify all dependencies

## Troubleshooting

### Common Issues:

1. **Flutter command not found**
   - Verify PATH is set correctly
   - Restart Command Prompt/PowerShell
   - Check if flutter.bat exists in `C:\flutter\bin`

2. **Android licenses not accepted**
   - Run: `flutter doctor --android-licenses`
   - Type 'y' to accept all licenses

3. **Visual Studio not found**
   - Install Visual Studio 2022 with C++ desktop development workload
   - Run: `flutter doctor --verbose` to check specific issues

4. **Chrome not found**
   - Install Google Chrome
   - Add Chrome to PATH or set CHROME_EXECUTABLE environment variable

## Verification Commands

After installation, run these commands to verify everything works:

```bash
# Check Flutter version
flutter --version

# Check system requirements
flutter doctor

# Check connected devices
flutter devices

# Test web setup
flutter config --enable-web

# Test Windows setup
flutter config --enable-windows-desktop

# Test Android setup
flutter devices
```

## Next Steps

Once Flutter is installed and verified:

1. Navigate to Charlie Chat project: `cd C:\Users\Craig\Downloads\Charlie Chat`
2. Install dependencies: `flutter pub get`
3. Run the app: `flutter run -d windows` (or other target platform)

## Automated Installation Script

For automated installation, you can run this batch file as Administrator:

```batch
@echo off
echo Installing Flutter SDK...

REM Create Flutter directory
if not exist "C:\flutter" mkdir "C:\flutter"

REM Download Flutter (this step needs manual intervention)
echo Please download Flutter SDK from https://flutter.dev/docs/development/tools/sdk-releases#windows
echo Extract to C:\flutter and press any key to continue...
pause

REM Add to PATH
setx PATH "%PATH%;C:\flutter\bin;C:\flutter\bin\cache\dart-sdk\bin" /M

echo Flutter installation completed!
echo Please restart Command Prompt and run 'flutter doctor'
pause
```

## Minimum System Requirements

- **OS**: Windows 10 or later
- **Disk Space**: 2.5 GB (excluding IDE/tools)
- **RAM**: 8 GB recommended
- **Processor**: x86-64 architecture

## IDE Recommendations

- **Android Studio**: Best for Android development
- **Visual Studio Code**: Lightweight with Flutter extensions
- **IntelliJ IDEA**: Full-featured IDE with Flutter plugin

## Performance Tips

1. Use SSD for better performance
2. Close unnecessary applications while developing
3. Use `flutter clean` if遇到 build issues
4. Enable `--release` mode for production builds

## Security Considerations

1. Only download Flutter from official sources
2. Verify checksum of downloaded files
3. Keep Flutter SDK updated
4. Use antivirus software to scan downloads

## Support Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Flutter GitHub Issues](https://github.com/flutter/flutter/issues)
- [Flutter Community](https://flutter.dev/community)
- [Stack Overflow Flutter Tag](https://stackoverflow.com/questions/tagged/flutter)
