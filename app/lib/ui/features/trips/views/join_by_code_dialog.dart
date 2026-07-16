import 'package:flutter/material.dart';

import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/entities/trip.dart';

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
    if (code.isEmpty) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final trip = await widget.tripRepository.joinTripByCode(code);
      if (mounted) Navigator.of(context).pop(trip);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter booking code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Booked a dive-center trip on their own site? Enter the code they gave you to join its Bubble here.'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Booking code', hintText: 'e.g. 8XK2NPQ4'),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Join'),
        ),
      ],
    );
  }
}
