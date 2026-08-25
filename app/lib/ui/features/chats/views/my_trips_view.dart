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
import '../../../core/theme/semantic_colors.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../onboarding/views/login_sheet.dart';
import '../view_models/my_trips_view_model.dart';
import 'archive_reveal_list.dart';
import 'archived_chats_page.dart';
import 'trip_conversation_page.dart';
import 'trip_row.dart';
import 'trip_row_actions.dart';

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
    required this.isActive,
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
  final bool isActive;

  @override
  State<MyTripsView> createState() => _MyTripsViewState();
}

class _MyTripsViewState extends State<MyTripsView> {
  // Refreshes on app resume too — trips/messages may have changed while backgrounded.
  late final _lifecycleListener = AppLifecycleListener(
    onResume: () {
      widget.viewModel.load();
      setState(() => _archiveRevealed = false);
    },
  );
  String _search = '';

  // Pinned by pulling past the reveal threshold (see ArchiveRevealList) — reset whenever this
  // tab is left and returned to, or the app comes back from background, so the diver has to
  // pull again each time rather than it staying stuck open, per the product ask.
  bool _archiveRevealed = false;

  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
    // Reload once signed in — this tab may have already loaded (and cached "needs sign in")
    // before the user logged in via some other screen's gate (Create trip, Join, etc.).
    widget.authRepository.addListener(_onAuthChanged);
  }

  @override
  void didUpdateWidget(MyTripsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      setState(() => _archiveRevealed = false);
    }
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
      appBar: AppBar(title: Text('Bubbles', style: Theme.of(context).textTheme.headlineSmall)),
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
              subtitle: 'Log in to view the trips you\'ve joined and their group chats.',
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
              : allTrips.where((t) => t.title.toLowerCase().contains(query)).toList();

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
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ArchiveRevealList(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: trips.length,
                        separatorBuilder: (context, _) => const Divider(height: 1, indent: 76),
                        archivedCount: widget.viewModel.archivedCount,
                        archivedUnreadCount: widget.viewModel.archivedUnreadCount,
                        archivedPreviewText: widget.viewModel.archivedPreviewText,
                        revealed: _archiveRevealed,
                        onRevealed: () => setState(() => _archiveRevealed = true),
                        onOpenArchive: () => _openArchive(context),
                        onRefresh: widget.viewModel.load,
                        itemBuilder: (context, index) {
                          final trip = trips[index];
                          return Dismissible(
                            key: ValueKey(trip.id),
                            direction: DismissDirection.endToStart,
                            background: _ArchiveSwipeBackground(theme: Theme.of(context)),
                            onDismissed: (_) => widget.viewModel.archiveTrip(trip.id),
                            child: TripRow(
                              trip: trip,
                              onTap: () => _openChat(context, trip),
                              onLongPress: () => _showActions(context, trip),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showActions(BuildContext context, Trip trip) {
    return showTripRowActionsSheet(
      context,
      trip: trip,
      currentUserId: widget.currentUserId,
      tripRepository: widget.tripRepository,
      isArchived: false,
      onArchiveToggled: () => widget.viewModel.archiveTrip(trip.id),
      onLeftOrCancelled: widget.viewModel.load,
    );
  }

  Future<void> _openArchive(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArchivedChatsPage(
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
        ),
      ),
    );
    // An unarchive on that screen isn't reflected in this list until we reload — cheap
    // either way since returning here means the diver's back on this tab regardless.
    if (context.mounted) widget.viewModel.load();
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
          onTransportAlertCleared: () => widget.viewModel.markTransportAlertCleared(trip.id),
          onBuddyAlertCleared: () => widget.viewModel.markBuddyAlertCleared(trip.id),
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

class _ArchiveSwipeBackground extends StatelessWidget {
  const _ArchiveSwipeBackground({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final semantic = theme.extension<SemanticColors>()!;
    return Container(
      color: semantic.infoContainer,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(Icons.archive_outlined, color: semantic.onInfoContainer),
    );
  }
}
