import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mock_auth_service.dart';

/// Mock authentication state provider for development
final mockAuthServiceProvider = Provider<MockAuthService>((ref) {
  return MockAuthService();
});

/// Mock authentication state provider (Riverpod 3.x)
final mockAuthNotifierProvider = NotifierProvider<MockAuthNotifier, MockAuthState>(MockAuthNotifier.new);

/// Mock authentication state notifier
class MockAuthNotifier extends Notifier<MockAuthState> {
  @override
  MockAuthState build() {
    final authService = ref.read(mockAuthServiceProvider);
    _initialize(authService);
    return MockAuthState.initial();
  }

  Future<void> _initialize(MockAuthService authService) async {
    await authService.initialize();
    
    // Listen to auth state changes
    authService.authStateChanges.listen((user) {
      if (user != null) {
        state = MockAuthState.authenticated(user);
      } else {
        state = MockAuthState.unauthenticated();
      }
    });
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    state = const MockAuthState.loading();
    
    final authService = ref.read(mockAuthServiceProvider);
    final result = await authService.signInWithEmailPassword(email, password);
    
    if (result.success && result.user != null) {
      state = MockAuthState.authenticated(result.user!);
    } else {
      state = MockAuthState.error(result.error ?? 'Sign in failed');
    }
  }

  Future<void> createAccountWithEmailPassword(String email, String password) async {
    state = const MockAuthState.loading();
    
    final authService = ref.read(mockAuthServiceProvider);
    final result = await authService.createAccountWithEmailPassword(email, password);
    
    if (result.success && result.user != null) {
      state = MockAuthState.authenticated(result.user!);
    } else {
      state = MockAuthState.error(result.error ?? 'Account creation failed');
    }
  }

  Future<void> signInWithGoogle() async {
    state = const MockAuthState.loading();
    
    final authService = ref.read(mockAuthServiceProvider);
    final result = await authService.signInWithGoogle();
    
    if (result.success && result.user != null) {
      state = MockAuthState.authenticated(result.user!);
    } else {
      state = MockAuthState.error(result.error ?? 'Google sign in failed');
    }
  }

  Future<void> signInWithApple() async {
    state = const MockAuthState.loading();
    
    final authService = ref.read(mockAuthServiceProvider);
    final result = await authService.signInWithApple();
    
    if (result.success && result.user != null) {
      state = MockAuthState.authenticated(result.user!);
    } else {
      state = MockAuthState.error(result.error ?? 'Apple sign in failed');
    }
  }

  Future<void> signInWithMicrosoft() async {
    state = const MockAuthState.loading();
    
    final authService = ref.read(mockAuthServiceProvider);
    final result = await authService.signInWithMicrosoft();
    
    if (result.success && result.user != null) {
      state = MockAuthState.authenticated(result.user!);
    } else {
      state = MockAuthState.error(result.error ?? 'Microsoft sign in failed');
    }
  }

  Future<void> signInAsGuest() async {
    state = const MockAuthState.loading();
    
    final authService = ref.read(mockAuthServiceProvider);
    final result = await authService.signInAsGuest();
    
    if (result.success && result.user != null) {
      state = MockAuthState.authenticated(result.user!);
    } else {
      state = MockAuthState.error(result.error ?? 'Guest sign in failed');
    }
  }

  Future<void> signOut() async {
    final authService = ref.read(mockAuthServiceProvider);
    await authService.signOut();
    state = const MockAuthState.unauthenticated();
  }

  Future<void> resetPassword(String email) async {
    state = const MockAuthState.loading();
    
    final authService = ref.read(mockAuthServiceProvider);
    final result = await authService.resetPassword(email);
    
    if (result.success) {
      state = const MockAuthState.passwordResetSent();
    } else {
      state = MockAuthState.error(result.error ?? 'Password reset failed');
    }
  }

  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    final authService = ref.read(mockAuthServiceProvider);
    final result = await authService.updateProfile(
      displayName: displayName,
      photoURL: photoURL,
    );
    
    if (result.success && result.user != null) {
      state = MockAuthState.authenticated(result.user!);
    } else if (!result.success) {
      state = MockAuthState.error(result.error ?? 'Profile update failed');
    }
  }

  Future<void> deleteAccount() async {
    state = const MockAuthState.loading();
    
    final authService = ref.read(mockAuthServiceProvider);
    final result = await authService.deleteAccount();
    
    if (result.success) {
      state = const MockAuthState.unauthenticated();
    } else {
      state = MockAuthState.error(result.error ?? 'Account deletion failed');
    }
  }

  void clearError() {
    if (state.isLoading) return;
    state = state.maybeWhen(
      error: (_) => const MockAuthState.unauthenticated(),
      orElse: () => state,
    );
  }
}

/// Mock authentication state provider
final mockAuthProvider = mockAuthNotifierProvider;

/// Mock current user provider
final mockCurrentUserProvider = Provider<MockAuthUser?>((ref) {
  return ref.watch(mockAuthProvider).maybeWhen(
    authenticated: (user) => user,
    orElse: () => null,
  );
});

/// Mock authentication state
class MockAuthState {
  final bool isLoading;
  final MockAuthUser? user;
  final String? error;
  final bool isPasswordResetSent;

  const MockAuthState._({
    this.isLoading = false,
    this.user,
    this.error,
    this.isPasswordResetSent = false,
  });

  const MockAuthState.initial() : this._();
  const MockAuthState.loading() : this._(isLoading: true);
  const MockAuthState.authenticated(MockAuthUser user) : this._(user: user);
  const MockAuthState.unauthenticated() : this._();
  const MockAuthState.error(String error) : this._(error: error);
  const MockAuthState.passwordResetSent() : this._(isPasswordResetSent: true);

  bool get isAuthenticated => user != null;
  bool get isUnauthenticated => user == null && !isLoading;
  bool get hasError => error != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MockAuthState &&
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

  MockAuthState copyWith({
    bool? isLoading,
    MockAuthUser? user,
    String? error,
    bool? isPasswordResetSent,
  }) {
    return MockAuthState._(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error ?? this.error,
      isPasswordResetSent: isPasswordResetSent ?? this.isPasswordResetSent,
    );
  }

  T maybeWhen<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(MockAuthUser user)? authenticated,
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
    required T Function(MockAuthUser user) authenticated,
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
    return 'MockAuthState(isLoading: $isLoading, user: $user, error: $error, isPasswordResetSent: $isPasswordResetSent)';
  }
}

/// Mock authentication utilities
class MockAuthUtils {
  static String getDisplayName(MockAuthUser user) {
    if (user.displayName?.isNotEmpty == true) {
      return user.displayName!;
    }
    if (user.email?.isNotEmpty == true) {
      return user.email!.split('@')[0];
    }
    return 'User';
  }

  static String getInitials(MockAuthUser user) {
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

  static bool isPremiumUser(MockAuthUser user) {
    // TODO: Implement premium user logic
    return false;
  }

  static bool canAccessFeature(MockAuthUser user, String feature) {
    // TODO: Implement feature access logic
    return true;
  }
}
