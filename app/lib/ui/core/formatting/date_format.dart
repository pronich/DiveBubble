const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// e.g. "Sat, Jul 18" — kept dependency-free, no `intl` needed for one label.
String formatShortDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${_weekdays[local.weekday - 1]}, ${_months[local.month - 1]} ${local.day}';
}

/// e.g. "09:30" (24h) — same dependency-free approach as formatShortDate.
String formatTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

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
