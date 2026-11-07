import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../models/incident.dart';
import 'status_chip.dart';

/// One row in the reports list. Reused by the feed and the staff dashboard.
class IncidentCard extends StatelessWidget {
  const IncidentCard({super.key, required this.incident, required this.onTap});

  final Incident incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(incident: incident),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.place_outlined, size: 14, color: muted),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            incident.location,
                            style: theme.textTheme.bodySmall?.copyWith(color: muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatusChip(status: incident.status),
                        const Spacer(),
                        if (incident.upvotes.isNotEmpty) ...[
                          Icon(Icons.people_outline, size: 16, color: muted),
                          const SizedBox(width: 2),
                          Text('${incident.upvotes.length}',
                              style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                          const SizedBox(width: 10),
                        ],
                        Text(timeAgo(incident.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = Container(
      width: 64,
      height: 64,
      color: scheme.secondaryContainer,
      child: Icon(incident.category.icon, color: scheme.onSecondaryContainer),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: incident.hasImage
          ? Image.network(
              incident.imageUrl!,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            )
          : fallback,
    );
  }
}
