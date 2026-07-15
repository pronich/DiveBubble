import 'package:flutter/material.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/transport_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../data/services/realtime_service.dart';
import '../../../../domain/entities/trip.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../onboarding/views/login_sheet.dart';
import '../../transport/view_models/transport_view_model.dart';
import '../view_models/chat_view_model.dart';
import '../view_models/my_trips_view_model.dart';
import 'trip_conversation_page.dart';

class MyTripsView extends StatefulWidget {
  const MyTripsView({
    super.key,
    required this.viewModel,
    required this.chatRepository,
    required this.tripRepository,
    required this.transportRepository,
    required this.realtimeService,
    required this.authRepository,
    required this.profileRepository,
    required this.currentUserId,
    required this.onGoToExplore,
  });

  final MyTripsViewModel viewModel;
  final ChatRepository chatRepository;
  final TripRepository tripRepository;
  final TransportRepository transportRepository;
  final RealtimeService realtimeService;
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final String currentUserId;
  final VoidCallback onGoToExplore;

  @override
  State<MyTripsView> createState() => _MyTripsViewState();
}

class _MyTripsViewState extends State<MyTripsView> {
  // Refreshes on app resume too — trips/messages may have changed while backgrounded.
  late final _lifecycleListener = AppLifecycleListener(onResume: widget.viewModel.load);

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
                );
                if (signedIn) widget.viewModel.load();
              },
            );
          }

          final error = widget.viewModel.error;
          if (error != null) {
            return Center(child: Text('Error: $error'));
          }

          final trips = widget.viewModel.trips;
          if (trips.isEmpty) {
            return EmptyStateView(
              icon: Icons.luggage_outlined,
              title: 'No Bubbles yet',
              subtitle: 'Join a trip in Explore and it becomes your Bubble here — chat, transport, and trip details all in one place.',
              ctaLabel: 'Explore trips',
              onCtaPressed: widget.onGoToExplore,
            );
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

  Future<void> _openChat(BuildContext context, Trip trip) async {
    // Fire-and-forget — a failed mark-read shouldn't block opening the chat, it just
    // means the unread badge lingers until the next successful one.
    widget.tripRepository.markRead(trip.id).catchError((_) {});
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripConversationPage(
          chatViewModel: ChatViewModel(
            repository: widget.chatRepository,
            realtimeService: widget.realtimeService,
            profileRepository: widget.profileRepository,
            tripId: trip.id,
            currentUserId: widget.currentUserId,
          ),
          transportViewModel: TransportViewModel(
            repository: widget.transportRepository,
            authRepository: widget.authRepository,
            profileRepository: widget.profileRepository,
            tripId: trip.id,
            currentUserId: widget.currentUserId,
          ),
          tripTitle: trip.title,
          tripRepository: widget.tripRepository,
          chatRepository: widget.chatRepository,
          transportRepository: widget.transportRepository,
          realtimeService: widget.realtimeService,
          authRepository: widget.authRepository,
          profileRepository: widget.profileRepository,
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
              child: (trip.photoUrl?.isNotEmpty ?? false)
                  ? Image.network(trip.photoUrl!, width: 52, height: 52, fit: BoxFit.cover)
                  : Image.asset(AppAssets.tripPlaceholder, width: 52, height: 52, fit: BoxFit.cover),
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
                      if (trip.unreadCount > 0) ...[
                        const SizedBox(width: 6),
                        _UnreadBadge(count: trip.unreadCount),
                      ],
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
                  _StatusPill(isPast: _isPast, isCancelled: trip.bookingStatus == 'cancelled'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(999)),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onError,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isPast, required this.isCancelled});

  final bool isPast;
  final bool isCancelled;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<SemanticColors>()!;
    final theme = Theme.of(context);

    final String label;
    final Color background;
    final Color foreground;
    // Cancelled outranks Active/Past — same priority call as Trip Page's status pill.
    if (isCancelled) {
      label = 'Cancelled';
      background = theme.colorScheme.surfaceContainerHighest;
      foreground = theme.colorScheme.onSurfaceVariant;
    } else if (isPast) {
      label = 'Past';
      background = semantic.neutralContainer;
      foreground = semantic.onNeutralContainer;
    } else {
      label = 'Active';
      background = semantic.infoContainer;
      foreground = semantic.onInfoContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }
}

