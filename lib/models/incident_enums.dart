import 'package:flutter/material.dart';

/// Incident categories. `value` is what is stored in Firestore and must
/// match the list in firestore.rules.
enum IncidentCategory {
  facilities('facilities', 'Broken facilities', Icons.build_outlined),
  water('water', 'Water shortage', Icons.water_drop_outlined),
  electricity('electricity', 'Electricity outage', Icons.bolt_outlined),
  furniture('furniture', 'Damaged furniture', Icons.chair_outlined),
  sanitation('sanitation', 'Sanitation', Icons.cleaning_services_outlined),
  safety('safety', 'Safety concern', Icons.health_and_safety_outlined),
  other('other', 'Other', Icons.more_horiz);

  const IncidentCategory(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;

  static IncidentCategory fromValue(String? value) =>
      values.firstWhere((c) => c.value == value, orElse: () => other);
}

/// The life cycle of a report: submitted → in review → in progress →
/// resolved (or rejected, e.g. for duplicates).
enum IncidentStatus {
  submitted('submitted', 'Submitted', Icons.outbox_outlined),
  inReview('in_review', 'In review', Icons.visibility_outlined),
  inProgress('in_progress', 'In progress', Icons.construction_outlined),
  resolved('resolved', 'Resolved', Icons.check_circle_outline),
  rejected('rejected', 'Rejected', Icons.block_outlined);

  const IncidentStatus(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;

  bool get isOpen => this != resolved && this != rejected;

  static IncidentStatus fromValue(String? value) =>
      values.firstWhere((s) => s.value == value, orElse: () => submitted);
}
