# Firebase Project Setup Guide for Charlie Chat

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `Charlie Chat`
4. Enable Google Analytics (recommended)
5. Click "Create project"

## Step 2: Add Firebase to Web App

1. In Firebase Console, go to Project Settings
2. Click "Add app" → Web
3. App nickname: `Charlie Chat Web`
4. Register app
5. Copy the `firebaseConfig` object
6. Replace placeholder values in `firebase_options.dart`

## Step 3: Configure Authentication

1. In Firebase Console, go to "Authentication" → "Sign-in method"
2. Enable the following providers:
   - **Email/Password**: Enable
   - **Google**: Enable, configure OAuth consent screen
   - **Apple**: Enable (for iOS/macOS, requires Apple Developer account)
   - **Microsoft**: Enable (requires Azure AD setup)
   - **Anonymous**: Enable (for guest access)

## Step 4: Add Firebase to Android (if targeting Android)

1. In Firebase Console, go to Project Settings
2. Click "Add app" → Android
3. Package name: `com.charliechat.app` (or your actual package name)
4. Download `google-services.json`
5. Place it in `android/app/google-services.json`

### Android Configuration
Add to `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

Add to `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'

dependencies {
    implementation 'com.google.firebase:firebase-auth'
    implementation 'com.google.android.gms:play-services-auth:20.7.0'
}
```

## Step 4: Add Firebase to iOS

1. In Firebase Console, click "Add app" → iOS
2. Bundle ID: `com.charliechat.app` (or your actual bundle ID)
3. Download `GoogleService-Info.plist`
4. Add to `ios/Runner/GoogleService-Info.plist`

### iOS Configuration
Add to `ios/Podfile`:
```ruby
pod 'Firebase/Auth'
pod 'GoogleSignIn'
```

Add to `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

## Step 5: Add Firebase to Web

1. In Firebase Console, click "Add app" → Web
2. App nickname: `Charlie Chat Web`
3. Copy Firebase config object
4. Add to `web/index.html`:
```html
<script src="https://www.gstatic.com/firebasejs/9.6.1/firebase-app.js"></script>
<script src="https://www.gstatic.com/firebasejs/9.6.1/firebase-auth.js"></script>
```

## Step 6: Add Firebase to Windows

1. In Firebase Console, click "Add app" → Web
2. Use same web configuration
3. Add to `windows/runner/CMakeLists.txt`:
```cmake
find_package(firebase_auth REQUIRED)
target_link_libraries(${BINARY_NAME} PRIVATE firebase_auth)
```

## Step 7: Configure OAuth Providers

### Google Sign-In
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Go to "APIs & Services" → "Credentials"
4. Create OAuth 2.0 Client ID:
   - Application type: Web application
   - Authorized redirect URIs:
     - `https://charliechat.firebaseapp.com/__/auth/handler`
     - `http://localhost:3000` (for development)

### Apple Sign-In
1. Go to [Apple Developer Portal](https://developer.apple.com/)
2. Go to "Certificates, Identifiers & Profiles"
3. Create App ID with "Sign In with Apple" capability
4. Create Services ID:
   - Description: `Charlie Chat`
   - Return URLs:
     - `https://charliechat.firebaseapp.com/__/auth/handler`

### Microsoft Account
1. Go to [Azure Portal](https://portal.azure.com/)
2. Go to "Azure Active Directory" → "App registrations"
3. New registration:
   - Name: `Charlie Chat`
   - Redirect URI: `msauth://com.charliechat.app/oauth2redirect`
4. Add Microsoft Graph permissions

## Step 8: Update Firebase Configuration

Replace the placeholder values in `firebase_options.dart` with your actual Firebase config:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'your-actual-web-api-key',
  appId: 'your-actual-web-app-id',
  messagingSenderId: 'your-actual-sender-id',
  projectId: 'your-actual-project-id',
  authDomain: 'your-project-id.firebaseapp.com',
  storageBucket: 'your-project-id.appspot.com',
);
```

## Step 9: Security Rules

### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Authenticated users can read public data
    match /public/{document} {
      allow read: if request.auth != null;
    }
  }
}
```

### Realtime Database Security Rules
```javascript
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    },
    "public": {
      ".read": "auth != null"
    }
  }
}
```

## Step 10: Enable Additional Services

### Cloud Firestore
1. Go to "Firestore Database" → "Create database"
2. Choose production mode or test mode
3. Select location

### Cloud Storage
1. Go to "Storage" → "Get started"
2. Follow the setup wizard
3. Configure security rules

### Hosting
1. Go to "Hosting" → "Get started"
2. Install Firebase CLI: `npm install -g firebase-tools`
3. Deploy: `firebase deploy`

## Step 11: Test Configuration

1. Run `flutter pub get` to install dependencies
2. Run `flutter run -d web` to test web configuration
3. Run `flutter run -d android` to test Android configuration
4. Run `flutter run -d ios` to test iOS configuration

## Troubleshooting

### Common Issues:

1. **"google-services.json not found"**
   - Ensure file is in `android/app/` directory
   - Clean and rebuild: `flutter clean && flutter run`

2. **"Google Sign-In failed"**
   - Check SHA-1 fingerprint in Firebase Console
   - Verify OAuth client ID configuration
   - Ensure package name matches

3. **"Apple Sign-In not working"**
   - Verify App ID configuration
   - Check Services ID setup
   - Ensure team membership

4. **"Microsoft Sign-In failed"**
   - Check Azure app registration
   - Verify redirect URI
   - Ensure API permissions

### Debug Commands:

```bash
# Check Firebase configuration
flutter packages pub run build_runner build

# Clean build
flutter clean

# Check dependencies
flutter doctor -v

# Test specific platform
flutter run -d android --verbose
flutter run -d web --verbose
```

## Production Checklist

- [ ] Enable Google Analytics
- [ ] Configure production security rules
- [ ] Set up monitoring and alerts
- [ ] Enable App Check
- [ ] Configure crash reporting
- [ ] Set up performance monitoring
- [ ] Configure A/B testing
- [ ] Enable remote config

## Environment Variables

For development, you can use environment variables:

```bash
export FIREBASE_API_KEY="your-api-key"
export FIREBASE_PROJECT_ID="your-project-id"
export FIREBASE_APP_ID="your-app-id"
```

## Support Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/docs)
- [Firebase Support](https://firebase.google.com/support)
- [Stack Overflow Firebase Tag](https://stackoverflow.com/questions/tagged/firebase)
