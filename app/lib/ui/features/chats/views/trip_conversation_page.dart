import 'package:flutter/material.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/chat_repository.dart';
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
class TripConversationPage extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: InkWell(onTap: () => _openTripPage(context), child: Text(tripTitle)),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Chat'),
              Tab(text: 'Transport'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ChatView(viewModel: chatViewModel),
            TransportView(viewModel: transportViewModel),
          ],
        ),
      ),
    );
  }

  void _openTripPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripPage(
          viewModel: TripViewModel(
            repository: tripRepository,
            authRepository: authRepository,
            profileRepository: profileRepository,
            tripId: chatViewModel.tripId,
            currentUserId: chatViewModel.currentUserId,
          ),
          tripRepository: tripRepository,
          chatRepository: chatRepository,
          transportRepository: transportRepository,
          realtimeService: realtimeService,
          openedFromConversation: true,
        ),
      ),
    );
  }
}
