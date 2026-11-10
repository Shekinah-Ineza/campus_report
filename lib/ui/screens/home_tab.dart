import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../models/incident.dart';
import '../../models/incident_enums.dart';
import '../../state/auth_providers.dart';
import '../../state/incident_providers.dart';
import '../widgets/avatar.dart';
import '../widgets/incident_card.dart';
import 'incident_detail_screen.dart';

/// Home: greeting, "Report an Issue" banner, a summary of the user's own
/// reports and their most recent ones.
class HomeTab extends ConsumerWidget {
  const HomeTab({
    super.key,
    required this.onReport,
    required this.onSeeAll,
    required this.onOpenProfile,
  });

  final VoidCallback onReport;
  final VoidCallback onSeeAll;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final name = profile?.name ?? '';
    final firstName = name.trim().isEmpty ? 'there' : name.trim().split(' ').first;
    final incidents = ref.watch(incidentsProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $firstName 👋',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Help make our campus safer.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Report issues and track their resolution.',
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              GestureDetector(onTap: onOpenProfile, child: Avatar(name: name, size: 46)),
            ],
          ),
          const SizedBox(height: 20),
          _ReportBanner(onTap: onReport),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Report Summary', onSeeAll: onSeeAll),
          const SizedBox(height: 12),
          incidents.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(friendlyError(e)),
            data: (list) => _Summary(mine: _mine(list, profile?.uid)),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Recent Reports', onSeeAll: onSeeAll),
          const SizedBox(height: 12),
          incidents.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (list) {
              final recent = _mine(list, profile?.uid).take(3).toList();
              if (recent.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: cardDecoration(),
                  child: const Text(
                    'You haven\'t reported anything yet. Tap the + button to report your first issue.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                );
              }
              return Column(
                children: [
                  for (final incident in recent)
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
            },
          ),
        ],
      ),
    );
  }

  /// The signed-in user's reports, newest first.
  static List<Incident> _mine(List<Incident> all, String? uid) {
    final mine = all.where((i) => i.reporterId == uid).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine;
  }
}

class _ReportBanner extends StatelessWidget {
  const _ReportBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              Icons.apartment_rounded,
              size: 110,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'See an issue\non campus?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Report it and help improve\nour learning environment.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                ),
                const SizedBox(height: 16),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onTap,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.add, size: 16, color: Colors.white),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Report an Issue',
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        const Spacer(),
        TextButton(onPressed: onSeeAll, child: const Text('See all')),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.mine});

  final List<Incident> mine;

  int _count(bool Function(Incident) test) => mine.where(test).length;

  @override
  Widget build(BuildContext context) {
    final inProgress = _count((i) =>
        i.status == IncidentStatus.inReview || i.status == IncidentStatus.inProgress);
    final resolved = _count((i) => i.status == IncidentStatus.resolved);
    final submitted = _count((i) => i.status == IncidentStatus.submitted);

    return Row(
      children: [
        _StatTile(
          icon: Icons.description_outlined,
          color: AppColors.primary,
          value: mine.length,
          label: 'My Reports',
        ),
        const SizedBox(width: 8),
        _StatTile(
          icon: Icons.schedule,
          color: const Color(0xFF2B6CB0),
          value: inProgress,
          label: 'In Progress',
        ),
        const SizedBox(width: 8),
        _StatTile(
          icon: Icons.check_circle_outline,
          color: const Color(0xFF2F855A),
          value: resolved,
          label: 'Resolved',
        ),
        const SizedBox(width: 8),
        _StatTile(
          icon: Icons.error_outline,
          color: const Color(0xFFC53030),
          value: submitted,
          label: 'Submitted',
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: cardDecoration(radius: 14),
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
    );
  }
}
