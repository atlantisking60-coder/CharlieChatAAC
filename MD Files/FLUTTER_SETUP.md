# Flutter Setup Instructions for Charlie Chat

## Problem
The `launch_preview_win.bat` file is crashing because Flutter is not installed or not properly configured in the system PATH.

## Solution

### 1. Install Flutter
Download and install Flutter from: https://flutter.dev/docs/get-started/install/windows

### 2. Add Flutter to PATH
Add the Flutter `bin` directory to your system PATH environment variable:
- Find your Flutter installation directory (usually `C:\src\flutter\bin`)
- Add this path to your PATH environment variable
- Restart your command prompt/terminal

### 3. Verify Installation
Open a new command prompt and run:
```cmd
flutter --version
flutter doctor
```

### 4. Install Dependencies
Run these commands in the Charlie Chat project directory:
```cmd
flutter pub get
```

### 5. Run the App
Use the fixed batch file:
```cmd
launch_preview_win_fixed.bat
```

## Common Issues

### Windows SDK Missing
- Install Visual Studio 2022 with Windows development tools
- Run `flutter doctor --windows-licenses` if needed

### Build Cache Issues
- The fixed batch file automatically runs `flutter clean` to resolve cache conflicts

### Missing Dependencies
- Run `flutter doctor` to check for missing components
- Follow the instructions provided by Flutter doctor

## Alternative: Web Preview
If Windows desktop development is not set up, you can run the web version:
```cmd
flutter run -d chrome
```

## Files Created
- `launch_preview_win_fixed.bat` - Fixed version with proper Flutter detection
- `check_flutter.bat` - Utility to check Flutter installation
- `MD Files\FLUTTER_SETUP.md` - This setup guide

## Testing
After installing Flutter, test with:
```cmd
check_flutter.bat
```

This will verify your Flutter installation and project setup.
