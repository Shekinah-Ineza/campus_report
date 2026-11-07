import 'package:firebase_core/firebase_core.dart';

/// A readable error thrown by the auth repository.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Turns any error into a message that is safe to show in a SnackBar.
String friendlyError(Object? error) {
  if (error is AuthFailure) return error.message;
  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return 'You don\'t have permission to do that.';
    }
    if (error.code == 'unavailable') {
      return 'No connection. Check your internet and try again.';
    }
    return error.message ?? 'Something went wrong. Try again.';
  }
  if (error is String) return error;
  return 'Something went wrong. Try again.';
}
