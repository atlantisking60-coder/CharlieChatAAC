# Charlie Chat Cross-Platform Authentication Setup Guide

This guide explains how to set up and configure the cross-platform authentication system for Charlie Chat.

## Overview

The authentication system supports:
- **Platforms**: Android, iOS, Web, Windows, macOS
- **Methods**: Email/Password, Google Sign-In, Apple Sign-In, Microsoft Account, Anonymous Guest Accounts
- **Backend**: Firebase Authentication with Riverpod state management

## Architecture

### Core Components

1. **AuthService** (`lib/services/auth_service.dart`)
   - Handles all authentication operations
   - Supports multiple providers
   - Cross-platform compatibility

2. **AuthProvider** (`lib/providers/auth_provider.dart`)
   - Riverpod state management
   - Reactive authentication state
   - Error handling and loading states

3. **AuthScreen** (`lib/widgets/auth_screen.dart`)
   - Unified authentication UI
   - Platform-specific provider selection
   - Form validation and error display

4. **AuthGuard** (`lib/widgets/auth_guard.dart`)
   - Authentication state wrapper
   - Navigation protection
   - Loading and error states

## Firebase Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing one
3. Enable Authentication in the Firebase Console
4. Configure sign-in methods:
   - Email/Password: Enable
   - Google: Enable
   - Apple: Enable (for iOS platforms)
   - Anonymous: Enable

### 2. Configure Platforms

#### Android
```bash
# Add Firebase config
flutterfire configure
```

Add to `android/app/build.gradle`:
```gradle
dependencies {
    implementation 'com.google.firebase:firebase-auth'
    implementation 'com.google.android.gms:play-services-auth:20.7.0'
}
```

#### iOS
1. Add Firebase SDK to `ios/Podfile`:
```ruby
pod 'Firebase/Auth'
pod 'GoogleSignIn'
```

2. Configure `ios/Runner/Info.plist`:
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

#### Web
1. Add Firebase SDK to `web/index.html`:
```html
<script src="https://www.gstatic.com/firebasejs/9.6.1/firebase-app.js"></script>
<script src="https://www.gstatic.com/firebasejs/9.6.1/firebase-auth.js"></script>
```

#### Windows/macOS
1. Configure Firebase for desktop platforms
2. Add Microsoft Identity Platform support

### 3. Update Firebase Configuration

Replace placeholder values in `firebase_options.dart`:
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

## Platform-Specific Configuration

### Google Sign-In

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Enable Google Sign-In API
4. Create OAuth 2.0 credentials
5. Add authorized redirect URIs for each platform

### Apple Sign-In

1. Go to [Apple Developer Portal](https://developer.apple.com/)
2. Enable Sign in with Apple
3. Create App ID with Sign in with Apple capability
4. Configure Services ID

### Microsoft Account

1. Go to [Azure Portal](https://portal.azure.com/)
2. Register new application
3. Add Microsoft Graph permissions
4. Configure redirect URI

## Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  google_sign_in: ^6.2.1
  sign_in_with_apple: ^6.1.1
  microsoft_identity_flutter: ^1.0.0
  flutter_riverpod: ^2.4.9
  flutter_secure_storage: ^9.0.0
  crypto: ^3.0.3
```

## Usage

### Basic Authentication Flow

```dart
// Watch authentication state
final authState = ref.watch(authProvider);

// Sign in with email/password
await ref.read(authProvider.notifier).signInWithEmailPassword(
  'user@example.com',
  'password123',
);

// Sign in with Google
await ref.read(authProvider.notifier).signInWithGoogle();

// Sign out
await ref.read(authProvider.notifier).signOut();
```

### Protected Routes

The `AuthGuard` widget automatically protects routes:

```dart
return AuthAwareApp(
  app: MaterialApp(
    // Your app configuration
  ),
);
```

### Access Current User

```dart
final user = ref.watch(currentUserProvider);
if (user != null) {
  print('User is authenticated: ${user.email}');
}
```

## Platform Detection

The system automatically detects platform capabilities:

```dart
final supportedProviders = PlatformUtils.supportedProviders;
// Returns available providers for current platform
```

## Error Handling

Authentication errors are handled automatically:

```dart
final authState = ref.watch(authProvider);
authState.when(
  error: (error) => showErrorDialog(error),
  // ... other states
);
```

## Security Features

1. **Secure Storage**: Uses `flutter_secure_storage` for sensitive data
2. **Token Management**: Automatic token refresh and cleanup
3. **Platform Security**: Uses platform-specific secure authentication
4. **Session Management**: Proper session handling and timeout

## Testing

### Unit Tests

```dart
test('sign in with email password', () async {
  final authNotifier = AuthNotifier(mockAuthService);
  await authNotifier.signInWithEmailPassword('test@example.com', 'password');
  expect(authNotifier.state.isAuthenticated, true);
});
```

### Integration Tests

Test on all target platforms:
- Android emulator/device
- iOS simulator/device
- Web browser
- Windows desktop
- macOS desktop

## Troubleshooting

### Common Issues

1. **Firebase not initialized**: Ensure `Firebase.initializeApp()` is called
2. **Google Sign-In fails**: Check OAuth configuration and SHA-1 fingerprint
3. **Apple Sign-In not working**: Verify App ID and Services ID configuration
4. **Microsoft Sign-In fails**: Check Azure app registration and redirect URI

### Debug Mode

Enable debug logging:
```dart
await FirebaseAuth.instance.setSettings(
  appVerificationDisabledForTesting: true,
);
```

## Migration Guide

### From Existing Auth System

1. Replace existing auth service calls with `AuthProvider`
2. Update UI to use `AuthScreen` and `AuthGuard`
3. Migrate user data to Firebase if needed
4. Update navigation to use authentication guards

## Performance Considerations

1. **Lazy Loading**: Auth state is loaded only when needed
2. **Caching**: User sessions are cached securely
3. **Network Optimization**: Minimal API calls for authentication
4. **Memory Management**: Proper cleanup of authentication resources

## Future Enhancements

1. **Biometric Authentication**: Add fingerprint/face ID support
2. **Multi-Factor Authentication**: Add 2FA support
3. **Social Providers**: Add Facebook, Twitter, etc.
4. **Enterprise SSO**: Add SAML/OIDC support
5. **Offline Support**: Add offline authentication capabilities

## Support

For issues and questions:
1. Check Firebase documentation
2. Review platform-specific setup guides
3. Consult FlutterFire documentation
4. Check existing GitHub issues

## License

This authentication system is part of Charlie Chat and follows the same license terms.
