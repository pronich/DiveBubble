import 'package:flutter/material.dart';

import '../../../data/repositories/chat_repository.dart';
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
    required this.realtimeService,
    required this.currentUserId,
  });

  final TripRepository tripRepository;
  final ChatRepository chatRepository;
  final RealtimeService realtimeService;
  final String currentUserId;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  // Created once — building these inline in build() would hand each tab a
  // fresh, unloaded ViewModel on every rebuild (e.g. every tab switch).
  late final _exploreViewModel = TripsListViewModel(repository: widget.tripRepository);
  late final _myTripsViewModel = MyTripsViewModel(repository: widget.tripRepository);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          TripsListView(
            viewModel: _exploreViewModel,
            tripRepository: widget.tripRepository,
            currentUserId: widget.currentUserId,
          ),
          MyTripsView(
            viewModel: _myTripsViewModel,
            chatRepository: widget.chatRepository,
            tripRepository: widget.tripRepository,
            realtimeService: widget.realtimeService,
            currentUserId: widget.currentUserId,
            onGoToExplore: () => setState(() => _index = 0),
          ),
          const ProfileView(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Trips'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
