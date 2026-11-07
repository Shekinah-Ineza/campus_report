import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors.dart';
import '../../state/auth_providers.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Decides what to show based on auth state: login, a loading screen while
/// the profile loads, or the home screen.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return auth.when(
      loading: () => const _LoadingScreen(),
      error: (e, _) => _ErrorScreen(message: friendlyError(e)),
      data: (user) {
        if (user == null) return const LoginScreen();
        final profile = ref.watch(currentUserProfileProvider);
        return profile.when(
          loading: () => const _LoadingScreen(),
          error: (e, _) => _ErrorScreen(message: friendlyError(e)),
          // A missing profile can briefly happen right after registering.
          data: (p) => p == null ? const _LoadingScreen(showSignOut: true) : const HomeScreen(),
        );
      },
    );
  }
}

class _LoadingScreen extends ConsumerWidget {
  const _LoadingScreen({this.showSignOut = false});

  final bool showSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (showSignOut) ...[
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                child: const Text('Sign out'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends ConsumerWidget {
  const _ErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
