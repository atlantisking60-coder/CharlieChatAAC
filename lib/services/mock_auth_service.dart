import 'dart:async';
import 'dart:io';

/// Mock authentication service for development without Firebase
/// This will be replaced with the real Firebase service once dependencies are installed
class MockAuthService {
  static final MockAuthService _instance = MockAuthService._internal();
  factory MockAuthService() => _instance;
  MockAuthService._internal();

  // Stream controller for authentication state
  final StreamController<MockAuthUser?> _authStateController = 
      StreamController<MockAuthUser?>.broadcast();
  
  Stream<MockAuthUser?> get authStateChanges => _authStateController.stream;
  
  MockAuthUser? get currentUser => _currentUser;
  MockAuthUser? _currentUser;

  /// Initialize the authentication service
  Future<void> initialize() async {
    // Simulate initialization delay
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Sign in with email and password
  Future<MockAuthResult> signInWithEmailPassword(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    
    if (email == 'test@example.com' && password == 'password123') {
      _currentUser = MockAuthUser(
        uid: 'mock-user-123',
        email: email,
        displayName: 'Test User',
        isAnonymous: false,
        isEmailVerified: true,
        providerId: 'password',
      );
      _authStateController.add(_currentUser);
      return MockAuthResult.success(_currentUser);
    } else {
      return MockAuthResult.failure('Invalid email or password');
    }
  }

  /// Create account with email and password
  Future<MockAuthResult> createAccountWithEmailPassword(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    
    if (password.length < 6) {
      return MockAuthResult.failure('Password must be at least 6 characters');
    }
    
    _currentUser = MockAuthUser(
      uid: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: email.split('@')[0],
      isAnonymous: false,
      isEmailVerified: false,
      providerId: 'password',
    );
    _authStateController.add(_currentUser);
    return MockAuthResult.success(_currentUser);
  }

  /// Sign in with Google
  Future<MockAuthResult> signInWithGoogle() async {
    await Future.delayed(const Duration(seconds: 2));
    
    _currentUser = MockAuthUser(
      uid: 'google-user-123',
      email: 'user@gmail.com',
      displayName: 'Google User',
      photoURL: 'https://lh3.googleusercontent.com/a/default-user',
      isAnonymous: false,
      isEmailVerified: true,
      providerId: 'google.com',
    );
    _authStateController.add(_currentUser);
    return MockAuthResult.success(_currentUser);
  }

  /// Sign in with Apple
  Future<MockAuthResult> signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      return MockAuthResult.failure('Apple Sign In is only available on Apple platforms');
    }
    
    await Future.delayed(const Duration(seconds: 2));
    
    _currentUser = MockAuthUser(
      uid: 'apple-user-123',
      email: 'user@icloud.com',
      displayName: 'Apple User',
      isAnonymous: false,
      isEmailVerified: true,
      providerId: 'apple.com',
    );
    _authStateController.add(_currentUser);
    return MockAuthResult.success(_currentUser);
  }

  /// Sign in with Microsoft
  Future<MockAuthResult> signInWithMicrosoft() async {
    await Future.delayed(const Duration(seconds: 2));
    
    _currentUser = MockAuthUser(
      uid: 'microsoft-user-123',
      email: 'user@outlook.com',
      displayName: 'Microsoft User',
      isAnonymous: false,
      isEmailVerified: true,
      providerId: 'microsoft.com',
    );
    _authStateController.add(_currentUser);
    return MockAuthResult.success(_currentUser);
  }

  /// Sign in as anonymous guest
  Future<MockAuthResult> signInAsGuest() async {
    await Future.delayed(const Duration(seconds: 1));
    
    _currentUser = MockAuthUser(
      uid: 'guest-user-${DateTime.now().millisecondsSinceEpoch}',
      isAnonymous: true,
      isEmailVerified: false,
      providerId: 'anonymous',
    );
    _authStateController.add(_currentUser);
    return MockAuthResult.success(_currentUser);
  }

  /// Sign out current user
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _authStateController.add(null);
  }

  /// Delete current user account
  Future<MockAuthResult> deleteAccount() async {
    if (_currentUser == null) {
      return MockAuthResult.failure('No user is currently signed in');
    }
    
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = null;
    _authStateController.add(null);
    return MockAuthResult.success(null);
  }

  /// Reset password
  Future<MockAuthResult> resetPassword(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    
    if (email == 'test@example.com') {
      return MockAuthResult.success(null);
    } else {
      return MockAuthResult.failure('Email not found');
    }
  }

  /// Update user profile
  Future<MockAuthResult> updateProfile({String? displayName, String? photoURL}) async {
    if (_currentUser == null) {
      return MockAuthResult.failure('No user is currently signed in');
    }
    
    await Future.delayed(const Duration(seconds: 1));
    
    _currentUser = MockAuthUser(
      uid: _currentUser!.uid,
      email: _currentUser!.email,
      displayName: displayName ?? _currentUser!.displayName,
      photoURL: photoURL ?? _currentUser!.photoURL,
      isAnonymous: _currentUser!.isAnonymous,
      isEmailVerified: _currentUser!.isEmailVerified,
      providerId: _currentUser!.providerId,
    );
    
    _authStateController.add(_currentUser);
    return MockAuthResult.success(_currentUser);
  }

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}

/// Mock authentication user model
class MockAuthUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool isAnonymous;
  final bool isEmailVerified;
  final String? providerId;

  MockAuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    required this.isAnonymous,
    required this.isEmailVerified,
    this.providerId,
  });
}

/// Mock authentication result wrapper
class MockAuthResult {
  final bool success;
  final MockAuthUser? user;
  final String? error;

  MockAuthResult.success(this.user) : success = true, error = null;
  MockAuthResult.failure(this.error) : success = false, user = null;
}

/// Mock platform detection utilities
class MockPlatformUtils {
  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;
  static bool get isWeb => identical(0, 0.0) || Platform.isMacOS;
  static bool get isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  static bool get isMobile => Platform.isIOS || Platform.isAndroid;
  
  static List<MockAuthProvider> get supportedProviders {
    if (isIOS) {
      return [MockAuthProvider.email, MockAuthProvider.google, MockAuthProvider.apple, MockAuthProvider.anonymous];
    } else if (isAndroid) {
      return [MockAuthProvider.email, MockAuthProvider.google, MockAuthProvider.anonymous];
    } else if (isWeb) {
      return [MockAuthProvider.email, MockAuthProvider.google, MockAuthProvider.anonymous];
    } else {
      return [MockAuthProvider.email, MockAuthProvider.google, MockAuthProvider.microsoft, MockAuthProvider.anonymous];
    }
  }
}

/// Supported authentication providers
enum MockAuthProvider {
  email,
  google,
  apple,
  microsoft,
  anonymous,
}
