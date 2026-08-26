import 'package:flutter/material.dart';

import '../../../../domain/entities/dive_log_entry.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/theme/app_colors.dart';

const double kDiveLogCardWidth = 220;

/// One dive's mini-card, peeking in the profile's DiveLogDeck teaser — mirrors SpecialtyCard's
/// shape (fixed width, rounded border, a couple of stat lines). The full DiveLogListPage uses
/// a plain ListTile instead of this — a fixed-width card reads oddly stretched across a full
/// vertical list.
class DiveLogCard extends StatelessWidget {
  const DiveLogCard({super.key, required this.entry, this.onTap});

  final DiveLogEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: kDiveLogCardWidth,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.scuba_diving_outlined, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    formatShortDate(entry.divedAt),
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (entry.siteName?.isNotEmpty ?? false) ...[
              const SizedBox(height: 4),
              Text(
                entry.siteName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _Stat(icon: Icons.arrow_downward, value: _depthText(entry.maxDepthM)),
                const SizedBox(width: 12),
                _Stat(icon: Icons.timer_outlined, value: _durationText(entry.durationMinutes)),
              ],
            ),
            const SizedBox(height: 6),
            _Stat(icon: Icons.thermostat, value: _tempText(entry.minTemperatureC)),
          ],
        ),
      ),
    );
  }
}

String _depthText(double? m) => m == null ? '—' : '${m.toStringAsFixed(0)}m';
String _durationText(int? minutes) => minutes == null ? '—' : '${minutes}min';
String _tempText(double? c) => c == null ? '—' : '${c.toStringAsFixed(0)}°C';

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(value, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
