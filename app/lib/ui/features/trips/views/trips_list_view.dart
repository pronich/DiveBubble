import 'package:flutter/material.dart';

import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/entities/trip.dart';
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
              itemCount: trips.length,
              itemBuilder: (context, index) => _TripTile(
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

class _TripTile extends StatelessWidget {
  const _TripTile({required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(trip.title),
      subtitle: Text('${trip.location} · ${trip.startTime.toLocal()}'),
      onTap: onTap,
    );
  }
}
