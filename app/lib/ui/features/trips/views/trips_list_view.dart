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
            child: LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                const horizontalPadding = 16.0;
                const textBlockHeight = 76.0; // title (2 lines) + location + paddings, kept fixed so the grid's childAspectRatio is predictable
                final cardWidth = (constraints.maxWidth - horizontalPadding * 2 - spacing) / 2;
                final aspectRatio = cardWidth / (cardWidth + textBlockHeight);

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: aspectRatio,
                  ),
                  itemCount: trips.length,
                  itemBuilder: (context, index) => _TripCard(
                    trip: trips[index],
                    onTap: () => _openTrip(context, trips[index]),
                  ),
                );
              },
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
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(AppAssets.tripPlaceholder, fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(gradient: AppGradients.imageScrim),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: _DatePill(date: trip.startTime),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(fontSize: 16, height: 1.15),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          trip.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        formatShortDate(date),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onInverseSurface),
      ),
    );
  }
}
