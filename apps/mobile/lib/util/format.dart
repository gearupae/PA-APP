import 'package:intl/intl.dart';

final _money = NumberFormat('#,##0', 'en');

/// Compact, currency-symbol-free money formatting (works across INR/AED/etc).
String money(double v) => _money.format(v.round());

String dayMonth(DateTime d) => DateFormat('d MMM').format(d);
String dayMonthTime(DateTime d) => DateFormat('d MMM, h:mm a').format(d);
String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('d MMM').format(d);
}
