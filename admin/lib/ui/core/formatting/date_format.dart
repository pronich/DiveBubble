const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// e.g. "Sat, Jul 18" — same dependency-free approach as app/'s equivalent, kept as a
/// separate copy rather than a shared package (see CLAUDE.md: admin/ doesn't share code
/// with app/ yet, a deliberate MVP choice, not an oversight).
String formatShortDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${_weekdays[local.weekday - 1]}, ${_months[local.month - 1]} ${local.day}';
}

/// e.g. "125.00" from 12500 minor units — always 2 decimals, matching how DKK/øre display.
String formatPriceMinor(int minor) => (minor / 100).toStringAsFixed(2);
