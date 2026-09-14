import 'package:flutter/material.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/buddy_repository.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/dive_center_repository.dart';
import '../../../data/repositories/dive_log_repository.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/repositories/gear_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/push_repository.dart';
import '../../../data/repositories/specialty_repository.dart';
import '../../../data/repositories/transport_repository.dart';
import '../../../data/repositories/trip_repository.dart';
import '../../../data/services/realtime_service.dart';
import '../../features/chats/view_models/my_trips_view_model.dart';
import '../../features/chats/views/my_trips_view.dart';
import '../../features/profile/view_models/profile_view_model.dart';
import '../../features/profile/views/dive_log_list_page.dart';
import '../../features/profile/views/profile_view.dart';

// Bubbles / DiveLog / Profile bottom nav — the app's top-level shell. Explore is deliberately
// not wired in here for the B2C pivot (divers organize their own trips instead of browsing
// dive-center listings) — TripsListView/TripsListViewModel are kept in the codebase, just
// unreachable, in case Explore comes back.
class RootShell extends StatefulWidget {
  const RootShell({
    super.key,
    required this.tripRepository,
    required this.chatRepository,
    required this.transportRepository,
    required this.buddyRepository,
    required this.realtimeService,
    required this.authRepository,
    required this.profileRepository,
    required this.specialtyRepository,
    required this.gearRepository,
    required this.diveCenterRepository,
    required this.expenseRepository,
    required this.diveLogRepository,
    required this.pushRepository,
    required this.currentUserId,
  });

  final TripRepository tripRepository;
  final ChatRepository chatRepository;
  final TransportRepository transportRepository;
  final BuddyRepository buddyRepository;
  final RealtimeService realtimeService;
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final SpecialtyRepository specialtyRepository;
  final GearRepository gearRepository;
  final DiveCenterRepository diveCenterRepository;
  final ExpenseRepository expenseRepository;
  final DiveLogRepository diveLogRepository;
  final PushRepository pushRepository;
  final String currentUserId;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  // Created once — building this inline in build() would hand the tab a
  // fresh, unloaded ViewModel on every rebuild (e.g. every tab switch).
  late final _myTripsViewModel = MyTripsViewModel(
    repository: widget.tripRepository,
    realtimeService: widget.realtimeService,
    currentUserId: widget.currentUserId,
  );

  // Shared between the Profile tab and the DiveLog tab — a dive logged from one shows up in
  // the other's Dive Log deck teaser without a second fetch or state going stale between them.
  late final _profileViewModel = ProfileViewModel(
    repository: widget.profileRepository,
    specialtyRepository: widget.specialtyRepository,
    gearRepository: widget.gearRepository,
    diveLogRepository: widget.diveLogRepository,
  );

  @override
  void initState() {
    super.initState();
    // Proactive — the Bubbles bottom-nav dot needs trips loaded from a cold start, not just
    // after the diver's first tap into the tab.
    _myTripsViewModel.load();
  }

  void _onDestinationSelected(int i) {
    setState(() => _index = i);
    // MyTripsViewModel only loads once via IndexedStack's initState — a trip joined or
    // created elsewhere wouldn't show up here otherwise until app resume.
    if (i == 0) _myTripsViewModel.load();
  }

  @override
  void didUpdateWidget(RootShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // _myTripsViewModel itself is built once (see its own comment) — AppEntryGate can still
    // hand this widget a fresher currentUserId later (see AppEntryGate's auth-change
    // listener), so that update needs to be pushed into the already-built ViewModel by hand.
    if (oldWidget.currentUserId != widget.currentUserId) {
      _myTripsViewModel.currentUserId = widget.currentUserId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          MyTripsView(
            viewModel: _myTripsViewModel,
            chatRepository: widget.chatRepository,
            tripRepository: widget.tripRepository,
            transportRepository: widget.transportRepository,
            buddyRepository: widget.buddyRepository,
            realtimeService: widget.realtimeService,
            authRepository: widget.authRepository,
            profileRepository: widget.profileRepository,
            pushRepository: widget.pushRepository,
            diveCenterRepository: widget.diveCenterRepository,
            expenseRepository: widget.expenseRepository,
            currentUserId: widget.currentUserId,
            isActive: _index == 0,
          ),
          DiveLogListPage(
            viewModel: _profileViewModel,
            tripRepository: widget.tripRepository,
            chatRepository: widget.chatRepository,
          ),
          ProfileView(
            authRepository: widget.authRepository,
            profileRepository: widget.profileRepository,
            viewModel: _profileViewModel,
            tripRepository: widget.tripRepository,
            chatRepository: widget.chatRepository,
            pushRepository: widget.pushRepository,
            isActive: _index == 2,
          ),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _myTripsViewModel,
        builder: (context, _) {
          final showDot = _index != 0 && _myTripsViewModel.hasAnyAttention;
          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _onDestinationSelected,
            destinations: [
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: showDot,
                  child: const Icon(Icons.bubble_chart_outlined),
                ),
                selectedIcon: Badge(isLabelVisible: showDot, child: const Icon(Icons.bubble_chart)),
                label: 'Bubbles',
              ),
              const NavigationDestination(
                icon: Icon(Icons.scuba_diving_outlined),
                selectedIcon: Icon(Icons.scuba_diving),
                label: 'Dive Log',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }
}
