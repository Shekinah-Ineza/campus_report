import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/incident_enums.dart';
import '../../models/incident_filter.dart';
import '../../state/incident_providers.dart';

/// Horizontal row of filter chips under the search field.
class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(incidentFilterProvider);
    final notifier = ref.read(incidentFilterProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('My reports'),
            selected: filter.mineOnly,
            onSelected: notifier.setMineOnly,
          ),
          const SizedBox(width: 8),
          _MenuChip(
            label: filter.category?.label ?? 'Category',
            selected: filter.category != null,
            onPressed: () => _showOptions<IncidentCategory>(
              context,
              title: 'Filter by category',
              options: IncidentCategory.values,
              labelOf: (c) => c.label,
              iconOf: (c) => c.icon,
              selected: filter.category,
              allowAll: true,
              onSelected: notifier.setCategory,
            ),
          ),
          const SizedBox(width: 8),
          _MenuChip(
            label: filter.status?.label ?? 'Status',
            selected: filter.status != null,
            onPressed: () => _showOptions<IncidentStatus>(
              context,
              title: 'Filter by status',
              options: IncidentStatus.values,
              labelOf: (s) => s.label,
              iconOf: (s) => s.icon,
              selected: filter.status,
              allowAll: true,
              onSelected: notifier.setStatus,
            ),
          ),
          const SizedBox(width: 8),
          _MenuChip(
            label: filter.sort.label,
            selected: false,
            icon: Icons.sort,
            onPressed: () => _showOptions<IncidentSort>(
              context,
              title: 'Sort by',
              options: IncidentSort.values,
              labelOf: (s) => s.label,
              selected: filter.sort,
              allowAll: false,
              onSelected: (s) {
                if (s != null) notifier.setSort(s);
              },
            ),
          ),
          if (filter.isActive) ...[
            const SizedBox(width: 8),
            TextButton(onPressed: notifier.reset, child: const Text('Clear filters')),
          ],
        ],
      ),
    );
  }
}

class _MenuChip extends StatelessWidget {
  const _MenuChip({
    required this.label,
    required this.selected,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: icon != null ? Icon(icon, size: 18) : null,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text(label), const Icon(Icons.arrow_drop_down, size: 18)],
      ),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onPressed(),
    );
  }
}

/// Bottom sheet listing options; "All" clears the filter.
Future<void> _showOptions<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required String Function(T) labelOf,
  IconData Function(T)? iconOf,
  required T? selected,
  required bool allowAll,
  required void Function(T?) onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      void choose(T? value) {
        Navigator.pop(sheetContext);
        onSelected(value);
      }

      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(title, style: Theme.of(context).textTheme.titleMedium),
            ),
            if (allowAll)
              ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: const Text('All'),
                trailing: selected == null ? const Icon(Icons.check) : null,
                onTap: () => choose(null),
              ),
            for (final option in options)
              ListTile(
                leading: iconOf != null ? Icon(iconOf(option)) : null,
                title: Text(labelOf(option)),
                trailing: option == selected ? const Icon(Icons.check) : null,
                onTap: () => choose(option),
              ),
          ],
        ),
      );
    },
  );
}
