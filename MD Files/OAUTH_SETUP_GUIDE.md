# OAuth Provider Setup Guide for Charlie Chat

## Overview

This guide explains how to configure OAuth providers for Charlie Chat authentication across all platforms.

## Google Sign-In Configuration

### 1. Google Cloud Console Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Go to "APIs & Services" → "Credentials"
4. Click "Create Credentials" → "OAuth 2.0 Client ID"

### 2. Web Application Credentials

**For Web & Windows:**
- Application type: Web application
- Name: Charlie Chat Web
- Authorized JavaScript origins:
  - `http://localhost:3000`
  - `https://yourdomain.com`
- Authorized redirect URIs:
  - `https://your-project-id.firebaseapp.com/__/auth/handler`
  - `http://localhost:3000`

### 3. Android Credentials

**For Android:**
- Application type: Android
- Name: Charlie Chat Android
- Package name: `com.charliechat.app`
- SHA-1 certificate fingerprint: Get from your keystore

**Get SHA-1 Fingerprint:**
```bash
# Debug keystore
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# Release keystore
keytool -list -v -keystore your-release-key.keystore -alias your-alias
```

### 4. iOS/macOS Credentials

**For iOS & macOS:**
- Application type: iOS
- Name: Charlie Chat iOS
- Bundle ID: `com.charliechat.app`
- Team ID: Your Apple Developer Team ID

### 5. Enable Required APIs

In Google Cloud Console, enable these APIs:
- Google Identity Services API
- Google People API (optional, for user profile)
- Google+ API (if needed)

## Apple Sign-In Configuration

### 1. Apple Developer Portal

1. Go to [Apple Developer Portal](https://developer.apple.com/)
2. Go to "Certificates, Identifiers & Profiles"
3. Select "Identifiers" → Click "+"

### 2. Create App ID

1. Description: Charlie Chat
2. Bundle ID: `com.charliechat.app`
3. Capabilities: Enable "Sign In with Apple"
4. Click "Continue" → "Register"

### 3. Create Services ID

1. Go to "Identifiers" → Click "+"
2. Type: Services ID
3. Description: Charlie Chat Web
4. Identifier: `com.charliechat.web`
5. Return URLs:
   - `https://your-project-id.firebaseapp.com/__/auth/handler`
   - `https://yourdomain.com`

### 4. Configure Sign In with Apple

1. Select your Services ID
2. Check "Sign In with Apple"
3. Configure "Primary App ID" as your main app ID
4. Add return URLs and domains

### 5. Create Private Key

1. Go to "Keys" → Click "+"
2. Key Name: Charlie Chat Auth Key
3. Sign In with Apple: Check
4. Click "Continue" → "Register"
5. Download the .p8 file (save it securely)

### 6. Firebase Configuration

1. In Firebase Console → Authentication → Sign-in method
2. Enable Apple Sign-In
3. Upload your .p8 private key
4. Enter Key ID and Team ID

## Microsoft Account Configuration

### 1. Azure Portal Setup

1. Go to [Azure Portal](https://portal.azure.com/)
2. Go to "Azure Active Directory"
3. Select "App registrations" → Click "New registration"

### 2. Register Application

1. Name: Charlie Chat
2. Supported account types: "Accounts in any organizational directory"
3. Redirect URI: 
   - Platform: Web
   - URI: `https://your-project-id.firebaseapp.com/__/auth/handler`
4. Click "Register"

### 3. Configure Authentication

1. Go to "Authentication" in your app registration
2. Add platform configurations:
   - **Web**: Add redirect URI
   - **SPA**: Add redirect URI for single-page apps
   - **Mobile/Desktop**: Add custom URI scheme: `msauth://com.charliechat.app/oauth2redirect`

### 4. Add API Permissions

1. Go to "API permissions"
2. Click "Add a permission" → "Microsoft Graph"
3. Select "Delegated permissions"
4. Add these permissions:
   - `User.Read`
   - `email`
   - `profile`
   - `openid`

### 5. Create Client Secret

1. Go to "Certificates & secrets"
2. Click "New client secret"
3. Description: Charlie Chat Secret
4. Expiration: Choose appropriate period
5. Copy the secret value immediately (it won't be shown again)

### 6. Firebase Configuration

1. In Firebase Console → Authentication → Sign-in method
2. Enable Microsoft
3. Enter:
   - Client ID: From Azure app registration
   - Client Secret: From Azure app registration
   - Authorized redirect URI: `https://your-project-id.firebaseapp.com/__/auth/handler`

## Platform-Specific Configuration

### Android Configuration

**build.gradle (Project level):**
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

**build.gradle (App level):**
```gradle
apply plugin: 'com.google.gms.google-services'

dependencies {
    implementation 'com.google.firebase:firebase-auth'
    implementation 'com.google.android.gms:play-services-auth:20.7.0'
}
```

**AndroidManifest.xml:**
```xml
<application>
    <meta-data
        android:name="com.google.android.gms.version"
        android:value="@integer/google_play_services_version" />
</application>
```

### iOS Configuration

**Podfile:**
```ruby
pod 'Firebase/Auth'
pod 'GoogleSignIn'
pod 'sign_in_with_apple'
```

**Info.plist:**
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

### Web Configuration

**index.html:**
```html
<script src="https://apis.google.com/js/platform.js" async defer></script>
<script src="https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/en_US/appleid.auth.js" async defer></script>
```

### Windows Configuration

**CMakeLists.txt:**
```cmake
find_package(firebase_auth REQUIRED)
find_package(google_sign_in REQUIRED)
target_link_libraries(${BINARY_NAME} PRIVATE firebase_auth google_sign_in)
```

## Testing OAuth Configuration

### 1. Test Google Sign-In

```bash
# Web
flutter run -d web
# Navigate to app and try Google Sign-In

# Android
flutter run -d android
# Try Google Sign-In on device/emulator

# iOS
flutter run -d ios
# Try Google Sign-In on simulator/device
```

### 2. Test Apple Sign-In

```bash
# iOS/macOS only
flutter run -d ios
# Try Apple Sign-In
```

### 3. Test Microsoft Sign-In

```bash
# All platforms
flutter run -d [platform]
# Try Microsoft Sign-In
```

## Troubleshooting

### Google Sign-In Issues

**"Web client type is required"**
- Check OAuth client configuration
- Ensure correct redirect URIs

**"SHA-1 certificate fingerprint mismatch"**
- Update SHA-1 in Google Cloud Console
- Use correct keystore for release builds

**"API key not authorized"**
- Check API key restrictions
- Ensure correct package name/bundle ID

### Apple Sign-In Issues

**"Invalid Services ID"**
- Verify Services ID configuration
- Check return URLs

**"Team ID not found"**
- Verify Apple Developer membership
- Check Team ID in Firebase

### Microsoft Sign-In Issues

**"Invalid redirect URI"**
- Check Azure app registration
- Verify redirect URI matches exactly

**"Insufficient permissions"**
- Add required API permissions
- Grant admin consent if needed

## Security Best Practices

1. **Use HTTPS** for all redirect URIs
2. **Validate domains** in OAuth provider settings
3. **Use production certificates** for release builds
4. **Store secrets securely** (don't commit to version control)
5. **Implement PKCE** for additional security
6. **Monitor OAuth usage** in provider dashboards

## Environment-Specific Configuration

### Development Environment
```dart
// Use development OAuth clients
const String googleClientId = 'your-dev-google-client-id';
const String appleServiceId = 'com.charliechat.dev';
```

### Production Environment
```dart
// Use production OAuth clients
const String googleClientId = 'your-prod-google-client-id';
const String appleServiceId = 'com.charliechat.app';
```

## Monitoring and Analytics

1. **Google Cloud Console**: Monitor API usage
2. **Apple Developer Console**: Track Sign In with Apple usage
3. **Azure Portal**: Monitor Microsoft Graph API calls
4. **Firebase Console**: Track authentication events

## Support Resources

- [Google Identity Platform](https://developers.google.com/identity)
- [Apple Sign-In Documentation](https://developer.apple.com/sign-in-with-apple/)
- [Microsoft Identity Platform](https://docs.microsoft.com/en-us/azure/active-directory/develop/)
- [Firebase Authentication](https://firebase.google.com/docs/auth)
