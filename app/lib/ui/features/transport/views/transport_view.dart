import 'package:flutter/material.dart';

import '../../../../domain/entities/transport_offer.dart';
import '../../../core/auth/ensure_signed_in.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../view_models/transport_view_model.dart';

const _typeLabels = {
  'offer_ride': 'Offering a ride',
  'share_rental': 'Sharing a rental',
};

const _typeIcons = {
  'offer_ride': Icons.directions_car,
  'share_rental': Icons.car_rental,
};

class TransportView extends StatefulWidget {
  const TransportView({super.key, required this.viewModel});

  final TransportViewModel viewModel;

  @override
  State<TransportView> createState() => _TransportViewState();
}

class _TransportViewState extends State<TransportView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          if (widget.viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final error = widget.viewModel.error;
          if (error != null) {
            return Center(child: Text('Error: $error'));
          }

          final offers = widget.viewModel.offers;
          if (offers.isEmpty) {
            return EmptyStateView(
              icon: Icons.directions_car_outlined,
              title: 'Be the first to share transport',
              subtitle: 'Offer a ride or share a rental so others can join you.',
              ctaLabel: 'Add transport info',
              onCtaPressed: () => _openAddSheet(context),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            separatorBuilder: (context, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _OfferTile(
              offer: offers[index],
              onTap: () => _openDetailSheet(context, offers[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddTransportOfferSheet(viewModel: widget.viewModel),
    );
  }

  void _openDetailSheet(BuildContext context, TransportOffer offer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TransportOfferDetailSheet(
        offerId: offer.id,
        viewModel: widget.viewModel,
      ),
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

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              _typeIcons[offer.type] ?? Icons.directions_car,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _typeLabels[offer.type] ?? offer.type,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (offer.seats != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${offer.joinedCount} of ${offer.seats} seats taken',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (offer.details != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      offer.details!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (offer.joined) ...[
              const SizedBox(width: 12),
              const _StatusPill(label: 'Joined', kind: _StatusKind.success),
            ] else if (isFull) ...[
              const SizedBox(width: 12),
              const _StatusPill(label: 'Full', kind: _StatusKind.info),
            ],
          ],
        ),
      ),
    );
  }
}

class _TransportOfferDetailSheet extends StatefulWidget {
  const _TransportOfferDetailSheet({
    required this.offerId,
    required this.viewModel,
  });

  final String offerId;
  final TransportViewModel viewModel;

  @override
  State<_TransportOfferDetailSheet> createState() =>
      _TransportOfferDetailSheetState();
}

class _TransportOfferDetailSheetState
    extends State<_TransportOfferDetailSheet> {
  List<String>? _joinedUserIds;
  String? _error;
  String? _joinError;

  @override
  void initState() {
    super.initState();
    _loadJoinedUserIds();
  }

  Future<void> _loadJoinedUserIds() async {
    try {
      final ids = await widget.viewModel.getJoinedUserIds(widget.offerId);
      if (mounted) setState(() => _joinedUserIds = ids);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _join(TransportOffer offer) async {
    final userId = await ensureSignedIn(context, widget.viewModel.authRepository, widget.viewModel.profileRepository);
    if (userId == null || !mounted) return;

    setState(() => _joinError = null);
    final error = await widget.viewModel.join(offer.id);
    if (!mounted) return;
    if (error != null) {
      setState(() => _joinError = error);
    } else {
      _loadJoinedUserIds();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final offer = widget.viewModel.offers.firstWhere(
              (o) => o.id == widget.offerId,
              orElse: () => widget.viewModel.offers.first,
            );
            final isFull =
                offer.seats != null && offer.joinedCount >= offer.seats!;
            final isOrganizer = offer.userId == widget.viewModel.currentUserId;
            // A diver can only book one ride per trip — don't offer a Join button
            // on other offers once they've already joined one.
            final hasBookingElsewhere = !offer.joined &&
                widget.viewModel.offers.any((o) => o.joined);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_typeIcons[offer.type] ?? Icons.directions_car),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _typeLabels[offer.type] ?? offer.type,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (offer.joined)
                      const _StatusPill(
                        label: 'Joined',
                        kind: _StatusKind.success,
                      )
                    else if (isFull)
                      const _StatusPill(label: 'Full', kind: _StatusKind.info),
                  ],
                ),
                if (offer.details != null) ...[
                  const SizedBox(height: 8),
                  Text(offer.details!, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      child: Icon(
                        Icons.person,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Organizer', style: theme.textTheme.bodyMedium),
                        if (isOrganizer)
                          Text(
                            '(You)',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Joined divers', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                if (_error != null)
                  Text(
                    'Error: $_error',
                    style: TextStyle(color: theme.colorScheme.error),
                  )
                else if (_joinedUserIds == null)
                  const Center(child: CircularProgressIndicator())
                else if (_joinedUserIds!.isEmpty)
                  Text(
                    'No one has joined yet',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  ..._joinedUserIds!.map((userId) {
                    final isMe = userId == widget.viewModel.currentUserId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            child: Icon(
                              Icons.person,
                              size: 18,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isMe ? 'You' : 'Diver',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }),
                if (!offer.joined && !isFull && !hasBookingElsewhere) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: _JoinButton(
                      offer: offer,
                      viewModel: widget.viewModel,
                      onPressed: () => _join(offer),
                    ),
                  ),
                  if (_joinError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _joinError!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _StatusKind { success, info }

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.kind});

  final String label;
  final _StatusKind kind;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<SemanticColors>()!;
    final theme = Theme.of(context);
    final background = kind == _StatusKind.success
        ? semantic.successContainer
        : semantic.infoContainer;
    final foreground = kind == _StatusKind.success
        ? semantic.onSuccessContainer
        : semantic.onInfoContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({
    required this.offer,
    required this.viewModel,
    required this.onPressed,
  });

  final TransportOffer offer;
  final TransportViewModel viewModel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isJoining = viewModel.isJoining(offer.id);
    return ElevatedButton(
      onPressed: isJoining ? null : onPressed,
      child: isJoining
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Join'),
    );
  }
}

class _AddTransportOfferSheet extends StatefulWidget {
  const _AddTransportOfferSheet({required this.viewModel});

  final TransportViewModel viewModel;

  @override
  State<_AddTransportOfferSheet> createState() =>
      _AddTransportOfferSheetState();
}

class _AddTransportOfferSheetState extends State<_AddTransportOfferSheet> {
  String _type = 'offer_ride';
  final _seatsController = TextEditingController();
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _seatsController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add transport info',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _typeLabels.entries.map((entry) {
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: _type == entry.key,
                  onSelected: (_) => setState(() => _type = entry.key),
                );
              }).toList(),
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
              decoration: const InputDecoration(
                labelText: 'Details — time, pickup point (optional)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.viewModel.isSubmitting ? null : _submit,
                child: widget.viewModel.isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final seats = int.tryParse(_seatsController.text.trim());
    final details = _detailsController.text.trim();
    final ok = await widget.viewModel.submit(
      type: _type,
      seats: seats,
      details: details.isEmpty ? null : details,
    );
    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }
}
