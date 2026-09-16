import 'package:flutter/material.dart';

import '../../../../data/services/error_codes.dart';

import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/entities/trip.dart';
import '../../../../l10n/app_localizations.dart';

/// Shared entry point for redeeming a business trip's booking code — used both from
/// Explore's header ("Join trip", no specific trip in context — the code alone resolves
/// one) and from a business trip's own Trip Page (contextual, same flow). Returns the
/// resolved trip on success, or null if the diver cancelled.
Future<Trip?> showJoinByCodeDialog(BuildContext context, TripRepository tripRepository) {
  return showDialog<Trip>(
    context: context,
    builder: (_) => _JoinByCodeDialog(tripRepository: tripRepository),
  );
}

class _JoinByCodeDialog extends StatefulWidget {
  const _JoinByCodeDialog({required this.tripRepository});

  final TripRepository tripRepository;

  @override
  State<_JoinByCodeDialog> createState() => _JoinByCodeDialogState();
}

class _JoinByCodeDialogState extends State<_JoinByCodeDialog> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim();
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final trip = await widget.tripRepository.joinTripByCode(code);
      if (mounted) Navigator.of(context).pop(trip);
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.enterBookingCodeTitle),
      // Off by default — on a small screen the keyboard (autofocus below triggers it
      // immediately) can shrink the available height enough that the content column no
      // longer fits, and without this the TextField itself is what silently collapses to
      // zero height while the title/actions stay visible, not the whole dialog.
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.bookingCodeDialogBody),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: l10n.bookingCodeLabel, hintText: l10n.bookingCodeHint),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.join),
        ),
      ],
    );
  }
}
