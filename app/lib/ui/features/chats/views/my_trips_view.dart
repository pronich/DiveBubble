import 'package:flutter/material.dart';

import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../data/services/realtime_service.dart';
import '../../../../domain/entities/trip.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/theme/semantic_colors.dart';
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
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: trips.length,
              separatorBuilder: (context, _) => const Divider(height: 1, indent: 76),
              itemBuilder: (context, index) => _TripRow(
                trip: trips[index],
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

class _TripRow extends StatelessWidget {
  const _TripRow({required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback onTap;

  bool get _isPast => trip.startTime.isBefore(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                AppAssets.tripPlaceholder,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          trip.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatShortDate(trip.startTime),
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      // Unread indicator (red dot) goes here once the backend tracks last-read-message per user/trip.
                    ],
                  ),
                  const SizedBox(height: 2),
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
                  _StatusPill(isPast: _isPast),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isPast});

  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<SemanticColors>()!;
    final theme = Theme.of(context);
    final background = isPast ? semantic.neutralContainer : semantic.infoContainer;
    final foreground = isPast ? semantic.onNeutralContainer : semantic.onInfoContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        isPast ? 'Past' : 'Active',
        style: theme.textTheme.labelSmall?.copyWith(color: foreground, fontWeight: FontWeight.w600),
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
