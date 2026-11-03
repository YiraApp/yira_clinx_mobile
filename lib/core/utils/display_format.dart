import 'package:intl/intl.dart';

/// "16:00:34", "16:00", "4:00 PM" or an ISO date-time -> "4:00 PM".
/// Anything it cannot read is returned unchanged.
String formatClockTime(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return s;
  final hms = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2}(?:\.\d+)?)?$').firstMatch(s);
  if (hms != null) {
    final h = int.parse(hms.group(1)!), m = int.parse(hms.group(2)!);
    if (h < 24 && m < 60) return DateFormat('h:mm a').format(DateTime(2000, 1, 1, h, m));
  }
  if (s.contains('T')) {
    final dt = DateTime.tryParse(s);
    if (dt != null) return DateFormat('h:mm a').format(dt.toLocal());
  }
  return s;
}

/// "PaymentPending", "PAYMENT_PENDING" or "payment pending" -> "Payment pending".
String humanizeStatus(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return s;
  final spaced = s
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll(RegExp(r'\s+'), ' ')
      .toLowerCase();
  return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}

/// Groups statuses that differ only in case, spacing or underscores.
String statusKey(String raw) => raw.replaceAll(RegExp(r'[\s_\-]'), '').toUpperCase();
