import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// Authentication state provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Authentication state provider (Riverpod 3.x)
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Authentication state notifier
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final authService = ref.read(authServiceProvider);
    _initialize(authService);
    return AuthState.initial();
  }

  Future<void> _initialize(AuthService authService) async {
    await authService.initialize();
    
    // Listen to auth state changes
    authService.authStateChanges.listen((user) {
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.unauthenticated();
      }
    });
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    state = const AuthState.loading();
    
    final authService = ref.read(authServiceProvider);
    final result = await authService.signInWithEmailPassword(email, password);
    
    if (result.success && result.user != null) {
      state = AuthState.authenticated(result.user!);
    } else {
      state = AuthState.error(result.error ?? 'Sign in failed');
    }
  }

  Future<void> createAccountWithEmailPassword(String email, String password) async {
    state = const AuthState.loading();
    
    final authService = ref.read(authServiceProvider);
    final result = await authService.createAccountWithEmailPassword(email, password);
    
    if (result.success && result.user != null) {
      state = AuthState.authenticated(result.user!);
    } else {
      state = AuthState.error(result.error ?? 'Account creation failed');
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AuthState.loading();
    
    final authService = ref.read(authServiceProvider);
    final result = await authService.signInWithGoogle();
    
    if (result.success && result.user != null) {
      state = AuthState.authenticated(result.user!);
    } else {
      state = AuthState.error(result.error ?? 'Google sign in failed');
    }
  }

  Future<void> signInWithApple() async {
    state = const AuthState.loading();
    
    final authService = ref.read(authServiceProvider);
    final result = await authService.signInWithApple();
    
    if (result.success && result.user != null) {
      state = AuthState.authenticated(result.user!);
    } else {
      state = AuthState.error(result.error ?? 'Apple sign in failed');
    }
  }

  Future<void> signInWithMicrosoft() async {
    state = const AuthState.loading();
    
    final authService = ref.read(authServiceProvider);
    final result = await authService.signInWithMicrosoft();
    
    if (result.success && result.user != null) {
      state = AuthState.authenticated(result.user!);
    } else {
      state = AuthState.error(result.error ?? 'Microsoft sign in failed');
    }
  }

  Future<void> signInAsGuest() async {
    state = const AuthState.loading();
    
    final authService = ref.read(authServiceProvider);
    final result = await authService.signInAsGuest();
    
    if (result.success && result.user != null) {
      state = AuthState.authenticated(result.user!);
    } else {
      state = AuthState.error(result.error ?? 'Guest sign in failed');
    }
  }

  Future<void> signOut() async {
    final authService = ref.read(authServiceProvider);
    await authService.signOut();
    state = const AuthState.unauthenticated();
  }

  Future<void> resetPassword(String email) async {
    state = const AuthState.loading();
    
    final authService = ref.read(authServiceProvider);
    final result = await authService.resetPassword(email);
    
    if (result.success) {
      state = const AuthState.passwordResetSent();
    } else {
      state = AuthState.error(result.error ?? 'Password reset failed');
    }
  }

  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    final authService = ref.read(authServiceProvider);
    final result = await authService.updateProfile(
      displayName: displayName,
      photoURL: photoURL,
    );
    
    if (result.success && result.user != null) {
      state = AuthState.authenticated(result.user!);
    } else if (!result.success) {
      state = AuthState.error(result.error ?? 'Profile update failed');
    }
  }

  Future<void> deleteAccount() async {
    state = const AuthState.loading();
    
    final authService = ref.read(authServiceProvider);
    final result = await authService.deleteAccount();
    
    if (result.success) {
      state = const AuthState.unauthenticated();
    } else {
      state = AuthState.error(result.error ?? 'Account deletion failed');
    }
  }

  void clearError() {
    if (state.isLoading) return;
    state = state.maybeWhen(
      error: (_) => const AuthState.unauthenticated(),
      orElse: () => state,
    );
  }
}

/// Authentication state provider
final authProvider = authNotifierProvider;

/// Current user provider
final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authProvider).maybeWhen(
    authenticated: (user) => user,
    orElse: () => null,
  );
});

/// Authentication state
class AuthState {
  final bool isLoading;
  final AuthUser? user;
  final String? error;
  final bool isPasswordResetSent;

  const AuthState._({
    this.isLoading = false,
    this.user,
    this.error,
    this.isPasswordResetSent = false,
  });

  const AuthState.initial() : this._();
  const AuthState.loading() : this._(isLoading: true);
  const AuthState.authenticated(AuthUser user) : this._(user: user);
  const AuthState.unauthenticated() : this._();
  const AuthState.error(String error) : this._(error: error);
  const AuthState.passwordResetSent() : this._(isPasswordResetSent: true);

  bool get isAuthenticated => user != null;
  bool get isUnauthenticated => user == null && !isLoading;
  bool get hasError => error != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.isLoading == isLoading &&
        other.user == user &&
        other.error == error &&
        other.isPasswordResetSent == isPasswordResetSent;
  }

  @override
  int get hashCode {
    return isLoading.hashCode ^
        user.hashCode ^
        error.hashCode ^
        isPasswordResetSent.hashCode;
  }

  AuthState copyWith({
    bool? isLoading,
    AuthUser? user,
    String? error,
    bool? isPasswordResetSent,
  }) {
    return AuthState._(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error ?? this.error,
      isPasswordResetSent: isPasswordResetSent ?? this.isPasswordResetSent,
    );
  }

  T maybeWhen<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(AuthUser user)? authenticated,
    T Function()? unauthenticated,
    T Function(String error)? error,
    T Function()? passwordResetSent,
    required T Function() orElse,
  }) {
    if (isPasswordResetSent && passwordResetSent != null) {
      return passwordResetSent();
    }
    if (isLoading && loading != null) {
      return loading();
    }
    if (user != null && authenticated != null) {
      return authenticated(user!);
    }
    if (user == null && !isLoading && !isPasswordResetSent && unauthenticated != null) {
      return unauthenticated();
    }
    if (this.error != null && error != null) {
      return error(this.error!);
    }
    if (user == null && !isLoading && !isPasswordResetSent && initial != null) {
      return initial();
    }
    return orElse();
  }

  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(AuthUser user) authenticated,
    required T Function() unauthenticated,
    required T Function(String error) error,
    required T Function() passwordResetSent,
  }) {
    if (isPasswordResetSent) return passwordResetSent();
    if (isLoading) return loading();
    if (user != null) return authenticated(user!);
    if (this.error != null) return error(this.error!);
    if (user == null && !isLoading && !isPasswordResetSent) return unauthenticated();
    return initial();
  }

  @override
  String toString() {
    return 'AuthState(isLoading: $isLoading, user: $user, error: $error, isPasswordResetSent: $isPasswordResetSent)';
  }
}

/// Authentication utilities
class AuthUtils {
  static String getDisplayName(AuthUser user) {
    if (user.displayName?.isNotEmpty == true) {
      return user.displayName!;
    }
    if (user.email?.isNotEmpty == true) {
      return user.email!.split('@')[0];
    }
    return 'User';
  }

  static String getInitials(AuthUser user) {
    final name = getDisplayName(user);
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  static String getProviderDisplayName(String? providerId) {
    switch (providerId) {
      case 'google.com':
        return 'Google';
      case 'apple.com':
        return 'Apple';
      case 'microsoft.com':
        return 'Microsoft';
      case 'password':
        return 'Email';
      default:
        return 'Unknown';
    }
  }

  static bool isPremiumUser(AuthUser user) {
    // TODO: Implement premium user logic
    // This could check for subscription status, user roles, etc.
    return false;
  }

  static bool canAccessFeature(AuthUser user, String feature) {
    // TODO: Implement feature access logic
    // This could check for user permissions, subscription tiers, etc.
    return true;
  }
}
