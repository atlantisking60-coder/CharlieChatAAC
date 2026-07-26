import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
// microsoft_identity_flutter not available - Microsoft sign-in disabled
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Authentication service supporting multiple providers across platforms
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  
  // Stream controller for authentication state
  final StreamController<AuthUser?> _authStateController = 
      StreamController<AuthUser?>.broadcast();
  
  Stream<AuthUser?> get authStateChanges => _authStateController.stream;
  
  AuthUser? get currentUser {
    final user = _auth.currentUser;
    return user != null ? AuthUser.fromFirebaseUser(user) : null;
  }

  /// Initialize the authentication service
  Future<void> initialize() async {
    // Initialize google_sign_in 7.x singleton
    await _googleSignIn.initialize();
    // Listen to Firebase auth state changes
    _auth.authStateChanges().listen((User? user) {
      _authStateController.add(user != null ? AuthUser.fromFirebaseUser(user) : null);
    });
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmailPassword(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AuthResult.success(AuthUser.fromFirebaseUser(result.user!));
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Create account with email and password
  Future<AuthResult> createAccountWithEmailPassword(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AuthResult.success(AuthUser.fromFirebaseUser(result.user!));
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      // google_sign_in 7.x: use singleton instance and authenticate()
      final googleUser = await _googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        return AuthResult.failure('Google sign in failed: no ID token');
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final result = await _auth.signInWithCredential(credential);
      return AuthResult.success(AuthUser.fromFirebaseUser(result.user!));
    } catch (e) {
      return AuthResult.failure('Google sign in failed: ${e.toString()}');
    }
  }

  /// Sign in with Apple (native on iOS/macOS, popup on web)
  Future<AuthResult> signInWithApple() async {
    try {
      if (kIsWeb) {
        // Web: use Firebase popup flow
        final provider = OAuthProvider('apple.com')
          ..addScope('email')
          ..addScope('name');
        final result = await _auth.signInWithPopup(provider);
        return AuthResult.success(AuthUser.fromFirebaseUser(result.user!));
      }

      if (!_isIOS && !_isMacOS) {
        return AuthResult.failure('Apple Sign In is only available on Apple platforms and web');
      }

      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final UserCredential result = await _auth.signInWithCredential(oauthCredential);
      return AuthResult.success(AuthUser.fromFirebaseUser(result.user!));
    } catch (e) {
      return AuthResult.failure('Apple sign in failed: ${e.toString()}');
    }
  }

  /// Sign in with Microsoft
  Future<AuthResult> signInWithMicrosoft() async {
    try {
      final result = await _microsoftSignIn();
      if (result != null) {
        return AuthResult.success(AuthUser.fromFirebaseUser(result));
      }
      return AuthResult.failure('Microsoft sign in was cancelled');
    } catch (e) {
      return AuthResult.failure('Microsoft sign in failed: ${e.toString()}');
    }
  }

  /// Sign in as anonymous guest
  Future<AuthResult> signInAsGuest() async {
    try {
      final result = await _auth.signInAnonymously();
      return AuthResult.success(AuthUser.fromFirebaseUser(result.user!));
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (e) {
      return AuthResult.failure('Guest sign in failed: ${e.toString()}');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      // Continue with sign out even if individual providers fail
      debugPrint('Error during sign out: $e');
    }
  }

  /// Delete current user account
  Future<AuthResult> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure('No user is currently signed in');
      }

      await user.delete();
      return AuthResult.success(null);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (e) {
      return AuthResult.failure('Account deletion failed: ${e.toString()}');
    }
  }

  /// Reset password
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success(null);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (e) {
      return AuthResult.failure('Password reset failed: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<AuthResult> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure('No user is currently signed in');
      }

      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      await user.reload();
      return AuthResult.success(AuthUser.fromFirebaseUser(user));
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (e) {
      return AuthResult.failure('Profile update failed: ${e.toString()}');
    }
  }

  // Private helper methods

  Future<User?> _microsoftSignIn() async {
    try {
      final provider = OAuthProvider('microsoft.com')
        ..setCustomParameters({'tenant': 'common'});
      if (kIsWeb) {
        // Web: popup flow
        final result = await _auth.signInWithPopup(provider);
        return result.user;
      } else {
        // Native (Android, iOS, Windows, macOS): redirect/provider flow
        final result = await _auth.signInWithProvider(provider);
        return result.user;
      }
    } catch (e) {
      debugPrint('Microsoft sign in error: $e');
      return null;
    }
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}

/// Authentication user model
class AuthUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool isAnonymous;
  final bool isEmailVerified;
  final String? providerId;

  AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    required this.isAnonymous,
    required this.isEmailVerified,
    this.providerId,
  });

  factory AuthUser.fromFirebaseUser(User user) {
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      isAnonymous: user.isAnonymous,
      isEmailVerified: user.emailVerified,
      providerId: user.providerData.isNotEmpty ? user.providerData.first.providerId : null,
    );
  }
}

/// Authentication result wrapper
class AuthResult {
  final bool success;
  final AuthUser? user;
  final String? error;

  AuthResult.success(this.user) : success = true, error = null;
  AuthResult.failure(this.error) : success = false, user = null;
}

/// Supported authentication providers
enum AuthProvider {
  email,
  google,
  apple,
  microsoft,
  anonymous,
}

bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
bool get _isMacOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

/// Platform detection utilities
class PlatformUtils {
  static bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isWeb => kIsWeb;
  static bool get isDesktop => !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS);
  static bool get isMobile => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
  
  static List<AuthProvider> get supportedProviders {
    if (isIOS) {
      return [AuthProvider.email, AuthProvider.google, AuthProvider.apple, AuthProvider.anonymous];
    } else if (isAndroid) {
      return [AuthProvider.email, AuthProvider.google, AuthProvider.microsoft, AuthProvider.anonymous];
    } else if (isWeb) {
      return [AuthProvider.email, AuthProvider.google, AuthProvider.apple, AuthProvider.microsoft, AuthProvider.anonymous];
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      return [AuthProvider.email, AuthProvider.google, AuthProvider.apple, AuthProvider.microsoft, AuthProvider.anonymous];
    } else {
      // Windows, Linux desktop
      return [AuthProvider.email, AuthProvider.google, AuthProvider.microsoft, AuthProvider.anonymous];
    }
  }
}
