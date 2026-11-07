import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/errors.dart';
import '../models/app_user.dart';

/// The only class that talks to Firebase Authentication.
class AuthRepository {
  AuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Live profile, including the role. Updates instantly if an admin
  /// promotes the account to staff.
  Stream<AppUser?> watchProfile(String uid) => _userDoc(uid).snapshots().map(
        (snap) => snap.exists ? AppUser.fromMap(snap.id, snap.data()!) : null,
      );

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code));
    }
  }

  /// Creates the account and its profile. Every new account is a student;
  /// staff are promoted by an administrator (see README), and
  /// firestore.rules blocks users from giving themselves the staff role.
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;
      await user.updateDisplayName(name.trim());
      await _userDoc(user.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code));
    }
  }

  Future<void> signOut() => _auth.signOut();

  static String _messageFor(String code) => switch (code) {
        'invalid-email' => 'That email address isn\'t valid.',
        'user-disabled' => 'This account has been disabled.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'Incorrect email or password.',
        'email-already-in-use' => 'An account with this email already exists.',
        'weak-password' => 'Choose a stronger password (at least 6 characters).',
        'too-many-requests' => 'Too many attempts. Wait a moment and try again.',
        'network-request-failed' => 'No connection. Check your internet and try again.',
        _ => 'Sign-in failed. Try again.',
      };
}
