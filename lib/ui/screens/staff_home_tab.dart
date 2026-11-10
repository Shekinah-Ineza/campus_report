import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/incident.dart';
import '../../models/incident_enums.dart';
import '../../state/auth_providers.dart';
import '../../state/incident_providers.dart';
import '../widgets/avatar.dart';
import '../widgets/incident_card.dart';
import 'incident_detail_screen.dart';

/// Staff portal home: an overview of ALL reports on campus, what needs
/// attention first, and quick links to filtered lists.
class StaffHomeTab extends ConsumerWidget {
  const StaffHomeTab({
    super.key,
    required this.onOpenStatus,
    required this.onOpenAll,
    required this.onOpenProfile,
  });

  /// Opens the Reports tab filtered to one status.
  final ValueChanged<IncidentStatus> onOpenStatus;
  final VoidCallback onOpenAll;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final name = profile?.name ?? '';
    final firstName = name.trim().isEmpty ? 'there' : name.trim().split(' ').first;
    final incidents = ref.watch(incidentsProvider);

    return SafeArea(
      child: incidents.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(friendlyError(e))),
        data: (all) {
          int count(IncidentStatus s) => all.where((i) => i.status == s).length;
          final newReports = count(IncidentStatus.submitted);
          final inReview = count(IncidentStatus.inReview);
          final inProgress = count(IncidentStatus.inProgress);
          final resolved = count(IncidentStatus.resolved);

          // Oldest open reports first, so nothing waits too long.
          final needsAttention = all.where((i) => i.status.isOpen).toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          // Most "This affects me too" first.
          final mostAffected = all.where((i) => i.status.isOpen && i.upvotes.isNotEmpty).toList()
            ..sort((a, b) => b.upvotes.length.compareTo(a.upvotes.length));

          final resolvedList = all.where((i) => i.status == IncidentStatus.resolved).toList();
          final avgResolve = resolvedList.isEmpty
              ? null
              : Duration(
                  minutes: resolvedList
                          .map((i) => i.updatedAt.difference(i.createdAt).inMinutes)
                          .reduce((a, b) => a + b) ~/
                      resolvedList.length,
                );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Staff portal',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hello, $firstName 👋',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Here is everything happening on campus.',
                          style: TextStyle(fontSize: 13, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(onTap: onOpenProfile, child: Avatar(name: name, size: 46)),
                ],
              ),
              const SizedBox(height: 20),
              _AttentionBanner(
                newReports: newReports,
                onReview: () => onOpenStatus(IncidentStatus.submitted),
              ),
              const SizedBox(height: 24),
              _Header(title: 'Campus overview', action: 'See all', onAction: onOpenAll),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Tile(
                    icon: Icons.description_outlined,
                    color: AppColors.primary,
                    value: all.length,
                    label: 'Total',
                    onTap: onOpenAll,
                  ),
                  const SizedBox(width: 8),
                  _Tile(
                    icon: Icons.error_outline,
                    color: const Color(0xFFB7791F),
                    value: newReports,
                    label: 'New',
                    onTap: () => onOpenStatus(IncidentStatus.submitted),
                  ),
                  const SizedBox(width: 8),
                  _Tile(
                    icon: Icons.schedule,
                    color: const Color(0xFF2B6CB0),
                    value: inReview + inProgress,
                    label: 'In Progress',
                    onTap: () => onOpenStatus(IncidentStatus.inProgress),
                  ),
                  const SizedBox(width: 8),
                  _Tile(
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF2F855A),
                    value: resolved,
                    label: 'Resolved',
                    onTap: () => onOpenStatus(IncidentStatus.resolved),
                  ),
                ],
              ),
              if (avgResolve != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: cardDecoration(radius: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: AppColors.primary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Average time to resolve',
                          style: TextStyle(color: AppColors.ink),
                        ),
                      ),
                      Text(
                        formatDuration(avgResolve),
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _Header(title: 'Needs attention', action: 'See all', onAction: onOpenAll),
              const SizedBox(height: 4),
              const Text(
                'Open reports, oldest first',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              _ReportList(incidents: needsAttention.take(5).toList(), empty: 'No open reports. Great job!'),
              if (mostAffected.isNotEmpty) ...[
                const SizedBox(height: 24),
                const _Header(title: 'Affecting the most people'),
                const SizedBox(height: 12),
                _ReportList(incidents: mostAffected.take(3).toList(), empty: ''),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AttentionBanner extends StatelessWidget {
  const _AttentionBanner({required this.newReports, required this.onReview});

  final int newReports;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final title = newReports == 0
        ? 'All caught up'
        : '$newReports new report${newReports == 1 ? '' : 's'}\nwaiting for review';
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF7C5CFF), AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -6,
            bottom: 34,
            child: Icon(
              Icons.fact_check_outlined,
              size: 104,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Review new reports and keep students\nupdated on progress.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                ),
                const SizedBox(height: 16),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onReview,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.inbox_outlined, color: AppColors.primary),
                          SizedBox(width: 10),
                          Text(
                            'Review new reports',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Spacer(),
                          Icon(Icons.chevron_right, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        const Spacer(),
        if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final int value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: cardDecoration(radius: 14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportList extends StatelessWidget {
  const _ReportList({required this.incidents, required this.empty});

  final List<Incident> incidents;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (incidents.isEmpty) {
      if (empty.isEmpty) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: cardDecoration(),
        child: Text(empty, style: const TextStyle(color: AppColors.muted)),
      );
    }
    return Column(
      children: [
        for (final incident in incidents)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
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
