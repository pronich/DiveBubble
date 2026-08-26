const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _fullMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// e.g. "Sat, Jul 18" — kept dependency-free, no `intl` needed for one label.
String formatShortDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${_weekdays[local.weekday - 1]}, ${_months[local.month - 1]} ${local.day}';
}

/// e.g. "Sat, Jul 18, 2026" — same as [formatShortDate] plus the year, for contexts (like
/// Dive Log, which can span many years) where "which year was this" isn't obvious from
/// context the way it is for a trip you just created.
String formatShortDateWithYear(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${formatShortDate(local)}, ${local.year}';
}

/// e.g. "09:30" (24h) — same dependency-free approach as formatShortDate.
String formatTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

/// e.g. "July 15" (same year as now) or "December 27, 2025" (a different year) — the
/// chat's date-separator label, deliberately no "Today"/"Yesterday" special-casing since
/// the reference chat UI this is matching always shows the real date.
String formatChatDateSeparator(DateTime dateTime) {
  final local = dateTime.toLocal();
  final now = DateTime.now();
  final month = _fullMonths[local.month - 1];
  if (local.year == now.year) return '$month ${local.day}';
  return '$month ${local.day}, ${local.year}';
}

/// e.g. "August 2026" — the calendar picker's month header.
String formatMonthYear(DateTime dateTime) => '${_fullMonths[dateTime.month - 1]} ${dateTime.year}';

/// Collapses to a single date when [end] is null or the same calendar day as [start].
String formatDateRange(DateTime start, DateTime? end) {
  if (end == null) return formatShortDate(start);
  final s = start.toLocal();
  final e = end.toLocal();
  if (s.year == e.year && s.month == e.month && s.day == e.day) {
    return formatShortDate(start);
  }
  return '${formatShortDate(start)} – ${formatShortDate(end)}';
}
