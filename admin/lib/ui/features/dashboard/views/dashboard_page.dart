import 'package:flutter/material.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/dive_center_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/entities/dive_center.dart';
import '../../../../domain/entities/trip.dart';
import '../../../core/formatting/date_format.dart';
import '../../trips/views/create_trip_page.dart';
import '../view_models/dashboard_view_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.diveCenter,
    required this.diveCenterRepository,
    required this.tripRepository,
    required this.authRepository,
    required this.onSignedOut,
  });

  final DiveCenter diveCenter;
  final DiveCenterRepository diveCenterRepository;
  final TripRepository tripRepository;
  final AuthRepository authRepository;
  final VoidCallback onSignedOut;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final _viewModel = DashboardViewModel(repository: widget.tripRepository, diveCenterId: widget.diveCenter.id);

  @override
  void initState() {
    super.initState();
    _viewModel.load();
  }

  Future<void> _openCreateTrip() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateTripPage(tripRepository: widget.tripRepository, diveCenterId: widget.diveCenter.id),
      ),
    );
    if (created == true) _viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.diveCenter.name),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await widget.authRepository.signOut();
              widget.onSignedOut();
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: RefreshIndicator(
                onRefresh: _viewModel.load,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Trips', style: theme.textTheme.titleLarge),
                        FilledButton.icon(
                          onPressed: _openCreateTrip,
                          icon: const Icon(Icons.add),
                          label: const Text('Create trip'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_viewModel.isLoading)
                      const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: CircularProgressIndicator()))
                    else if (_viewModel.error != null)
                      Text('Error: ${_viewModel.error}', style: TextStyle(color: theme.colorScheme.error))
                    else if (_viewModel.trips.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text(
                            'No trips yet — create your first one.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      )
                    else
                      ..._viewModel.trips.map((t) => _TripRow(trip: t)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TripRow extends StatelessWidget {
  const _TripRow({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceMinor = trip.priceMinor;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(trip.title),
        subtitle: Text('${formatShortDate(trip.startTime)} · ${trip.location}'),
        trailing: priceMinor != null
            ? Text('${formatPriceMinor(priceMinor)} ${trip.currency}', style: theme.textTheme.titleMedium)
            : Text('No price', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ),
    );
  }
}
