import 'package:flutter/material.dart';

import '../../models/incident_enums.dart';

/// Background and text colour for each status pill.
({Color bg, Color fg}) statusColors(IncidentStatus status) => switch (status) {
      IncidentStatus.submitted => (bg: const Color(0xFFFFF4DB), fg: const Color(0xFFB7791F)),
      IncidentStatus.inReview => (bg: const Color(0xFFE3F0FF), fg: const Color(0xFF2B6CB0)),
      IncidentStatus.inProgress => (bg: const Color(0xFFEDE9FE), fg: const Color(0xFF6C4CF1)),
      IncidentStatus.resolved => (bg: const Color(0xFFE3F6EA), fg: const Color(0xFF2F855A)),
      IncidentStatus.rejected => (bg: const Color(0xFFFDE8E8), fg: const Color(0xFFC53030)),
    };

/// Kept for screens that only need the main colour of a status.
Color statusColor(IncidentStatus status, ColorScheme scheme) => statusColors(status).fg;

/// A small rounded pill showing an incident's status.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    final c = statusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        status.label,
        style: TextStyle(color: c.fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
