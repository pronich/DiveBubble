import 'package:flutter/material.dart';

import '../../../../data/repositories/trip_repository.dart';
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
  });

  final ChatViewModel chatViewModel;
  final TransportViewModel transportViewModel;
  final String tripTitle;
  final TripRepository tripRepository;

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
            tripId: chatViewModel.tripId,
            currentUserId: chatViewModel.currentUserId,
          ),
        ),
      ),
    );
  }
}
