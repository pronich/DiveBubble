import 'package:flutter/material.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/repositories/dive_center_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/transport_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../data/services/realtime_service.dart';
import '../../transport/view_models/transport_view_model.dart';
import '../../transport/views/transport_view.dart';
import '../../trips/view_models/trip_view_model.dart';
import '../../trips/views/trip_page.dart';
import '../view_models/chat_view_model.dart';
import 'chat_view.dart';

/// Shell for a joined trip: Chat and Transport are the two things worth reaching
/// immediately, so they're tabs here rather than buried inside Trip Page (which
/// stays reachable by tapping the title, for the fuller trip overview).
class TripConversationPage extends StatefulWidget {
  const TripConversationPage({
    super.key,
    required this.chatViewModel,
    required this.transportViewModel,
    required this.tripTitle,
    required this.tripRepository,
    required this.chatRepository,
    required this.transportRepository,
    required this.realtimeService,
    required this.authRepository,
    required this.profileRepository,
    required this.diveCenterRepository,
    required this.initialHasTransportAlert,
    this.onTransportAlertCleared,
  });

  final ChatViewModel chatViewModel;
  final TransportViewModel transportViewModel;
  final String tripTitle;
  final TripRepository tripRepository;
  final ChatRepository chatRepository;
  final TransportRepository transportRepository;
  final RealtimeService realtimeService;
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final DiveCenterRepository diveCenterRepository;
  // Seeds TransportViewModel.hasAlert from the already-loaded Trip — the Bubble is only
  // ever reached by tapping a row from that loaded list, so this is always available and
  // skips a redundant GET /trips/{id}/transport/alert on every chat open.
  final bool initialHasTransportAlert;
  // Fired once the Transport tab is actually visited and the alert clears server-side —
  // lets MyTripsViewModel flip the same flag locally so the bottom-nav dot and Bubbles
  // row indicator update immediately, without MyTripsView refetching the whole list.
  final VoidCallback? onTransportAlertCleared;

  @override
  State<TripConversationPage> createState() => _TripConversationPageState();
}

class _TripConversationPageState extends State<TripConversationPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isCancelled = false;
  String? _businessName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Seeded from the Trip already in hand (see the field's own comment) — the dot itself
    // lives in the AppBar, always visible regardless of which tab is active, so this is
    // what actually surfaces it before the diver ever switches to Transport.
    widget.transportViewModel.seedAlert(widget.initialHasTransportAlert);
    _refreshTripDerivedState();
  }

  // Owned here, not by ChatViewModel/TransportViewModel — both tabs (plus the message
  // attribution below) just need plain read-only values derived from the trip, and a
  // single fetch avoids duplicating this (and its own realtime-subscription-shaped
  // footguns, see RealtimeService) into multiple ViewModels.
  Future<void> _refreshTripDerivedState() async {
    try {
      final trip = await widget.tripRepository.getTrip(widget.chatViewModel.tripId);
      final diveCenterId = trip.diveCenterId;
      String? businessName;
      if (diveCenterId != null) {
        try {
          businessName = (await widget.diveCenterRepository.getById(diveCenterId)).name;
        } catch (_) {
          // Best-effort — chat messages just fall back to the sender's plain name.
        }
      }
      if (mounted) {
        setState(() {
          _isCancelled = trip.bookingStatus == 'cancelled';
          _businessName = businessName;
        });
      }
    } catch (_) {
      // Best-effort — worst case the input stays enabled until the next successful check,
      // and the server-side guards (EnsureNotCancelled) still reject the action either way.
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 1) {
      widget.transportViewModel.checkAlert().then((_) => widget.onTransportAlertCleared?.call());
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(onTap: () => _openTripPage(context), child: Text(widget.tripTitle)),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Chat'),
            ListenableBuilder(
              listenable: widget.transportViewModel,
              builder: (context, _) => Tab(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Text('Transport'),
                    if (widget.transportViewModel.hasAlert)
                      Positioned(
                        right: -8,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ChatView(viewModel: widget.chatViewModel, isCancelled: _isCancelled, businessName: _businessName),
          TransportView(viewModel: widget.transportViewModel, isCancelled: _isCancelled, businessName: _businessName),
        ],
      ),
    );
  }

  Future<void> _openTripPage(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripPage(
          viewModel: TripViewModel(
            repository: widget.tripRepository,
            authRepository: widget.authRepository,
            profileRepository: widget.profileRepository,
            diveCenterRepository: widget.diveCenterRepository,
            tripId: widget.chatViewModel.tripId,
            currentUserId: widget.chatViewModel.currentUserId,
          ),
          tripRepository: widget.tripRepository,
          chatRepository: widget.chatRepository,
          transportRepository: widget.transportRepository,
          realtimeService: widget.realtimeService,
          diveCenterRepository: widget.diveCenterRepository,
          openedFromConversation: true,
        ),
      ),
    );
    // Trip Page is the only place bookingStatus can change (Cancel Trip) — refresh once
    // back, since ChatView/TransportView otherwise have no reason to know it changed.
    if (mounted) _refreshTripDerivedState();
  }
}
