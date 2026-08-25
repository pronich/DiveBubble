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
import '../../../../domain/entities/picked_attachment.dart';
import '../../../../domain/entities/trip.dart';
import '../../../core/widgets/empty_state_view.dart';
import 'trip_conversation_page.dart';
import 'trip_row.dart';

/// Reached from Share-to-DiveBubble (see main.dart's _handleSharedMedia) — a Telegram-style
/// "Share with" search-and-pick screen over the diver's joined Bubbles. Reuses TripRow (same
/// list row as My Trips) with showBadges: false — this isn't the inbox, so unread counts/
/// alert dots/the status pill don't apply, but everything else (thumbnail, title, location)
/// is the same trip row the rest of the app already uses. The tap target opens straight into
/// compose state rather than a plain chat view (see ChatView.initialAttachments).
class ChooseBubblePage extends StatefulWidget {
  const ChooseBubblePage({
    super.key,
    required this.attachments,
    required this.tripRepository,
    required this.chatRepository,
    required this.transportRepository,
    required this.buddyRepository,
    required this.realtimeService,
    required this.authRepository,
    required this.profileRepository,
    required this.pushRepository,
    required this.diveCenterRepository,
    required this.currentUserId,
  });

  final List<PickedAttachment> attachments;
  final TripRepository tripRepository;
  final ChatRepository chatRepository;
  final TransportRepository transportRepository;
  final BuddyRepository buddyRepository;
  final RealtimeService realtimeService;
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final PushRepository pushRepository;
  final DiveCenterRepository diveCenterRepository;
  final String currentUserId;

  @override
  State<ChooseBubblePage> createState() => _ChooseBubblePageState();
}

class _ChooseBubblePageState extends State<ChooseBubblePage> {
  String _search = '';
  bool _isLoading = true;
  String? _error;
  List<Trip> _trips = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final trips = await widget.tripRepository.getMyTrips();
      if (!mounted) return;
      setState(() {
        _trips = trips;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Share to a Bubble')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : _trips.isEmpty
          ? const EmptyStateView(
              icon: Icons.luggage_outlined,
              title: 'No Bubbles yet',
              subtitle: 'Join a trip to get a Bubble you can share into.',
            )
          : Builder(
              builder: (context) {
                final query = _search.trim().toLowerCase();
                final trips = query.isEmpty
                    ? _trips
                    : _trips
                          .where((t) => t.title.toLowerCase().contains(query))
                          .toList();
                return Column(
                  children: [
                    if (_trips.length > 5)
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
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: trips.length,
                              separatorBuilder: (context, _) =>
                                  const Divider(height: 1, indent: 76),
                              itemBuilder: (context, index) => TripRow(
                                trip: trips[index],
                                onTap: () => _openChat(context, trips[index]),
                                showBadges: false,
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
          initialAttachments: widget.attachments,
        ),
      ),
    );
  }
}
