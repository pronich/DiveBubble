import 'package:flutter/material.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/buddy_repository.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/repositories/dive_center_repository.dart';
import '../../../../data/repositories/expense_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/push_repository.dart';
import '../../../../data/repositories/transport_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../data/services/realtime_service.dart';
import '../../../../domain/entities/trip.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../view_models/archived_trips_view_model.dart';
import 'trip_conversation_page.dart';
import 'trip_row.dart';
import 'trip_row_actions.dart';

/// Reached only via ArchiveRevealList's pull-down gesture (see its own doc comment) — there's
/// deliberately no other entry point, matching the "stays hidden" product ask.
class ArchivedChatsPage extends StatefulWidget {
  const ArchivedChatsPage({
    super.key,
    required this.currentUserId,
    required this.tripRepository,
    required this.chatRepository,
    required this.transportRepository,
    required this.buddyRepository,
    required this.realtimeService,
    required this.authRepository,
    required this.profileRepository,
    required this.pushRepository,
    required this.diveCenterRepository,
    required this.expenseRepository,
  });

  final String currentUserId;
  final TripRepository tripRepository;
  final ChatRepository chatRepository;
  final TransportRepository transportRepository;
  final BuddyRepository buddyRepository;
  final RealtimeService realtimeService;
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final PushRepository pushRepository;
  final DiveCenterRepository diveCenterRepository;
  final ExpenseRepository expenseRepository;

  @override
  State<ArchivedChatsPage> createState() => _ArchivedChatsPageState();
}

class _ArchivedChatsPageState extends State<ArchivedChatsPage> {
  late final _viewModel = ArchivedTripsViewModel(repository: widget.tripRepository);

  @override
  void initState() {
    super.initState();
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archived Chats')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final error = _viewModel.error;
          if (error != null) {
            return Center(child: Text('Error: $error'));
          }
          final trips = _viewModel.trips;
          if (trips.isEmpty) {
            return const EmptyStateView(
              icon: Icons.archive_outlined,
              title: 'No archived chats',
              subtitle: 'Bubbles you archive show up here — swipe or unarchive to bring one back.',
            );
          }

          return RefreshIndicator(
            onRefresh: _viewModel.load,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: trips.length,
              separatorBuilder: (context, _) => const Divider(height: 1, indent: 76),
              itemBuilder: (context, index) {
                final trip = trips[index];
                return Dismissible(
                  key: ValueKey(trip.id),
                  direction: DismissDirection.endToStart,
                  background: _UnarchiveSwipeBackground(theme: Theme.of(context)),
                  onDismissed: (_) => _viewModel.unarchiveTrip(trip.id),
                  child: TripRow(
                    trip: trip,
                    onTap: () => _openChat(context, trip),
                    onLongPress: () => _showActions(context, trip),
                  ),
                );
              },
            ),
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
      isArchived: true,
      onArchiveToggled: () => _viewModel.unarchiveTrip(trip.id),
      onLeftOrCancelled: _viewModel.load,
    );
  }

  Future<void> _openChat(BuildContext context, Trip trip) async {
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
          expenseRepository: widget.expenseRepository,
        ),
      ),
    );
    if (!context.mounted) return;
    widget.tripRepository.markRead(trip.id).catchError((_) {});
    _viewModel.load();
  }
}

class _UnarchiveSwipeBackground extends StatelessWidget {
  const _UnarchiveSwipeBackground({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final semantic = theme.extension<SemanticColors>()!;
    return Container(
      color: semantic.infoContainer,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(Icons.unarchive_outlined, color: semantic.onInfoContainer),
    );
  }
}
