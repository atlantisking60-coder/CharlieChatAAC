# Charlie Chat Authentication Testing Guide

## Overview

This guide provides comprehensive testing instructions for the Charlie Chat authentication system across all supported platforms.

## Prerequisites

Before testing, ensure:
- Flutter SDK is installed and configured
- Firebase project is set up and configured
- OAuth providers are properly configured
- All dependencies are installed (`flutter pub get`)
- Firebase configuration is updated in `firebase_options.dart`

## Platform Testing Matrix

| Platform | Email/Password | Google | Apple | Microsoft | Guest | Notes |
|----------|----------------|--------|-------|-----------|-------|-------|
| Android | ✅ | ✅ | ❌ | ❌ | ✅ | Requires physical device or emulator |
| iOS | ✅ | ✅ | ✅ | ❌ | ✅ | Requires physical device or simulator |
| Web | ✅ | ✅ | ❌ | ❌ | ✅ | Test in Chrome/Firefox/Safari |
| Windows | ✅ | ✅ | ❌ | ✅ | ✅ | Requires Windows build |
| macOS | ✅ | ✅ | ✅ | ✅ | ✅ | Requires macOS build |

## Testing Environment Setup

### 1. Development Environment

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Check configuration
flutter doctor -v

# Validate Firebase config
dart -c lib/firebase_options.dart
```

### 2. Test Accounts

Create test accounts for each provider:

**Email/Password:**
- Test user: `test@example.com` / `password123`
- Admin user: `admin@example.com` / `admin123`

**Google:**
- Use your personal Google account
- Create a test Google account if needed

**Apple:**
- Use your Apple ID
- Create a test Apple ID if needed

**Microsoft:**
- Use your Microsoft account
- Create a test Microsoft account if needed

## Platform-Specific Testing

### Android Testing

#### Setup
```bash
# List available devices
flutter devices

# Start Android emulator
flutter emulators --launch <emulator_name>

# Or connect physical device
flutter devices
```

#### Test Cases
1. **Email/Password Authentication**
   ```bash
   flutter run -d android
   # Test sign in with valid credentials
   # Test sign in with invalid credentials
   # Test password reset
   # Test account creation
   ```

2. **Google Sign-In**
   ```bash
   flutter run -d android
   # Test Google Sign-In flow
   # Verify user profile is loaded
   # Test sign out and sign in again
   ```

3. **Guest Account**
   ```bash
   flutter run -d android
   # Test guest sign-in
   # Verify limited functionality
   # Test upgrade to full account
   ```

#### Debugging
```bash
# View logs
adb logcat | grep flutter

# Check authentication state
flutter run -d android --verbose
```

### iOS Testing

#### Setup
```bash
# List available devices
flutter devices

# Start iOS simulator
open -a Simulator

# Or connect physical device
flutter devices
```

#### Test Cases
1. **Email/Password Authentication**
   ```bash
   flutter run -d ios
   # Test all email/password flows
   ```

2. **Apple Sign-In**
   ```bash
   flutter run -d ios
   # Test Apple Sign-In flow
   # Verify user information is retrieved
   ```

3. **Google Sign-In**
   ```bash
   flutter run -d ios
   # Test Google Sign-In on iOS
   ```

#### Debugging
```bash
# View iOS logs
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.apple.symptomsd"'

# Check Flutter logs
flutter run -d ios --verbose
```

### Web Testing

#### Setup
```bash
# Enable web support
flutter config --enable-web

# Run web app
flutter run -d chrome
# Or
flutter run -d web-server --web-port=8080
```

#### Test Cases
1. **Browser Compatibility**
   ```bash
   # Test in Chrome
   flutter run -d chrome
   
   # Test in Firefox (manual)
   flutter run -d web-server
   # Open http://localhost:8080 in Firefox
   
   # Test in Safari (manual)
   flutter run -d web-server
   # Open http://localhost:8080 in Safari
   ```

2. **Authentication Flows**
   - Test all authentication methods
   - Verify responsive design
   - Test keyboard navigation
   - Test screen reader compatibility

#### Debugging
```bash
# Check browser console
# Open Developer Tools in browser

# Check Flutter web logs
flutter run -d chrome --verbose
```

### Windows Testing

#### Setup
```bash
# Enable Windows support
flutter config --enable-windows-desktop

# Build Windows app
flutter build windows

# Run Windows app
flutter run -d windows
```

#### Test Cases
1. **Authentication Methods**
   - Email/Password authentication
   - Google Sign-In
   - Microsoft Account authentication
   - Guest accounts

2. **Windows Integration**
   - Test window resizing
   - Test keyboard shortcuts
   - Test accessibility features

#### Debugging
```bash
# Check Windows logs
flutter run -d windows --verbose

# Check Event Viewer for system logs
```

### macOS Testing

#### Setup
```bash
# Enable macOS support
flutter config --enable-macos-desktop

# Build macOS app
flutter build macos

# Run macOS app
flutter run -d macos
```

#### Test Cases
1. **Authentication Methods**
   - All supported providers
   - Apple Sign-In integration
   - Microsoft Account authentication

2. **macOS Integration**
   - Test menu bar integration
   - Test keyboard shortcuts
   - Test Touch ID if available

## Automated Testing

### Unit Tests

```bash
# Run all unit tests
flutter test

# Run specific test file
flutter test test/auth_service_test.dart

# Run with coverage
flutter test --coverage
```

### Integration Tests

```bash
# Run integration tests
flutter test integration_test/

# Run specific integration test
flutter test integration_test/auth_test.dart
```

### Widget Tests

```bash
# Run widget tests
flutter test test/widget/

# Test authentication widgets
flutter test test/widget/auth_screen_test.dart
```

## Test Scenarios

### Positive Test Cases

1. **Successful Authentication**
   - Valid email/password
   - Valid OAuth provider
   - Guest account creation

2. **User Profile Management**
   - Update display name
   - Update photo URL
   - View account information

3. **Session Management**
   - Sign out
   - Automatic sign-in
   - Token refresh

### Negative Test Cases

1. **Invalid Credentials**
   - Wrong password
   - Non-existent email
   - Invalid OAuth token

2. **Network Issues**
   - No internet connection
   - Slow network
   - Timeout scenarios

3. **Edge Cases**
   - Empty credentials
   - Special characters
   - Very long inputs

### Security Test Cases

1. **Session Security**
   - Token expiration
   - Concurrent sessions
   - Session hijacking

2. **Data Validation**
   - Input sanitization
   - SQL injection prevention
   - XSS prevention

## Performance Testing

### Load Testing

```bash
# Test with multiple concurrent users
flutter drive --driver=test_driver/app_test.dart --target=integration_test/load_test.dart
```

### Memory Testing

```bash
# Monitor memory usage
flutter run --profile
# Use Flutter Inspector to monitor memory
```

## Accessibility Testing

### Screen Reader Testing

1. **Android**
   - Enable TalkBack
   - Test navigation
   - Verify labels

2. **iOS**
   - Enable VoiceOver
   - Test navigation
   - Verify labels

3. **Web**
   - Test with screen readers
   - Verify ARIA labels
   - Test keyboard navigation

### Keyboard Navigation

- Tab navigation
- Arrow keys
- Enter/Space activation
- Escape key behavior

## Error Handling Testing

### Network Errors

1. **No Internet**
   - Test offline behavior
   - Verify error messages
   - Test retry functionality

2. **Server Errors**
   - Test 500 errors
   - Test timeout errors
   - Test rate limiting

### Client Errors

1. **Invalid Input**
   - Test validation errors
   - Verify error messages
   - Test recovery scenarios

2. **Permission Errors**
   - Test denied permissions
   - Verify error handling
   - Test permission requests

## Regression Testing

### Automated Regression

```bash
# Run full test suite
flutter test --coverage

# Run integration tests
flutter test integration_test/

# Run performance tests
flutter test test/performance/
```

### Manual Regression

1. **Core Functionality**
   - All authentication methods
   - User profile management
   - Session management

2. **Platform-Specific Features**
   - OAuth provider integration
   - Platform-specific UI
   - Native integrations

## Test Reporting

### Test Results

Create test reports for:

1. **Authentication Success Rates**
   - By platform
   - By provider
   - By scenario

2. **Performance Metrics**
   - Sign-in times
   - Memory usage
   - CPU usage

3. **Error Rates**
   - Network errors
   - Authentication errors
   - Platform-specific errors

### Bug Tracking

Track bugs with:

1. **Severity Levels**
   - Critical (blocking)
   - High (major functionality)
   - Medium (minor issues)
   - Low (cosmetic)

2. **Platform Categories**
   - Android-specific
   - iOS-specific
   - Web-specific
   - Desktop-specific
   - Cross-platform

## Continuous Integration

### CI/CD Pipeline

```yaml
# .github/workflows/test.yml
name: Test Authentication
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test
      - run: flutter test integration_test/
```

### Automated Testing

1. **Unit Tests**: Every commit
2. **Integration Tests**: Every pull request
3. **UI Tests**: Every release
4. **Performance Tests**: Weekly

## Troubleshooting

### Common Issues

1. **Firebase Configuration**
   - Check API keys
   - Verify project ID
   - Check service account permissions

2. **OAuth Configuration**
   - Verify client IDs
   - Check redirect URIs
   - Ensure proper scopes

3. **Platform-Specific Issues**
   - Android: Check SHA-1 fingerprint
   - iOS: Check bundle ID
   - Web: Check CORS settings
   - Desktop: Check native dependencies

### Debug Commands

```bash
# Check Flutter configuration
flutter doctor -v

# Check Firebase configuration
firebase projects:list

# Test Firebase connection
firebase experiments:enable web-frameworks

# Check OAuth configuration
flutter run --verbose
```

## Test Data Management

### Test Users

Create and manage test users:

1. **Firebase Console**
   - Create test users manually
   - Enable/disable test users
   - Reset passwords

2. **Programmatic Creation**
   ```bash
   # Create test users via Firebase Admin SDK
   firebase auth:create-user --email=test@example.com --password=password123
   ```

### Test Data Cleanup

```bash
# Clean up test data
firebase auth:delete test@example.com
firebase firestore:delete --all-collections
```

## Release Testing

### Pre-Release Checklist

- [ ] All authentication methods tested
- [ ] All platforms tested
- [ ] Performance benchmarks met
- [ ] Security tests passed
- [ ] Accessibility tests passed
- [ ] Documentation updated

### Post-Release Monitoring

- Monitor authentication success rates
- Track error rates
- Monitor performance metrics
- Collect user feedback

## Support Resources

- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [Firebase Testing Guide](https://firebase.google.com/docs/test-lab)
- [OAuth Testing Best Practices](https://oauth.net/articles/)
- [Accessibility Testing Guide](https://web.dev/accessibility-testing/)
