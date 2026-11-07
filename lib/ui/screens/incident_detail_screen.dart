import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors.dart';
import '../../core/format.dart';
import '../../models/incident.dart';
import '../../state/auth_providers.dart';
import '../../state/incident_providers.dart';
import '../../state/repository_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_chip.dart';
import '../widgets/status_timeline.dart';
import 'update_status_sheet.dart';

/// Full details of one report, its history, and (for staff) status controls.
class IncidentDetailScreen extends ConsumerWidget {
  const IncidentDetailScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentAsync = ref.watch(incidentProvider(incidentId));
    final isStaff = ref.watch(isStaffProvider);
    final incident = incidentAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Report details')),
      body: incidentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'This report couldn\'t load',
          message: friendlyError(e),
        ),
        data: (incident) => incident == null
            ? const EmptyState(
                icon: Icons.search_off,
                title: 'Report not found',
                message: 'It may have been removed by staff.',
              )
            : _Details(incident: incident),
      ),
      bottomNavigationBar: isStaff && incident != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton.icon(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => UpdateStatusSheet(incident: incident),
                  ),
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Update status'),
                ),
              ),
            )
          : null,
    );
  }
}

class _Details extends ConsumerWidget {
  const _Details({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final history = ref.watch(statusHistoryProvider(incident.id));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (incident.hasImage) ...[
          GestureDetector(
            onTap: () => _showFullImage(context, incident.imageUrl!),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.network(
                  incident.imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (_, __, ___) =>
                      const Center(child: Icon(Icons.broken_image_outlined, size: 48)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(incident.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusChip(status: incident.status),
            Chip(
              avatar: Icon(incident.category.icon, size: 18),
              label: Text(incident.category.label),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _InfoRow(icon: Icons.place_outlined, text: incident.location),
        _InfoRow(icon: Icons.person_outline, text: 'Reported by ${incident.reporterName}'),
        _InfoRow(icon: Icons.schedule, text: formatDateTime(incident.createdAt)),
        const SizedBox(height: 16),
        Text(incident.description, style: theme.textTheme.bodyLarge),
        if (incident.lastNote.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.secondaryContainer,
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Latest update from staff'),
              subtitle: Text(incident.lastNote),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _MeTooButton(incident: incident),
        const SizedBox(height: 24),
        Text('Progress', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        history.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(friendlyError(e)),
          data: (changes) => StatusTimeline(changes: changes),
        ),
      ],
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(child: InteractiveViewer(child: Image.network(url))),
            SafeArea(
              child: IconButton(
                tooltip: 'Close',
                color: Colors.white,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: muted),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: muted))),
        ],
      ),
    );
  }
}

/// "Me too" lets other students confirm a problem instead of filing a
/// duplicate report, and helps staff see which issues affect the most people.
class _MeTooButton extends ConsumerWidget {
  const _MeTooButton({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    if (uid == null) return const SizedBox.shrink();

    final count = incident.upvotes.length;
    final isReporter = incident.reporterId == uid;
    final affected = incident.isUpvotedBy(uid);
    final countText = count == 1 ? '1 person affected' : '$count people affected';

    if (isReporter) {
      return Text('You reported this. $countText.',
          style: Theme.of(context).textTheme.bodyMedium);
    }

    Future<void> toggle() async {
      try {
        await ref.read(incidentRepositoryProvider).toggleUpvote(incident, uid);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(friendlyError(e))));
        }
      }
    }

    return affected
        ? FilledButton.tonalIcon(
            onPressed: toggle,
            icon: const Icon(Icons.check),
            label: Text('This affects me too ($count)'),
          )
        : OutlinedButton.icon(
            onPressed: toggle,
            icon: const Icon(Icons.people_outline),
            label: Text('This affects me too ($count)'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          );
  }
}
