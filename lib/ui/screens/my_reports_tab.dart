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

enum _Tab { all, submitted, active, resolved }

/// Profile tab: the user's details, counts and their own reports.
class MyReportsTab extends ConsumerStatefulWidget {
  const MyReportsTab({super.key});

  @override
  ConsumerState<MyReportsTab> createState() => _MyReportsTabState();
}

class _MyReportsTabState extends ConsumerState<MyReportsTab> {
  _Tab _tab = _Tab.all;

  bool _matches(Incident i) => switch (_tab) {
        _Tab.all => true,
        _Tab.submitted => i.status == IncidentStatus.submitted,
        _Tab.active =>
          i.status == IncidentStatus.inReview || i.status == IncidentStatus.inProgress,
        _Tab.resolved => i.status == IncidentStatus.resolved,
      };

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final isStaff = ref.watch(isStaffProvider);
    final incidents = ref.watch(incidentsProvider);

    return SafeArea(
      child: incidents.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(friendlyError(e))),
        data: (all) {
          final mine = all.where((i) => i.reporterId == profile?.uid).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final shown = mine.where(_matches).toList();
          final active = mine
              .where((i) =>
                  i.status == IncidentStatus.inReview || i.status == IncidentStatus.inProgress)
              .length;
          final resolved = mine.where((i) => i.status == IncidentStatus.resolved).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              Row(
                children: [
                  const Text(
                    'My Reports',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Sign out',
                    icon: const Icon(Icons.logout, color: AppColors.muted),
                    onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: cardDecoration(),
                child: Row(
                  children: [
                    Avatar(name: profile?.name ?? '', size: 56),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  profile?.name ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  isStaff ? 'Staff' : 'Student',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.mail_outline, size: 14, color: AppColors.muted),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  profile?.email ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: cardDecoration(),
                child: Row(
                  children: [
                    _Count(value: mine.length, label: 'Total Reports', color: AppColors.primary),
                    _Count(value: active, label: 'In Progress', color: const Color(0xFF2B6CB0)),
                    _Count(value: resolved, label: 'Resolved', color: const Color(0xFF2F855A)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final t in _Tab.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _TabChip(
                          label: switch (t) {
                            _Tab.all => 'All',
                            _Tab.submitted => 'Submitted',
                            _Tab.active => 'In Progress',
                            _Tab.resolved => 'Resolved',
                          },
                          selected: _tab == t,
                          onTap: () => setState(() => _tab = t),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (shown.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: cardDecoration(),
                  child: const Text(
                    'No reports here yet.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                )
              else
                for (final incident in shown)
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
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.value, required this.label, required this.color});

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
