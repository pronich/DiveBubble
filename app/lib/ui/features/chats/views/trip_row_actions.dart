import 'package:flutter/material.dart';

import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/entities/trip.dart';
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
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(isArchived ? Icons.unarchive_outlined : Icons.archive_outlined),
            title: Text(isArchived ? 'Unarchive' : 'Archive'),
            onTap: () => Navigator.of(
              context,
            ).pop(isArchived ? TripRowAction.unarchive : TripRowAction.archive),
          ),
          if (canLeaveOrCancel)
            if (isOrganizer && trip.bookingStatus != 'cancelled')
              ListTile(
                leading: Icon(Icons.cancel_outlined, color: Theme.of(context).colorScheme.error),
                title: Text(
                  'Cancel trip',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () => Navigator.of(context).pop(TripRowAction.cancel),
              )
            else if (!isOrganizer)
              ListTile(
                leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                title: Text('Leave', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () => Navigator.of(context).pop(TripRowAction.leave),
              ),
        ],
      ),
    ),
  );
  if (action == null || !context.mounted) return;

  switch (action) {
    case TripRowAction.archive:
    case TripRowAction.unarchive:
      try {
        await onArchiveToggled();
      } catch (e) {
        if (!context.mounted) return;
        final verb = action == TripRowAction.archive ? 'archive' : 'unarchive';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not $verb: $e')));
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
    builder: (context) => AlertDialog(
      title: const Text('Leave this Bubble?'),
      content: const Text("You'll lose your spot and can rejoin later if there's room."),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        TextButton(
          style: AppButtonStyles.ghost.copyWith(
            foregroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.error),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Leave'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await tripRepository.leaveTrip(trip.id);
    onDone();
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not leave: $e')));
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
    builder: (context) => AlertDialog(
      title: const Text('Cancel this trip?'),
      content: const Text(
        "Every participant keeps the Bubble to see the chat history, but no one — including you — "
        "can send messages, join, or arrange transport anymore. This can't be undone.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Never mind'),
        ),
        TextButton(
          style: AppButtonStyles.ghost.copyWith(
            foregroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.error),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Cancel trip'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await tripRepository.cancelTrip(trip.id);
    onDone();
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not cancel: $e')));
  }
}
