import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../models/status_change.dart';
import 'status_chip.dart';

/// Vertical timeline of every status change on a report.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.changes});

  final List<StatusChange> changes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (changes.isEmpty) {
      return Text('No history yet.', style: theme.textTheme.bodyMedium);
    }
    return Column(
      children: [
        for (var i = 0; i < changes.length; i++)
          _TimelineEntry(change: changes[i], isLast: i == changes.length - 1),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.change, required this.isLast});

  final StatusChange change;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = statusColor(change.toStatus, theme.colorScheme);
    final muted = theme.colorScheme.onSurfaceVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: theme.colorScheme.outlineVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(change.toStatus.label,
                      style: theme.textTheme.titleSmall?.copyWith(color: color)),
                  const SizedBox(height: 2),
                  Text(
                    '${change.changedByName}, ${formatDateTime(change.changedAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                  if (change.note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(change.note, style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
