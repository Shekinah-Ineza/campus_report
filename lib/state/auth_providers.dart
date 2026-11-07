import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import 'repository_providers.dart';

/// The signed-in Firebase user, or null.
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// The signed-in user's profile (with role). Rebuilds when auth changes.
final currentUserProfileProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).watchProfile(user.uid);
});

/// Convenience flag the UI uses to show or hide staff features.
/// This only hides UI; the real enforcement is in firestore.rules.
final isStaffProvider = Provider<bool>(
  (ref) => ref.watch(currentUserProfileProvider).valueOrNull?.isStaff ?? false,
);

/// Handles sign-in, registration, password reset and sign-out.
/// Its AsyncValue state drives loading spinners and error messages.
class AuthController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> signIn(String email, String password) => _run(
        () => ref.read(authRepositoryProvider).signIn(email: email, password: password),
      );

  Future<bool> register(String name, String email, String password) => _run(
        () => ref
            .read(authRepositoryProvider)
            .register(name: name, email: email, password: password),
      );

  Future<bool> sendPasswordReset(String email) =>
      _run(() => ref.read(authRepositoryProvider).sendPasswordReset(email));

  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }
}

final authControllerProvider =
    AsyncNotifierProvider.autoDispose<AuthController, void>(AuthController.new);
