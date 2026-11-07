import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors.dart';
import '../../state/incident_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_bar.dart';
import '../widgets/incident_card.dart';
import 'incident_detail_screen.dart';

/// Browse, search and filter all reports.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep the search box in sync when filters are cleared elsewhere.
    ref.listen(incidentFilterProvider, (_, next) {
      if (next.query.isEmpty && _search.text.isNotEmpty) _search.clear();
    });

    final incidents = ref.watch(filteredIncidentsProvider);
    final filter = ref.watch(incidentFilterProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: 'Search title, description or place',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: filter.query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        ref.read(incidentFilterProvider.notifier).setQuery('');
                      },
                    ),
            ),
            textInputAction: TextInputAction.search,
            onChanged: ref.read(incidentFilterProvider.notifier).setQuery,
          ),
        ),
        const FilterBar(),
        const SizedBox(height: 8),
        Expanded(
          child: incidents.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Reports couldn\'t load',
              message: friendlyError(e),
            ),
            data: (list) {
              if (list.isEmpty) {
                return filter.isActive
                    ? EmptyState(
                        icon: Icons.filter_alt_off_outlined,
                        title: 'No reports match',
                        message: 'Try a different search or clear the filters.',
                        action: OutlinedButton(
                          onPressed: ref.read(incidentFilterProvider.notifier).reset,
                          child: const Text('Clear filters'),
                        ),
                      )
                    : const EmptyState(
                        icon: Icons.task_alt,
                        title: 'No reports yet',
                        message: 'Spotted a problem on campus? Tap "Report a problem" to tell staff.',
                      );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => IncidentCard(
                  incident: list[i],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => IncidentDetailScreen(incidentId: list[i].id),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
