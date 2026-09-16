import 'package:flutter/material.dart';

import '../../../../domain/entities/trip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/theme/semantic_colors.dart';

/// Shared by My Trips and ChooseBubblePage; [showBadges] is the one real difference, since the picker isn't showing what's new.
class TripRow extends StatelessWidget {
  const TripRow({
    required this.trip,
    required this.onTap,
    this.onLongPress,
    this.showBadges = true,
  });

  final Trip trip;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool showBadges;

  // Past once the trip's last calendar day fully ends, not the moment startTime passes, or a multi-day trip would flip to Past on its first morning.
  bool get _isPast {
    final lastDay = (trip.endDate ?? trip.startTime).toUtc();
    final cutoff = DateTime.utc(lastDay.year, lastDay.month, lastDay.day + 1);
    return !DateTime.now().toUtc().isBefore(cutoff);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: (trip.photoUrl?.isNotEmpty ?? false)
                  ? Image.network(
                      trip.photoUrl!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        AppAssets.tripPlaceholder,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      AppAssets.tripPlaceholder,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          trip.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatShortDate(trip.startTime),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (showBadges && trip.unreadCount > 0) ...[
                        const SizedBox(width: 6),
                        _UnreadBadge(count: trip.unreadCount),
                      ],
                      if (showBadges && (trip.hasTransportAlert || trip.hasUnreadTransportMessages)) ...[
                        const SizedBox(width: 6),
                        const _TransportAlertDot(),
                      ],
                      if (showBadges && (trip.hasBuddyAlert || trip.hasUnreadBuddyMessages)) ...[
                        const SizedBox(width: 6),
                        const _BuddyAlertDot(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          trip.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (showBadges) ...[
                    const SizedBox(height: 6),
                    _StatusPill(isPast: _isPast, isCancelled: trip.bookingStatus == 'cancelled'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onError,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

// Distinct from _UnreadBadge on purpose: a dissolved offer/request or unread car-chat message isn't the trip's general unread count, so it gets its own (info, not error-red) visual language.
class _TransportAlertDot extends StatelessWidget {
  const _TransportAlertDot();

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<SemanticColors>()!;
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: semantic.infoContainer, shape: BoxShape.circle),
      child: Icon(Icons.directions_car, size: 12, color: semantic.onInfoContainer),
    );
  }
}

class _BuddyAlertDot extends StatelessWidget {
  const _BuddyAlertDot();

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<SemanticColors>()!;
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: semantic.infoContainer, shape: BoxShape.circle),
      child: Icon(Icons.people_outline, size: 12, color: semantic.onInfoContainer),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isPast, required this.isCancelled});

  final bool isPast;
  final bool isCancelled;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<SemanticColors>()!;
    final theme = Theme.of(context);

    final String label;
    final Color background;
    final Color foreground;
    // Cancelled outranks Active/Past — same priority call as Trip Page's status pill.
    if (isCancelled) {
      label = AppLocalizations.of(context).cancelledStatus;
      background = theme.colorScheme.surfaceContainerHighest;
      foreground = theme.colorScheme.onSurfaceVariant;
    } else if (isPast) {
      label = AppLocalizations.of(context).pastStatus;
      background = semantic.neutralContainer;
      foreground = semantic.onNeutralContainer;
    } else {
      label = AppLocalizations.of(context).activeStatus;
      background = semantic.infoContainer;
      foreground = semantic.onInfoContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }
}
