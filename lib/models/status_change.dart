import 'package:cloud_firestore/cloud_firestore.dart';

import 'incident_enums.dart';

/// One entry in incidents/{id}/statusHistory — an audit trail of who
/// changed the status, when, and why.
class StatusChange {
  const StatusChange({
    required this.id,
    required this.toStatus,
    required this.changedBy,
    required this.changedByName,
    required this.changedAt,
    this.fromStatus,
    this.note = '',
  });

  final String id;
  final IncidentStatus? fromStatus;
  final IncidentStatus toStatus;
  final String changedBy;
  final String changedByName;
  final DateTime changedAt;
  final String note;

  factory StatusChange.fromMap(String id, Map<String, dynamic> data) {
    final from = data['fromStatus'] as String?;
    final at = data['changedAt'];
    return StatusChange(
      id: id,
      fromStatus: from == null ? null : IncidentStatus.fromValue(from),
      toStatus: IncidentStatus.fromValue(data['toStatus'] as String?),
      changedBy: data['changedBy'] as String? ?? '',
      changedByName: data['changedByName'] as String? ?? '',
      changedAt: at is Timestamp ? at.toDate() : DateTime.now(),
      note: data['note'] as String? ?? '',
    );
  }
}
