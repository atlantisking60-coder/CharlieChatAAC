import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// App Router Configuration
/// 
/// This file defines all routes in the application using go_router.
/// Routes are organized by feature and include error handling.
/// 
/// NOTE: This is a placeholder for the router structure.
/// The actual widget instantiation should be done in main.dart
/// where the required state (profiles, settings, etc.) is available.
/// 
/// Usage:
/// ```dart
/// // In main.dart, wrap MaterialApp with ProviderScope and use go_router
/// MaterialApp.router(
///   routerConfig: router,
/// )
/// ```
final router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  errorBuilder: (context, state) => ErrorPage(error: state.error),
  routes: [
    // Welcome Screen
    GoRoute(
      path: '/welcome',
      name: 'welcome',
      builder: (context, state) => const PlaceholderScreen(title: 'Welcome'),
    ),
    
    // Home / Main Screen
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const PlaceholderScreen(title: 'Home'),
    ),
    
    // Settings
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const PlaceholderScreen(title: 'Settings'),
    ),
    
    // Board Editor
    GoRoute(
      path: '/editor',
      name: 'editor',
      builder: (context, state) {
        final boardId = state.uri.queryParameters['boardId'];
        return PlaceholderScreen(title: 'Editor${boardId != null ? " ($boardId)" : ""}');
      },
    ),
    
    // Sync Status
    GoRoute(
      path: '/sync',
      name: 'sync',
      builder: (context, state) => const PlaceholderScreen(title: 'Sync'),
    ),
    
    // Favorites
    GoRoute(
      path: '/favorites',
      name: 'favorites',
      builder: (context, state) => const PlaceholderScreen(title: 'Favorites'),
    ),
    
    // Board Detail (for sub-boards)
    GoRoute(
      path: '/board/:id',
      name: 'board',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return PlaceholderScreen(title: 'Board: $id');
      },
    ),
  ],
);

/// Placeholder screen for router structure
/// Replace with actual widgets in main.dart
class PlaceholderScreen extends StatelessWidget {
  final String title;
  
  const PlaceholderScreen({required this.title, super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '$title - Route configured',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Widget integration to be done in main.dart'),
          ],
        ),
      ),
    );
  }
}

/// Error Page for routing errors
class ErrorPage extends StatelessWidget {
  final Object? error;
  
  const ErrorPage({this.error, super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'An error occurred',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            if (error != null)
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigation Extensions
/// 
/// Helper methods for common navigation patterns
extension NavigationExtensions on BuildContext {
  void goToHome() => go('/');
  void goToSettings() => go('/settings');
  void goToEditor({String? boardId}) {
    if (boardId != null) {
      go('/editor?boardId=$boardId');
    } else {
      go('/editor');
    }
  }
  void goToSync() => go('/sync');
  void goToFavorites() => go('/favorites');
  void goToBoard(String id) => go('/board/$id');
  void goToWelcome() => go('/welcome');
}
