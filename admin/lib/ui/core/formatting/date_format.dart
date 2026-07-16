const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _fullMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// e.g. "Sat, Jul 18" — same dependency-free approach as app/'s equivalent, kept as a
/// separate copy rather than a shared package (see CLAUDE.md: admin/ doesn't share code
/// with app/ yet, a deliberate MVP choice, not an oversight).
String formatShortDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${_weekdays[local.weekday - 1]}, ${_months[local.month - 1]} ${local.day}';
}

/// e.g. "125.00" from 12500 minor units — always 2 decimals, matching how DKK/øre display.
String formatPriceMinor(int minor) => (minor / 100).toStringAsFixed(2);

/// e.g. "09:30" (24h) — same dependency-free approach as formatShortDate.
String formatTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

/// e.g. "July 15" (same year as now) or "December 27, 2025" — same as app/'s Bubbles date separator.
String formatChatDateSeparator(DateTime dateTime) {
  final local = dateTime.toLocal();
  final now = DateTime.now();
  final month = _fullMonths[local.month - 1];
  if (local.year == now.year) return '$month ${local.day}';
  return '$month ${local.day}, ${local.year}';
}
