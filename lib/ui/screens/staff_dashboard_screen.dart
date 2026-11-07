import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors.dart';
import '../../core/format.dart';
import '../../models/incident.dart';
import '../../models/incident_enums.dart';
import '../../state/incident_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/incident_card.dart';
import '../widgets/status_chip.dart';
import 'incident_detail_screen.dart';

/// Staff overview: workload by status, hotspots by category, and the
/// oldest unresolved reports that need attention.
class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key, required this.onStatusSelected});

  /// Opens the reports list filtered to the tapped status.
  final ValueChanged<IncidentStatus> onStatusSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidents = ref.watch(incidentsProvider);

    return incidents.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Dashboard couldn\'t load',
        message: friendlyError(e),
      ),
      data: (list) => _DashboardBody(incidents: list, onStatusSelected: onStatusSelected),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.incidents, required this.onStatusSelected});

  final List<Incident> incidents;
  final ValueChanged<IncidentStatus> onStatusSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final byStatus = {
      for (final s in IncidentStatus.values) s: incidents.where((i) => i.status == s).length,
    };
    final open = incidents.where((i) => i.status.isOpen).toList();
    final byCategory = {
      for (final c in IncidentCategory.values) c: open.where((i) => i.category == c).length,
    }..removeWhere((_, n) => n == 0);
    final maxCategory = byCategory.values.fold<int>(0, (a, b) => a > b ? a : b);

    final oldestOpen = [...open]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Approximation: updatedAt is the time of the last status change, which
    // for a resolved report is when it was resolved.
    final resolved = incidents.where((i) => i.status == IncidentStatus.resolved).toList();
    final avgResolution = resolved.isEmpty
        ? null
        : Duration(
            minutes: resolved
                    .map((i) => i.updatedAt.difference(i.createdAt).inMinutes)
                    .reduce((a, b) => a + b) ~/
                resolved.length,
          );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('${open.length} open of ${incidents.length} total',
            style: theme.textTheme.titleLarge),
        if (avgResolution != null)
          Text('Average time to resolve: ${formatDuration(avgResolution)}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in IncidentStatus.values)
                  SizedBox(
                    width: width,
                    child: _StatusTile(
                      status: s,
                      count: byStatus[s]!,
                      onTap: () => onStatusSelected(s),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Text('Open reports by category', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (byCategory.isEmpty)
          const Text('Nothing open right now.')
        else
          for (final entry in byCategory.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(entry.key.icon, size: 20),
                  const SizedBox(width: 8),
                  SizedBox(width: 130, child: Text(entry.key.label)),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: entry.value / maxCategory,
                        minHeight: 10,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    child: Text('${entry.value}', textAlign: TextAlign.end),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 24),
        Text('Waiting longest', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (oldestOpen.isEmpty)
          const Text('No open reports.')
        else
          for (final incident in oldestOpen.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: IncidentCard(
                incident: incident,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => IncidentDetailScreen(incidentId: incident.id),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.status, required this.count, required this.onTap});

  final IncidentStatus status;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = statusColor(status, theme.colorScheme);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(status.icon, color: color),
              const SizedBox(width: 10),
              Expanded(child: Text(status.label, style: theme.textTheme.bodyMedium)),
              Text('$count', style: theme.textTheme.titleLarge?.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
