import 'package:flutter/material.dart';

import '../../../../domain/entities/transport_offer.dart';
import '../../transport/view_models/transport_view_model.dart';

const _typeLabels = {'offer_ride': 'Offering a ride', 'share_rental': 'Sharing a rental'};
const _typeIcons = {'offer_ride': Icons.directions_car, 'share_rental': Icons.car_rental};

/// Transport tab content for one open Bubble — embedded next to Chat in BubblesPage's
/// _Conversation (see its own comment: transport lives inside the Bubble, not as its own
/// top-level admin section, same "one place holds everything about this trip" idea app/'s
/// TripConversationPage already follows with its Chat/Transport tabs).
class TransportTab extends StatelessWidget {
  const TransportTab({super.key, required this.viewModel});

  final TransportViewModel viewModel;

  Future<void> _openAddOfferDialog(BuildContext context) async {
    await showDialog<bool>(context: context, builder: (_) => _AddOfferDialog(viewModel: viewModel));
  }

  void _openOfferDetail(BuildContext context, TransportOffer offer) {
    showDialog<void>(context: context, builder: (_) => _OfferDetailDialog(viewModel: viewModel, offer: offer));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final offers = viewModel.offers;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Transport offers',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _openAddOfferDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('New offer'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : offers.isEmpty
                      ? Center(
                          child: Text(
                            'No transport offered for this trip yet.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: offers.length,
                          separatorBuilder: (context, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) => _OfferTile(offer: offers[index], onTap: () => _openOfferDetail(context, offers[index])),
                        ),
            ),
          ],
        );
      },
    );
  }
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({required this.offer, required this.onTap});

  final TransportOffer offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFull = offer.seats != null && offer.joinedCount >= offer.seats!;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(_typeIcons[offer.type] ?? Icons.directions_car, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_typeLabels[offer.type] ?? offer.type, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    if (offer.seats != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${offer.joinedCount} of ${offer.seats} seats taken',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                    if (offer.details != null) ...[
                      const SizedBox(height: 2),
                      Text(offer.details!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
              if (isFull)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: theme.colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    'Full',
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddOfferDialog extends StatefulWidget {
  const _AddOfferDialog({required this.viewModel});

  final TransportViewModel viewModel;

  @override
  State<_AddOfferDialog> createState() => _AddOfferDialogState();
}

class _AddOfferDialogState extends State<_AddOfferDialog> {
  String _type = 'offer_ride';
  final _seatsController = TextEditingController();
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _seatsController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final seats = int.tryParse(_seatsController.text.trim());
    final details = _detailsController.text.trim();
    final ok = await widget.viewModel.submit(type: _type, seats: seats, details: details.isEmpty ? null : details);
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('New transport offer'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _typeLabels.entries
                  .map((entry) => ChoiceChip(label: Text(entry.value), selected: _type == entry.key, onSelected: (_) => setState(() => _type = entry.key)))
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _seatsController,
              decoration: const InputDecoration(labelText: 'Seats (optional)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsController,
              decoration: const InputDecoration(labelText: 'Details — time, pickup point (optional)'),
              maxLines: 2,
            ),
            if (widget.viewModel.error != null) ...[
              const SizedBox(height: 12),
              Text('Error: ${widget.viewModel.error}', style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(
          onPressed: widget.viewModel.isSubmitting ? null : _submit,
          child: widget.viewModel.isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Add'),
        ),
      ],
    );
  }
}

class _OfferDetailDialog extends StatefulWidget {
  const _OfferDetailDialog({required this.viewModel, required this.offer});

  final TransportViewModel viewModel;
  final TransportOffer offer;

  @override
  State<_OfferDetailDialog> createState() => _OfferDetailDialogState();
}

class _OfferDetailDialogState extends State<_OfferDetailDialog> {
  List<String>? _joinedUserIds;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ids = await widget.viewModel.getJoinedUserIds(widget.offer.id);
      if (!mounted) return;
      setState(() => _joinedUserIds = ids);
      for (final id in ids) {
        widget.viewModel.resolveProfile(id);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offer = widget.offer;

    return AlertDialog(
      title: Row(
        children: [
          Icon(_typeIcons[offer.type] ?? Icons.directions_car),
          const SizedBox(width: 8),
          Expanded(child: Text(_typeLabels[offer.type] ?? offer.type)),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (offer.details != null) ...[
              Text(offer.details!, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
            ],
            Text('Joined divers', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            if (_error != null)
              Text('Error: $_error', style: TextStyle(color: theme.colorScheme.error))
            else if (_joinedUserIds == null)
              const Center(child: CircularProgressIndicator())
            else if (_joinedUserIds!.isEmpty)
              Text('No one has joined yet', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))
            else
              ListenableBuilder(
                listenable: widget.viewModel,
                builder: (context, _) => Column(
                  children: _joinedUserIds!.map((userId) {
                    final profile = widget.viewModel.profiles[userId];
                    final name = (profile?.displayName?.isNotEmpty ?? false) ? profile!.displayName! : 'Diver';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: theme.colorScheme.secondaryContainer,
                            backgroundImage: (profile?.avatarUrl?.isNotEmpty ?? false) ? NetworkImage(profile!.avatarUrl!) : null,
                            child: (profile?.avatarUrl?.isNotEmpty ?? false) ? null : Icon(Icons.person, size: 18, color: theme.colorScheme.onSecondaryContainer),
                          ),
                          const SizedBox(width: 12),
                          Text(name, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
    );
  }
}
