import 'package:flutter/material.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/buddy_repository.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/repositories/dive_center_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/push_repository.dart';
import '../../../../data/repositories/transport_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../data/services/realtime_service.dart';
import '../../../../domain/entities/trip.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../onboarding/views/login_sheet.dart';
import '../view_models/my_trips_view_model.dart';
import 'trip_conversation_page.dart';
import 'trip_row.dart';

class MyTripsView extends StatefulWidget {
  const MyTripsView({
    super.key,
    required this.viewModel,
    required this.chatRepository,
    required this.tripRepository,
    required this.transportRepository,
    required this.buddyRepository,
    required this.realtimeService,
    required this.authRepository,
    required this.profileRepository,
    required this.pushRepository,
    required this.diveCenterRepository,
    required this.currentUserId,
    required this.onGoToExplore,
  });

  final MyTripsViewModel viewModel;
  final ChatRepository chatRepository;
  final TripRepository tripRepository;
  final TransportRepository transportRepository;
  final BuddyRepository buddyRepository;
  final RealtimeService realtimeService;
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final PushRepository pushRepository;
  final DiveCenterRepository diveCenterRepository;
  final String currentUserId;
  final VoidCallback onGoToExplore;

  @override
  State<MyTripsView> createState() => _MyTripsViewState();
}

class _MyTripsViewState extends State<MyTripsView> {
  // Refreshes on app resume too — trips/messages may have changed while backgrounded.
  late final _lifecycleListener = AppLifecycleListener(
    onResume: widget.viewModel.load,
  );
  String _search = '';

  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
    // Reload once signed in — this tab may have already loaded (and cached "needs sign in")
    // before the user logged in via some other screen's gate (Create trip, Join, etc.).
    widget.authRepository.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    widget.authRepository.removeListener(_onAuthChanged);
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _onAuthChanged() => widget.viewModel.load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bubbles',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          if (widget.viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.viewModel.needsSignIn) {
            return EmptyStateView(
              icon: Icons.login,
              title: 'Sign in to see your trips',
              subtitle:
                  'Log in to view the trips you\'ve joined and their group chats.',
              ctaLabel: 'Dive in',
              onCtaPressed: () async {
                final signedIn = await LoginSheet.show(
                  context,
                  authRepository: widget.authRepository,
                  profileRepository: widget.profileRepository,
                  pushRepository: widget.pushRepository,
                );
                if (signedIn) widget.viewModel.load();
              },
            );
          }

          final error = widget.viewModel.error;
          if (error != null) {
            return Center(child: Text('Error: $error'));
          }

          final allTrips = widget.viewModel.trips;
          if (allTrips.isEmpty) {
            return EmptyStateView(
              icon: Icons.luggage_outlined,
              title: 'No Bubbles yet',
              subtitle:
                  'Join a trip in Explore and it becomes your Bubble here — chat, transport, and trip details all in one place.',
              ctaLabel: 'Explore trips',
              onCtaPressed: widget.onGoToExplore,
            );
          }

          final query = _search.trim().toLowerCase();
          final trips = query.isEmpty
              ? allTrips
              : allTrips
                    .where((t) => t.title.toLowerCase().contains(query))
                    .toList();

          return Column(
            children: [
              // Only shown once there's more than a handful to search through — a single
              // Bubble doesn't need a search box sitting above it.
              if (allTrips.length > 5)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search Bubbles',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    onChanged: (value) => setState(() => _search = value),
                  ),
                ),
              Expanded(
                child: trips.isEmpty
                    ? Center(
                        child: Text(
                          'No matches.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: widget.viewModel.load,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: trips.length,
                          separatorBuilder: (context, _) =>
                              const Divider(height: 1, indent: 76),
                          itemBuilder: (context, index) => TripRow(
                            trip: trips[index],
                            onTap: () => _openChat(context, trips[index]),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openChat(BuildContext context, Trip trip) async {
    // Fire-and-forget — a failed mark-read shouldn't block opening the chat, it just
    // means the unread badge lingers until the next successful one.
    widget.tripRepository.markRead(trip.id).catchError((_) {});
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripConversationPage.forTrip(
          trip: trip,
          currentUserId: widget.currentUserId,
          tripRepository: widget.tripRepository,
          chatRepository: widget.chatRepository,
          transportRepository: widget.transportRepository,
          buddyRepository: widget.buddyRepository,
          realtimeService: widget.realtimeService,
          authRepository: widget.authRepository,
          profileRepository: widget.profileRepository,
          pushRepository: widget.pushRepository,
          diveCenterRepository: widget.diveCenterRepository,
          onTransportAlertCleared: () =>
              widget.viewModel.markTransportAlertCleared(trip.id),
          onBuddyAlertCleared: () =>
              widget.viewModel.markBuddyAlertCleared(trip.id),
        ),
      ),
    );
    // Mark read again on the way out — catches any messages that arrived while the
    // diver was actively inside the chat — then refresh so the corrected (accurate)
    // unread count shows immediately rather than waiting for the next tab switch.
    if (!context.mounted) return;
    widget.tripRepository.markRead(trip.id).catchError((_) {});
    widget.viewModel.load();
  }
}
