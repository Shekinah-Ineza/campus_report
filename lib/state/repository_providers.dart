import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/cloudinary_repository.dart';
import '../data/incident_repository.dart';

// Dependency injection: the rest of the app asks Riverpod for a repository
// instead of creating one. Tests can override these with fakes.

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(firebaseAuthProvider), ref.watch(firestoreProvider)),
);

final incidentRepositoryProvider = Provider<IncidentRepository>(
  (ref) => IncidentRepository(ref.watch(firestoreProvider)),
);

final cloudinaryRepositoryProvider = Provider<CloudinaryRepository>(
  (ref) => CloudinaryRepository(),
);
