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
