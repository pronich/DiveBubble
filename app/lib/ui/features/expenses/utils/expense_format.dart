/// The ¤ glyph is Unicode's own generic "some currency" sign — used everywhere in this
/// feature instead of a real symbol/code so amounts don't imply DKK (or any currency) is
/// the only one Expenses will ever support. See DiveBubble's CLAUDE.md/product decision:
/// real multi-currency handling is deferred until there's evidence divers actually want it.
String formatExpenseAmount(int amountMinor) => '¤${(amountMinor / 100).toStringAsFixed(2)}';

/// Parses a diver-typed amount (accepts both '.' and ',' as the decimal separator) into
/// minor units, or null if it isn't a valid non-negative number.
int? parseExpenseAmountMinor(String input) {
  final normalized = input.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  final value = double.tryParse(normalized);
  if (value == null || value < 0) return null;
  return (value * 100).round();
}
