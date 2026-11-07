import 'incident.dart';
import 'incident_enums.dart';

enum IncidentSort {
  newest('Newest first'),
  oldest('Oldest first'),
  mostAffected('Most affected');

  const IncidentSort(this.label);
  final String label;
}

/// Search and filter settings for the reports list. Immutable: every change
/// creates a new object, which is what lets Riverpod detect updates.
///
/// Filtering runs on the client because Firestore has no full-text search
/// and combining several optional filters would need many composite indexes.
class IncidentFilter {
  const IncidentFilter({
    this.query = '',
    this.category,
    this.status,
    this.mineOnly = false,
    this.sort = IncidentSort.newest,
  });

  final String query;
  final IncidentCategory? category;
  final IncidentStatus? status;
  final bool mineOnly;
  final IncidentSort sort;

  bool get isActive =>
      query.trim().isNotEmpty || category != null || status != null || mineOnly;

  List<Incident> apply(List<Incident> incidents, {String? currentUid}) {
    final q = query.trim().toLowerCase();

    final result = incidents.where((i) {
      if (category != null && i.category != category) return false;
      if (status != null && i.status != status) return false;
      if (mineOnly && i.reporterId != currentUid) return false;
      if (q.isNotEmpty) {
        final text = '${i.title} ${i.description} ${i.location}'.toLowerCase();
        if (!text.contains(q)) return false;
      }
      return true;
    }).toList();

    switch (sort) {
      case IncidentSort.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case IncidentSort.oldest:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case IncidentSort.mostAffected:
        result.sort((a, b) {
          final byVotes = b.upvotes.length.compareTo(a.upvotes.length);
          return byVotes != 0 ? byVotes : b.createdAt.compareTo(a.createdAt);
        });
    }
    return result;
  }
}
