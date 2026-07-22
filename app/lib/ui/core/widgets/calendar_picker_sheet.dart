import 'package:flutter/material.dart';

import '../formatting/date_format.dart';

const _weekdayHeaders = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

/// A month-grid date picker, Apple Calendar-style layout (weekday header row, chevron month
/// navigation, tap a day to pick it immediately — no separate Cancel/Done step, unlike the
/// wheel picker this replaces for date selection) skinned in DiveBubble's own theme rather
/// than Material's `showDatePicker` look.
Future<DateTime?> showCalendarPicker(
  BuildContext context, {
  DateTime? initialDate,
  DateTime? minimumDate,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final min = minimumDate != null ? DateTime(minimumDate.year, minimumDate.month, minimumDate.day) : today;
  final initial = initialDate ?? (min.isAfter(today) ? min : today);

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CalendarPickerSheet(initialDate: initial, minimumDate: min),
  );
}

class _CalendarPickerSheet extends StatefulWidget {
  const _CalendarPickerSheet({required this.initialDate, required this.minimumDate});

  final DateTime initialDate;
  final DateTime minimumDate;

  @override
  State<_CalendarPickerSheet> createState() => _CalendarPickerSheetState();
}

class _CalendarPickerSheetState extends State<_CalendarPickerSheet> {
  late DateTime _visibleMonth = DateTime(widget.initialDate.year, widget.initialDate.month);

  void _changeMonth(int delta) {
    setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    // DateTime.weekday is already 1=Mon..7=Sun, so a Monday-first grid needs no remapping.
    final leadingBlanks = DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday - 1;
    // Same calendar month as the floor -> can still navigate back into it (to reach days
    // before the selected one that are still >= minimumDate); any earlier month is a dead end.
    final canGoBack = _visibleMonth.year > widget.minimumDate.year ||
        (_visibleMonth.year == widget.minimumDate.year && _visibleMonth.month > widget.minimumDate.month);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    formatMonthYear(_visibleMonth),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: canGoBack ? () => _changeMonth(-1) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            Row(
              children: [
                for (final label in _weekdayHeaders)
                  Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
                for (var day = 1; day <= daysInMonth; day++)
                  _DayCell(
                    date: DateTime(_visibleMonth.year, _visibleMonth.month, day),
                    isSelected: _isSameDay(DateTime(_visibleMonth.year, _visibleMonth.month, day), widget.initialDate),
                    isDisabled: DateTime(_visibleMonth.year, _visibleMonth.month, day).isBefore(widget.minimumDate),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.date, required this.isSelected, required this.isDisabled});

  final DateTime date;
  final bool isSelected;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: isDisabled ? null : () => Navigator.of(context).pop(date),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? theme.colorScheme.primary : null,
          ),
          child: Text(
            '${date.day}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : isDisabled
                      ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                      : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
