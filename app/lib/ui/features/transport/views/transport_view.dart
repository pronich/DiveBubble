import 'package:flutter/material.dart';

import '../../../../domain/entities/transport_offer.dart';
import '../view_models/transport_view_model.dart';

const _typeLabels = {
  'offer_ride': 'Offering a ride',
  'find_ride': 'Looking for a ride',
  'share_rental': 'Sharing a rental',
  'self_arranged': "Getting there myself",
};

const _typeIcons = {
  'offer_ride': Icons.directions_car,
  'find_ride': Icons.person_search,
  'share_rental': Icons.car_rental,
  'self_arranged': Icons.directions_walk,
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No transport offers yet'),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: () => _openAddSheet(context), child: const Text('Add transport info')),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            separatorBuilder: (context, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _OfferTile(offer: offers[index]),
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
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({required this.offer});

  final TransportOffer offer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_typeIcons[offer.type] ?? Icons.directions_car, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeLabels[offer.type] ?? offer.type,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (offer.seats != null) ...[
                  const SizedBox(height: 2),
                  Text('${offer.seats} seat${offer.seats == 1 ? '' : 's'}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
                if (offer.details != null) ...[
                  const SizedBox(height: 2),
                  Text(offer.details!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTransportOfferSheet extends StatefulWidget {
  const _AddTransportOfferSheet({required this.viewModel});

  final TransportViewModel viewModel;

  @override
  State<_AddTransportOfferSheet> createState() => _AddTransportOfferSheetState();
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
    return Padding(
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
          Text('Add transport info', style: Theme.of(context).textTheme.titleMedium),
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
            decoration: const InputDecoration(labelText: 'Details — time, pickup point (optional)'),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: widget.viewModel.isSubmitting ? null : _submit,
            child: widget.viewModel.isSubmitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Add'),
          ),
        ],
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
