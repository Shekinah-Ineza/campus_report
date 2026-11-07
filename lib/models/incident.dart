import 'package:cloud_firestore/cloud_firestore.dart';

import 'incident_enums.dart';

/// An incident report stored at incidents/{id}.
class Incident {
  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.status,
    required this.reporterId,
    required this.reporterName,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    this.lastNote = '',
    this.upvotes = const [],
  });

  final String id;
  final String title;
  final String description;
  final IncidentCategory category;
  final String location;
  final IncidentStatus status;
  final String reporterId;
  final String reporterName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageUrl;

  /// The most recent note left by staff when changing the status.
  final String lastNote;

  /// UIDs of users who pressed "Me too" (same problem affects them).
  final List<String> upvotes;

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool isUpvotedBy(String uid) => upvotes.contains(uid);

  factory Incident.fromMap(String id, Map<String, dynamic> data) => Incident(
        id: id,
        title: data['title'] as String? ?? '',
        description: data['description'] as String? ?? '',
        category: IncidentCategory.fromValue(data['category'] as String?),
        location: data['location'] as String? ?? '',
        status: IncidentStatus.fromValue(data['status'] as String?),
        reporterId: data['reporterId'] as String? ?? '',
        reporterName: data['reporterName'] as String? ?? 'Unknown',
        createdAt: _toDate(data['createdAt']),
        updatedAt: _toDate(data['updatedAt']),
        imageUrl: data['imageUrl'] as String?,
        lastNote: data['lastNote'] as String? ?? '',
        upvotes: List<String>.from(data['upvotes'] as List? ?? const []),
      );

  /// Server timestamps are null locally until the write reaches the server,
  /// so fall back to "now" for that brief moment.
  static DateTime _toDate(Object? value) =>
      value is Timestamp ? value.toDate() : DateTime.now();
}
