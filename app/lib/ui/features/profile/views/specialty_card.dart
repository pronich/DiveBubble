import 'package:flutter/material.dart';

import '../../../../domain/entities/specialty_certification.dart';
import '../../../../ui/core/theme/app_colors.dart';

const double kSpecialtyCardWidth = 220;

/// One color per specialty type, drawn from the existing AppColors palette (no new hexes)
/// so the stack reads as a set of distinct, recognizable cards rather than a flat gray pile.
const Map<String, Color> _kSpecialtyColors = {
  'Enriched Air (Nitrox)': AppColors.success,
  'Deep Diver': AppColors.buttonPrimary,
  'Wreck Diver': AppColors.warning,
  'Night Diver': AppColors.surfaceDark,
  'Dry Suit': AppColors.info,
  'Other': AppColors.neutral,
};

Color colorForSpecialty(String specialty) => _kSpecialtyColors[specialty] ?? AppColors.neutral;

/// Colored per specialty type — the Level card still gets the brand gradient since it's
/// the hero credential, but specialties are now a proper colorful card deck, not gray tiles.
class SpecialtyCard extends StatelessWidget {
  const SpecialtyCard({super.key, required this.specialty, this.onRemove});

  final SpecialtyCertification specialty;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = specialty.specialty == 'Other' && (specialty.customLabel?.isNotEmpty ?? false)
        ? specialty.customLabel!
        : specialty.specialty;
    final color = colorForSpecialty(specialty.specialty);

    return Container(
      width: kSpecialtyCardWidth,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (specialty.agency?.isNotEmpty ?? false)
                Text(
                  specialty.agency!.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textInverse.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                )
              else
                const SizedBox.shrink(),
              if (onRemove != null)
                InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(12),
                  child: const Icon(Icons.close, size: 16, color: AppColors.textInverse),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(color: AppColors.textInverse),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (specialty.certNumber?.isNotEmpty ?? false) ...[
            const SizedBox(height: 6),
            Text(
              specialty.certNumber!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textInverse.withValues(alpha: 0.85),
                letterSpacing: 1,
              ),
            ),
          ],
          if (specialty.verified) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_outlined, size: 14, color: AppColors.textInverse),
                const SizedBox(width: 4),
                Text('Verified', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textInverse)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Empty-state tile — the whole tile is the "Add" affordance, same pattern as AddLevelCard.
class AddSpecialtyCard extends StatelessWidget {
  const AddSpecialtyCard({super.key, required this.onTap});

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
            Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text('Add speciality', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary)),
          ],
        ),
      ),
    );
  }
}
