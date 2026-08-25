import 'package:flutter/material.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/buddy_repository.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/dive_center_repository.dart';
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
import '../../features/profile/views/profile_view.dart';
import '../../features/trips/view_models/trips_list_view_model.dart';
import '../../features/trips/views/trips_list_view.dart';

// Explore / Trips / Profile bottom nav — the app's top-level shell.
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
  final PushRepository pushRepository;
  final String currentUserId;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  // Created once — building these inline in build() would hand each tab a
  // fresh, unloaded ViewModel on every rebuild (e.g. every tab switch).
  late final _exploreViewModel = TripsListViewModel(repository: widget.tripRepository);
  late final _myTripsViewModel = MyTripsViewModel(
    repository: widget.tripRepository,
    realtimeService: widget.realtimeService,
    currentUserId: widget.currentUserId,
  );

  @override
  void initState() {
    super.initState();
    // Proactive — the Bubbles bottom-nav dot needs trips loaded from a cold start, not just
    // after the diver's first tap into the tab (see _onDestinationSelected's own load() call).
    _myTripsViewModel.load();
  }

  void _onDestinationSelected(int i) {
    setState(() => _index = i);
    // MyTripsViewModel only loads once via IndexedStack's initState — a trip joined
    // elsewhere (Explore -> Trip Page) wouldn't show up here otherwise until app resume.
    if (i == 1) _myTripsViewModel.load();
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
          TripsListView(
            viewModel: _exploreViewModel,
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
            currentUserId: widget.currentUserId,
          ),
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
            onGoToExplore: () => setState(() => _index = 0),
            isActive: _index == 1,
          ),
          ProfileView(
            authRepository: widget.authRepository,
            profileRepository: widget.profileRepository,
            specialtyRepository: widget.specialtyRepository,
            gearRepository: widget.gearRepository,
            pushRepository: widget.pushRepository,
            isActive: _index == 2,
          ),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _myTripsViewModel,
        builder: (context, _) {
          final showDot = _index != 1 && _myTripsViewModel.hasAnyAttention;
          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _onDestinationSelected,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Explore',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: showDot,
                  child: const Icon(Icons.bubble_chart_outlined),
                ),
                selectedIcon: Badge(isLabelVisible: showDot, child: const Icon(Icons.bubble_chart)),
                label: 'Bubbles',
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
