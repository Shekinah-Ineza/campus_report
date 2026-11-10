import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/incident.dart';
import 'status_chip.dart';

/// One report in a list: photo, title, place, time and status.
class IncidentCard extends StatelessWidget {
  const IncidentCard({super.key, required this.incident, required this.onTap});

  final Incident incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IncidentThumbnail(incident: incident, size: 64),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incident.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        incident.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 13, color: AppColors.muted),
                          const SizedBox(width: 4),
                          Text(
                            timeAgo(incident.createdAt),
                            style: const TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                          if (incident.upvotes.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            const Icon(Icons.people_outline, size: 14, color: AppColors.muted),
                            const SizedBox(width: 3),
                            Text(
                              '${incident.upvotes.length}',
                              style: const TextStyle(color: AppColors.muted, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip(status: incident.status),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The report's photo, or its category icon when there is no photo.
class IncidentThumbnail extends StatelessWidget {
  const IncidentThumbnail({super.key, required this.incident, this.size = 64});

  final Incident incident;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      color: AppColors.primarySoft,
      child: Icon(incident.category.icon, color: AppColors.primary, size: size * 0.42),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: incident.hasImage
          ? Image.network(
              incident.imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            )
          : fallback,
    );
  }
}
