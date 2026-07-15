import 'package:flutter/material.dart';

import '../../../../domain/entities/gear_ownership.dart';
import '../../../../domain/gear_item.dart';

/// "X/N in Locker" teaser — tap pushes the full GearLockerPage, same summary-card-then-detail-page
/// pattern as the Certifications section's "See all". Counted against the fixed Essential
/// list only — free-text Additional items aren't part of the denominator.
class GearSummaryCard extends StatelessWidget {
  const GearSummaryCard({super.key, required this.gear, required this.onTap});

  final List<GearOwnership> gear;
  final VoidCallback onTap;

  int get _ownedCount {
    final essentialKeys = kEssentialGearItems.map((i) => i.key).toSet();
    return gear.where((g) => essentialKeys.contains(g.itemKey) && g.status == GearStatus.owned.value).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = kEssentialGearItems.length;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.checkroom_outlined, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gear locker', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '$_ownedCount/$total in Locker',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
