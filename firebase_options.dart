// Firebase configuration for Charlie Chat
// Replace placeholder values with your actual Firebase project configuration
// See FIREBASE_SETUP_GUIDE.md for detailed setup instructions

// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// To configure:
/// 1. Create a Firebase project at https://console.firebase.google.com/
/// 2. Add your app platforms (Android, iOS, Web, Windows, macOS)
/// 3. Replace the placeholder values below with your actual config
/// 4. Run `flutter pub get` to install dependencies
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Web Configuration
  // Get these values from Firebase Console → Project Settings → Web apps
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyYourWebApiKeyHere', // Replace with actual Web API key
    appId: '1:1234567890:web:abcdef1234567890', // Replace with actual Web App ID
    messagingSenderId: '1234567890', // Replace with actual Sender ID
    projectId: 'charliechat-project', // Replace with actual Project ID
    authDomain: 'charliechat-project.firebaseapp.com', // Replace with actual Auth domain
    storageBucket: 'charliechat-project.appspot.com', // Replace with actual Storage bucket
    measurementId: 'G-XXXXXXXXXX', // Replace with actual Measurement ID (optional)
  );

  // Android Configuration
  // Get these values from Firebase Console → Project Settings → Android apps
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyYourAndroidApiKeyHere', // Replace with actual Android API key
    appId: '1:1234567890:android:abcdef1234567890', // Replace with actual Android App ID
    messagingSenderId: '1234567890', // Replace with actual Sender ID
    projectId: 'charliechat-project', // Replace with actual Project ID
    storageBucket: 'charliechat-project.appspot.com', // Replace with actual Storage bucket
  );

  // iOS Configuration
  // Get these values from Firebase Console → Project Settings → iOS apps
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyYourIosApiKeyHere', // Replace with actual iOS API key
    appId: '1:1234567890:ios:abcdef1234567890', // Replace with actual iOS App ID
    messagingSenderId: '1234567890', // Replace with actual Sender ID
    projectId: 'charliechat-project', // Replace with actual Project ID
    storageBucket: 'charliechat-project.appspot.com', // Replace with actual Storage bucket
    iosBundleId: 'com.charliechat.app', // Replace with actual iOS Bundle ID
    iosClientId: '1234567890-abcdef1234567890.apps.googleusercontent.com', // Replace with actual iOS Client ID
  );

  // macOS Configuration
  // Get these values from Firebase Console → Project Settings → macOS apps
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyYourMacosApiKeyHere', // Replace with actual macOS API key
    appId: '1:1234567890:macos:abcdef1234567890', // Replace with actual macOS App ID
    messagingSenderId: '1234567890', // Replace with actual Sender ID
    projectId: 'charliechat-project', // Replace with actual Project ID
    storageBucket: 'charliechat-project.appspot.com', // Replace with actual Storage bucket
    iosBundleId: 'com.charliechat.app', // Replace with actual macOS Bundle ID
    iosClientId: '1234567890-abcdef1234567890.apps.googleusercontent.com', // Replace with actual macOS Client ID
  );

  // Windows Configuration
  // Use Web configuration for Windows (same as web)
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyYourWebApiKeyHere', // Replace with actual Web API key
    appId: '1:1234567890:web:abcdef1234567890', // Replace with actual Web App ID
    messagingSenderId: '1234567890', // Replace with actual Sender ID
    projectId: 'charliechat-project', // Replace with actual Project ID
    authDomain: 'charliechat-project.firebaseapp.com', // Replace with actual Auth domain
    storageBucket: 'charliechat-project.appspot.com', // Replace with actual Storage bucket
    measurementId: 'G-XXXXXXXXXX', // Replace with actual Measurement ID (optional)
  );
}

/// Helper method to validate Firebase configuration
class FirebaseConfigValidator {
  static bool isConfigured() {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      return options.apiKey != 'AIzaSyYourWebApiKeyHere' &&
             options.apiKey != 'AIzaSyYourAndroidApiKeyHere' &&
             options.apiKey != 'AIzaSyYourIosApiKeyHere' &&
             options.apiKey != 'AIzaSyYourMacosApiKeyHere' &&
             options.projectId != 'charliechat-project' &&
             options.appId != '1:1234567890:web:abcdef1234567890';
    } catch (e) {
      return false;
    }
  }

  static List<String> getMissingConfigurations() {
    final options = DefaultFirebaseOptions.currentPlatform;
    final missing = <String>[];
    
    if (options.apiKey.contains('Your') || options.apiKey.contains('Here')) {
      missing.add('API Key');
    }
    if (options.appId.contains('1234567890')) {
      missing.add('App ID');
    }
    if (options.projectId.contains('charliechat-project')) {
      missing.add('Project ID');
    }
    if (options.messagingSenderId.contains('1234567890')) {
      missing.add('Messaging Sender ID');
    }
    
    return missing;
  }

  static void printConfigurationStatus() {
    if (isConfigured()) {
      print('✅ Firebase is properly configured');
    } else {
      print('❌ Firebase is not configured');
      print('Missing configurations: ${getMissingConfigurations().join(', ')}');
      print('Please update firebase_options.dart with your actual Firebase project values');
      print('See FIREBASE_SETUP_GUIDE.md for detailed instructions');
    }
  }
}
