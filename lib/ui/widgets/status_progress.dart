import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/incident_enums.dart';
import '../../models/status_change.dart';
import 'status_chip.dart';

/// Horizontal timeline: Submitted, In review, In progress, Resolved
/// (or Rejected), with the date each step was reached.
class StatusProgress extends StatelessWidget {
  const StatusProgress({super.key, required this.status, required this.changes});

  final IncidentStatus status;
  final List<StatusChange> changes;

  List<IncidentStatus> get _steps => status == IncidentStatus.rejected
      ? const [IncidentStatus.submitted, IncidentStatus.inReview, IncidentStatus.rejected]
      : const [
          IncidentStatus.submitted,
          IncidentStatus.inReview,
          IncidentStatus.inProgress,
          IncidentStatus.resolved,
        ];

  String? _dateFor(IncidentStatus step) {
    final matches = changes.where((c) => c.toStatus == step).toList();
    if (matches.isEmpty) return null;
    return DateFormat('d MMM, HH:mm').format(matches.last.changedAt);
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final found = steps.indexOf(status);
    final current = found < 0 ? 0 : found;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i == 0
                            ? Colors.transparent
                            : (i <= current ? AppColors.primary : AppColors.border),
                      ),
                    ),
                    _Dot(step: steps[i], reached: i <= current, isCurrent: i == current),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i == steps.length - 1
                            ? Colors.transparent
                            : (i < current ? AppColors.primary : AppColors.border),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  steps[i].label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                    color: i <= current ? statusColors(steps[i]).fg : AppColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  i <= current ? (_dateFor(steps[i]) ?? '') : '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.step, required this.reached, required this.isCurrent});

  final IncidentStatus step;
  final bool reached;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final color = reached ? statusColors(step).fg : AppColors.border;
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: reached ? color : Colors.white,
        border: Border.all(color: color, width: 2),
      ),
      child: reached
          ? Icon(isCurrent ? step.icon : Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}
