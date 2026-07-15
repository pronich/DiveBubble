import 'package:flutter/material.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_gradients.dart';

/// Full-size wallet-style card for the diver's current certification level —
/// deliberately not the same as Overview's compact "Level" stat tile (that one
/// stays a short text value; this shows agency/number/verified detail).
class LevelCard extends StatelessWidget {
  const LevelCard({super.key, required this.level, this.agency, this.number, this.verified = false});

  final String level;
  final String? agency;
  final String? number;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: AppGradients.compact, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (agency != null)
                Text(
                  agency!.toUpperCase(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              const Icon(Icons.workspace_premium_outlined, color: AppColors.textInverse),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            level,
            style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.textInverse),
          ),
          if (number?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  number!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textInverse.withValues(alpha: 0.85),
                    letterSpacing: 1.5,
                  ),
                ),
                if (verified) ...[
                  const SizedBox(width: 12),
                  const _VerifiedBadge(),
                ],
              ],
            ),
          ] else if (verified) ...[
            const SizedBox(height: 12),
            const _VerifiedBadge(),
          ],
        ],
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.textInverse.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_outlined, size: 14, color: AppColors.textInverse),
          const SizedBox(width: 4),
          Text(
            'Verified',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.textInverse, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Empty-state tile shown in place of the card when no level has been added yet —
/// the whole tile is the "Add" affordance, not a separate button next to a blank card.
class AddLevelCard extends StatelessWidget {
  const AddLevelCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Column(
          children: [
            Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text('Add certificate', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary)),
          ],
        ),
      ),
    );
  }
}
