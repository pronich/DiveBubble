import 'package:flutter/material.dart';

/// A lightweight month-grid date picker — dates only, previous/next month navigation, no
/// year-picker toggle or input-mode switcher. Replaces Flutter's stock `showDatePicker`
/// (its Material 3 chrome read as cluttered for this form) with something closer to
/// Momondo's minimal calendar, which is what this was modeled on.
Future<DateTime?> showSimpleDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _SimpleDatePickerDialog(initialDate: initialDate, firstDate: firstDate, lastDate: lastDate),
  );
}

class _SimpleDatePickerDialog extends StatefulWidget {
  const _SimpleDatePickerDialog({required this.initialDate, required this.firstDate, required this.lastDate});

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_SimpleDatePickerDialog> createState() => _SimpleDatePickerDialogState();
}

class _SimpleDatePickerDialogState extends State<_SimpleDatePickerDialog> {
  late DateTime _visibleMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
  late DateTime? _selected = _dateOnly(widget.initialDate);

  static const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool get _canGoPrevious {
    final previousMonthEnd = DateTime(_visibleMonth.year, _visibleMonth.month, 0);
    return !previousMonthEnd.isBefore(_dateOnly(widget.firstDate));
  }

  bool get _canGoNext {
    final nextMonthStart = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    return !nextMonthStart.isAfter(_dateOnly(widget.lastDate));
  }

  void _goToPreviousMonth() => setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1));

  void _goToNextMonth() => setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1));

  bool _isSelectable(DateTime day) => !day.isBefore(_dateOnly(widget.firstDate)) && !day.isAfter(_dateOnly(widget.lastDate));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday - 1; // Monday-start week
    final today = _dateOnly(DateTime.now());

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: _canGoPrevious ? _goToPreviousMonth : null),
                  Expanded(
                    child: Text(
                      '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: _canGoNext ? _goToNextMonth : null),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final letter in _weekdayLetters)
                    Expanded(
                      child: Center(
                        child: Text(
                          letter,
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
                itemCount: leadingBlanks + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < leadingBlanks) return const SizedBox.shrink();
                  final day = index - leadingBlanks + 1;
                  final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
                  final selectable = _isSelectable(date);
                  final isSelected = _selected != null && _selected == date;
                  final isToday = date == today;

                  return Padding(
                    padding: const EdgeInsets.all(2),
                    child: Material(
                      color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: selectable ? () => setState(() => _selected = date) : null,
                        child: Center(
                          child: Text(
                            '$day',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : !selectable
                                      ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                                      : isToday
                                          ? theme.colorScheme.primary
                                          : null,
                              fontWeight: isSelected || isToday ? FontWeight.bold : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _selected == null ? null : () => Navigator.of(context).pop(_selected),
                    child: const Text('Select'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
