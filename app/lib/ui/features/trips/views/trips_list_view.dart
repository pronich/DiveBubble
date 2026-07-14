import 'package:flutter/material.dart';

import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/entities/trip.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/theme/app_gradients.dart';
import '../view_models/trip_view_model.dart';
import '../view_models/trips_list_view_model.dart';
import 'trip_page.dart';

class TripsListView extends StatefulWidget {
  const TripsListView({
    super.key,
    required this.viewModel,
    required this.tripRepository,
  });

  final TripsListViewModel viewModel;
  final TripRepository tripRepository;

  @override
  State<TripsListView> createState() => _TripsListViewState();
}

class _TripsListViewState extends State<TripsListView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadTrips();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
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

          final trips = widget.viewModel.trips;
          if (trips.isEmpty) {
            return const Center(child: Text('No trips yet'));
          }

          return RefreshIndicator(
            onRefresh: widget.viewModel.loadTrips,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: trips.length,
              itemBuilder: (context, index) => _TripCard(
                trip: trips[index],
                onTap: () => _openTrip(context, trips[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openTrip(BuildContext context, Trip trip) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripPage(
          viewModel: TripViewModel(
            repository: widget.tripRepository,
            tripId: trip.id,
          ),
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(AppAssets.tripPlaceholder, fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(gradient: AppGradients.imageScrim),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: _DatePill(date: trip.startTime),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trip.title, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(trip.location, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Details', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
                        Icon(Icons.arrow_forward, size: 16, color: theme.colorScheme.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        formatShortDate(date),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onInverseSurface),
      ),
    );
  }
}
