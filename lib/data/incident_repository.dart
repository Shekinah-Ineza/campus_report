import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/incident.dart';
import '../models/incident_enums.dart';
import '../models/status_change.dart';

/// The only class that reads and writes incidents in Cloud Firestore.
class IncidentRepository {
  IncidentRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _db.collection('incidents');

  /// Reserves a document ID so the photo can be uploaded under that ID
  /// before the report itself is written.
  String newIncidentId() => _incidents.doc().id;

  Stream<List<Incident>> watchIncidents({int limit = 500}) => _incidents
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => Incident.fromMap(d.id, d.data())).toList());

  Stream<Incident?> watchIncident(String id) => _incidents.doc(id).snapshots().map(
        (snap) => snap.exists ? Incident.fromMap(snap.id, snap.data()!) : null,
      );

  Stream<List<StatusChange>> watchHistory(String incidentId) => _incidents
      .doc(incidentId)
      .collection('statusHistory')
      .orderBy('changedAt')
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => StatusChange.fromMap(d.id, d.data())).toList());

  /// Writes the report and its first history entry in one atomic batch.
  Future<void> createIncident({
    required String id,
    required AppUser reporter,
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
    String? imageUrl,
  }) async {
    final ref = _incidents.doc(id);
    final batch = _db.batch();
    batch.set(ref, {
      'title': title.trim(),
      'description': description.trim(),
      'category': category.value,
      'location': location.trim(),
      'imageUrl': imageUrl,
      'status': IncidentStatus.submitted.value,
      'reporterId': reporter.uid,
      'reporterName': reporter.name,
      'upvotes': <String>[],
      'lastNote': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(ref.collection('statusHistory').doc(), {
      'fromStatus': null,
      'toStatus': IncidentStatus.submitted.value,
      'note': '',
      'changedBy': reporter.uid,
      'changedByName': reporter.name,
      'changedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Staff only (enforced by firestore.rules). Updates the status and
  /// records the change in the history, atomically.
  Future<void> updateStatus({
    required Incident incident,
    required IncidentStatus newStatus,
    required AppUser staff,
    String note = '',
  }) async {
    final ref = _incidents.doc(incident.id);
    final batch = _db.batch();
    batch.update(ref, {
      'status': newStatus.value,
      'lastNote': note.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(ref.collection('statusHistory').doc(), {
      'fromStatus': incident.status.value,
      'toStatus': newStatus.value,
      'note': note.trim(),
      'changedBy': staff.uid,
      'changedByName': staff.name,
      'changedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Adds or removes the user's "Me too". arrayUnion/arrayRemove avoid
  /// lost updates when several people press it at the same time.
  Future<void> toggleUpvote(Incident incident, String uid) {
    return _incidents.doc(incident.id).update({
      'upvotes': incident.isUpvotedBy(uid)
          ? FieldValue.arrayRemove([uid])
          : FieldValue.arrayUnion([uid]),
    });
  }
}
