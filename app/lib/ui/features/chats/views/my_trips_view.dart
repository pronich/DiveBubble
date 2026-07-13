import 'package:flutter/material.dart';

import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../data/services/realtime_service.dart';
import '../../../../domain/entities/trip.dart';
import '../view_models/chat_view_model.dart';
import '../view_models/my_trips_view_model.dart';
import 'chat_view.dart';

class MyTripsView extends StatefulWidget {
  const MyTripsView({
    super.key,
    required this.viewModel,
    required this.chatRepository,
    required this.tripRepository,
    required this.realtimeService,
    required this.currentUserId,
    required this.onGoToExplore,
  });

  final MyTripsViewModel viewModel;
  final ChatRepository chatRepository;
  final TripRepository tripRepository;
  final RealtimeService realtimeService;
  final String currentUserId;
  final VoidCallback onGoToExplore;

  @override
  State<MyTripsView> createState() => _MyTripsViewState();
}

class _MyTripsViewState extends State<MyTripsView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trips')),
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
            return _EmptyTrips(onGetStarted: widget.onGoToExplore);
          }

          return RefreshIndicator(
            onRefresh: widget.viewModel.load,
            child: ListView.builder(
              itemCount: trips.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(trips[index].title),
                subtitle: Text(trips[index].location),
                onTap: () => _openChat(context, trips[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openChat(BuildContext context, Trip trip) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatView(
          viewModel: ChatViewModel(
            repository: widget.chatRepository,
            realtimeService: widget.realtimeService,
            tripId: trip.id,
            currentUserId: widget.currentUserId,
          ),
          tripTitle: trip.title,
          tripRepository: widget.tripRepository,
        ),
      ),
    );
  }
}

class _EmptyTrips extends StatelessWidget {
  const _EmptyTrips({required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No trips yet'),
            const SizedBox(height: 8),
            const Text('Join a trip to start chatting with the group here.'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onGetStarted, child: const Text('Get started')),
          ],
        ),
      ),
    );
  }
}
