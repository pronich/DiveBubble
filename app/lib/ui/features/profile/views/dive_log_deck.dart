import 'package:flutter/material.dart';

import '../../../../domain/entities/dive_log_entry.dart';
import '../../../core/theme/app_colors.dart';
import 'dive_log_card.dart';

/// Same peeking-stack look as SpecialtiesSection's collapsed deck, but purely a static
/// teaser here — there's no in-place expand, tapping always pushes DiveLogListPage's own
/// full vertical list. A dedicated list page reads better for entries a diver might have
/// dozens of (an import can add many at once), unlike Specialties' typically-small count.
class DiveLogDeck extends StatelessWidget {
  const DiveLogDeck({super.key, required this.entries, required this.onTap});

  final List<DiveLogEntry> entries;
  final VoidCallback onTap;

  static const double _cardHeight = 150;
  static const double _peekOffset = 12;
  static const int _maxPeek = 3;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return _AddDiveLogCard(onTap: onTap);

    final theme = Theme.of(context);
    final n = entries.length;
    final peekCount = n > _maxPeek ? _maxPeek : n;
    final collapsedWidth = kDiveLogCardWidth + (peekCount - 1) * _peekOffset;

    return LayoutBuilder(
      builder: (context, constraints) {
        final centerOffset = ((constraints.maxWidth - collapsedWidth) / 2).clamp(
          0.0,
          double.infinity,
        );

        return GestureDetector(
          onTap: onTap,
          // Without this, only the area actually painted by a descendant (the front card,
          // the count badge) registers a hit — GestureDetector's default deferToChild
          // behavior means empty space anywhere else in this box (around the peeking cards,
          // to their sides) silently swallows the tap instead of opening the list.
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: constraints.maxWidth,
            height: _cardHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Painted back-to-front so the most recent dive (i=0) ends up on top.
                for (var i = peekCount - 1; i >= 0; i--)
                  Positioned(
                    left: centerOffset + i * _peekOffset,
                    top: 0,
                    child: IgnorePointer(
                      // Only the front card's own InkWell would be reachable anyway (it's
                      // painted last/topmost) — this just makes that explicit and avoids
                      // relying on paint order for hit-testing.
                      child: SizedBox(
                        width: kDiveLogCardWidth,
                        height: _cardHeight,
                        child: DiveLogCard(entry: entries[i]),
                      ),
                    ),
                  ),
                Positioned(
                  left: centerOffset + collapsedWidth - 34,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      '$n',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AddDiveLogCard extends StatelessWidget {
  const _AddDiveLogCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Column(
          children: [
            Icon(Icons.scuba_diving_outlined, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              'Add a dive',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
