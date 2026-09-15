import 'package:flutter/material.dart';

import '../../../../data/repositories/trip_repository.dart';
import '../../../../data/services/error_codes.dart';
import '../../../../domain/entities/trip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

enum TripRowAction { archive, unarchive, leave, cancel }

/// Long-press menu for a Bubbles-list row — Archive (or Unarchive, from inside the Archive
/// itself) plus Leave/Cancel, same actions and confirmation copy as the Bubble's own
/// _ActionPillsRow (trip_page.dart), just reachable without opening the Bubble first.
/// Deliberately skips Leave/Cancel for business trips: telling "am I this dive center's
/// organizer" apart from "am I just a diver on their trip" needs the same membership check
/// _ActionPillsRow's host (TripViewModel) already does — not worth re-deriving here for a
/// quick menu when staff already have Cancel inside the Bubble (or admin/) either way.
Future<void> showTripRowActionsSheet(
  BuildContext context, {
  required Trip trip,
  required String currentUserId,
  required TripRepository tripRepository,
  required bool isArchived,
  required Future<void> Function() onArchiveToggled,
  required VoidCallback onLeftOrCancelled,
}) async {
  final isOrganizer = trip.creatorUserId == currentUserId;
  final canLeaveOrCancel = trip.diveCenterId == null;

  final action = await showModalBottomSheet<TripRowAction>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(isArchived ? Icons.unarchive_outlined : Icons.archive_outlined),
              title: Text(isArchived ? l10n.unarchive : l10n.archive),
              onTap: () => Navigator.of(
                context,
              ).pop(isArchived ? TripRowAction.unarchive : TripRowAction.archive),
            ),
            if (canLeaveOrCancel)
              if (isOrganizer && trip.bookingStatus != 'cancelled')
                ListTile(
                  leading: Icon(Icons.cancel_outlined, color: Theme.of(context).colorScheme.error),
                  title: Text(
                    l10n.cancelTrip,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  onTap: () => Navigator.of(context).pop(TripRowAction.cancel),
                )
              else if (!isOrganizer)
                ListTile(
                  leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                  title: Text(l10n.leave, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  onTap: () => Navigator.of(context).pop(TripRowAction.leave),
                ),
          ],
        ),
      );
    },
  );
  if (action == null || !context.mounted) return;

  switch (action) {
    case TripRowAction.archive:
    case TripRowAction.unarchive:
      try {
        await onArchiveToggled();
      } catch (e) {
        if (!context.mounted) return;
        final message = action == TripRowAction.archive
            ? AppLocalizations.of(context).couldNotArchive(friendlyError(e))
            : AppLocalizations.of(context).couldNotUnarchive(friendlyError(e));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    case TripRowAction.leave:
      await _confirmAndLeave(context, tripRepository, trip, onLeftOrCancelled);
    case TripRowAction.cancel:
      await _confirmAndCancel(context, tripRepository, trip, onLeftOrCancelled);
  }
}

Future<void> _confirmAndLeave(
  BuildContext context,
  TripRepository tripRepository,
  Trip trip,
  VoidCallback onDone,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return AlertDialog(
        title: Text(l10n.leaveBubbleTitle),
        content: Text(l10n.leaveBubbleBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
          TextButton(
            style: AppButtonStyles.ghost.copyWith(
              foregroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.error),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.leave),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await tripRepository.leaveTrip(trip.id);
    onDone();
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).couldNotLeave(friendlyError(e)))));
  }
}

Future<void> _confirmAndCancel(
  BuildContext context,
  TripRepository tripRepository,
  Trip trip,
  VoidCallback onDone,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return AlertDialog(
        title: Text(l10n.cancelTripTitle),
        content: Text(l10n.cancelTripBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.neverMind),
          ),
          TextButton(
            style: AppButtonStyles.ghost.copyWith(
              foregroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.error),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.cancelTrip),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await tripRepository.cancelTrip(trip.id);
    onDone();
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).couldNotCancel(friendlyError(e)))));
  }
}
