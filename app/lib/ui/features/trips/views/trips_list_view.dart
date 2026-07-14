import 'package:flutter/material.dart';

import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/entities/trip.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/theme/app_gradients.dart';
import '../view_models/create_trip_view_model.dart';
import '../view_models/trip_view_model.dart';
import '../view_models/trips_list_view_model.dart';
import 'create_trip_page.dart';
import 'trip_page.dart';

class TripsListView extends StatefulWidget {
  const TripsListView({
    super.key,
    required this.viewModel,
    required this.tripRepository,
    required this.currentUserId,
  });

  final TripsListViewModel viewModel;
  final TripRepository tripRepository;
  final String currentUserId;

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
      appBar: AppBar(
        centerTitle: false,
        title: Text('Explore', style: Theme.of(context).textTheme.headlineSmall),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _openCreateTrip(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create trip'),
              style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
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
                const textBlockHeight = 112.0; // title (2 lines) + location + icon row + paddings, kept fixed so the grid's childAspectRatio is predictable
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
            currentUserId: widget.currentUserId,
          ),
        ),
      ),
    );
  }

  void _openCreateTrip(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateTripPage(
          viewModel: CreateTripViewModel(repository: widget.tripRepository),
          onCreated: (trip) {
            widget.viewModel.loadTrips();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => TripPage(
                  viewModel: TripViewModel(
                    repository: widget.tripRepository,
                    tripId: trip.id,
                    currentUserId: widget.currentUserId,
                  ),
                ),
              ),
            );
          },
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
                  const SizedBox(height: 6),
                  _TripCardBadges(trip: trip),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripCardBadges extends StatelessWidget {
  const _TripCardBadges({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    final style = theme.textTheme.labelSmall?.copyWith(color: color);

    final badges = <Widget>[
      if (trip.minCertification != null) _Badge(icon: Icons.badge_outlined, text: trip.minCertification!, color: color, style: style),
      if (_depthText != null) _Badge(icon: Icons.south, text: _depthText!, color: color, style: style),
      _Badge(icon: Icons.schedule, text: _durationText, color: color, style: style),
      if (_diveCountText != null) _Badge(icon: Icons.scuba_diving_outlined, text: _diveCountText!, color: color, style: style),
    ];

    return Wrap(spacing: 8, runSpacing: 4, children: badges);
  }

  String? get _depthText {
    final min = trip.depthMinM;
    final max = trip.depthMaxM;
    if (min == null && max == null) return null;
    if (min != null && max != null) return min == max ? '${min}m' : '$min–${max}m';
    return max != null ? '≤${max}m' : '${min}m+';
  }

  String? get _diveCountText {
    final min = trip.diveCountMin;
    final max = trip.diveCountMax;
    if (min == null && max == null) return null;
    if (min != null && max != null) return min == max ? '$min' : '$min–$max';
    return max != null ? '≤$max' : '$min+';
  }

  String get _durationText {
    final end = trip.endDate;
    if (end == null) return '1d';
    final start = trip.startTime.toLocal();
    final endLocal = end.toLocal();
    final startDate = DateTime(start.year, start.month, start.day);
    final endDateOnly = DateTime(endLocal.year, endLocal.month, endLocal.day);
    final days = endDateOnly.difference(startDate).inDays + 1;
    return '${days}d';
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.text, required this.color, required this.style});

  final IconData icon;
  final String text;
  final Color color;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 2),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 68),
          child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
        ),
      ],
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
