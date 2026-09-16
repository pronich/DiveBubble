/// The ¤ glyph is a deliberate generic placeholder — real multi-currency handling is deferred, so amounts must not imply DKK (or any currency) is the only one supported.
String formatExpenseAmount(int amountMinor) => '¤${(amountMinor / 100).toStringAsFixed(2)}';

/// Accepts both '.' and ',' as the decimal separator.
int? parseExpenseAmountMinor(String input) {
  final normalized = input.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  final value = double.tryParse(normalized);
  if (value == null || value < 0) return null;
  return (value * 100).round();
}
