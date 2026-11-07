import 'package:intl/intl.dart';

/// "just now", "5m ago", "3h ago", "2d ago", or a date for older items.
String timeAgo(DateTime date, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('d MMM yyyy').format(date);
}

String formatDateTime(DateTime date) => DateFormat('d MMM yyyy, HH:mm').format(date);

/// e.g. "3 days 4 h", used for average resolution time.
String formatDuration(Duration d) {
  if (d.inDays >= 1) {
    final h = d.inHours % 24;
    return '${d.inDays} day${d.inDays == 1 ? '' : 's'}${h > 0 ? ' $h h' : ''}';
  }
  if (d.inHours >= 1) return '${d.inHours} h ${d.inMinutes % 60} min';
  return '${d.inMinutes} min';
}
