import 'package:flutter/material.dart';

import '../../models/incident_enums.dart';

Color statusColor(IncidentStatus status, ColorScheme scheme) => switch (status) {
      IncidentStatus.submitted => const Color(0xFF64748B),
      IncidentStatus.inReview => const Color(0xFFB7791F),
      IncidentStatus.inProgress => const Color(0xFF2563EB),
      IncidentStatus.resolved => const Color(0xFF15803D),
      IncidentStatus.rejected => scheme.error,
    };

/// A small coloured pill showing an incident's status.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status, Theme.of(context).colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
