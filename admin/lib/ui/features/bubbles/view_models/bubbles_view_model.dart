import 'dart:async';
import 'dart:convert';

import 'package:centrifuge/centrifuge.dart' as centrifuge;
import 'package:flutter/foundation.dart';

import '../../../../data/repositories/message_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../data/services/realtime_service.dart';
import '../../../../domain/entities/chat_message.dart';
import '../../../../domain/entities/my_profile.dart';
import '../../../../domain/entities/trip.dart';

/// Only the currently-open conversation gets a live subscription — unlike app/'s
/// MyTripsViewModel, which subscribes to every joined trip up front for inbox-wide unread
/// badges, this stays scoped to one channel at a time (re-subscribed on every selectTrip
/// call) since BubblesViewModel itself is long-lived and reused across trip switches,
/// not disposed-and-recreated per trip the way app/'s ChatViewModel is.
class BubblesViewModel extends ChangeNotifier {
  BubblesViewModel({
    required TripRepository tripRepository,
    required MessageRepository messageRepository,
    required ProfileRepository profileRepository,
    required RealtimeService realtimeService,
    required this.diveCenterId,
    required this.diveCenterName,
    required this.currentUserId,
  })  : _tripRepository = tripRepository,
        _messageRepository = messageRepository,
        _profileRepository = profileRepository,
        _realtimeService = realtimeService;

  final TripRepository _tripRepository;
  final MessageRepository _messageRepository;
  final ProfileRepository _profileRepository;
  final RealtimeService _realtimeService;
  final String diveCenterId;
  final String diveCenterName;
  final String currentUserId;

  centrifuge.Subscription? _subscription;
  StreamSubscription<centrifuge.PublicationEvent>? _publicationListener;

  List<Trip> _trips = [];
  List<Trip> get trips => _trips;

  bool _isLoadingTrips = false;
  bool get isLoadingTrips => _isLoadingTrips;

  String? _selectedTripId;
  String? get selectedTripId => _selectedTripId;

  Trip? get selectedTrip {
    final id = _selectedTripId;
    if (id == null) return null;
    for (final t in _trips) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  bool _isLoadingMessages = false;
  bool get isLoadingMessages => _isLoadingMessages;

  bool _isSending = false;
  bool get isSending => _isSending;

  String? _error;
  String? get error => _error;

  final Map<String, MyProfile> _senderProfiles = {};
  Map<String, MyProfile> get senderProfiles => _senderProfiles;

  // GET /trips/mine is already ordered by most recent chat activity server-side — filtering
  // to this dive center preserves that order, no client-side re-sort needed.
  Future<void> loadTrips() async {
    _isLoadingTrips = true;
    _error = null;
    notifyListeners();
    try {
      final all = await _tripRepository.getMyTrips();
      _trips = all.where((t) => t.diveCenterId == diveCenterId).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingTrips = false;
      notifyListeners();
    }
  }

  Future<void> selectTrip(String tripId) async {
    await _unsubscribeCurrent();

    _selectedTripId = tripId;
    _isLoadingMessages = true;
    _error = null;
    notifyListeners();
    try {
      _messages = await _messageRepository.getMessages(tripId);
      await _resolveSenderProfiles();
      await _subscribeToRealtime(tripId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
    // Best-effort, and after the load above — a staff member has no trip_participants row,
    // so last_read_at (and therefore unreadCount in the inbox) only ever moves via this call.
    try {
      await _tripRepository.markRead(tripId);
      // Quiet refresh — no isLoadingTrips flip, so the inbox list doesn't flash a spinner
      // every time a conversation is opened.
      final all = await _tripRepository.getMyTrips();
      _trips = all.where((t) => t.diveCenterId == diveCenterId).toList();
      notifyListeners();
    } catch (_) {
      // Not worth surfacing — the inbox badge just stays stale until the next successful call.
    }
  }

  Future<void> _subscribeToRealtime(String tripId) async {
    _subscription = await _realtimeService.subscribe('trip:$tripId');
    _publicationListener = _subscription!.publication.listen((event) async {
      final json = jsonDecode(utf8.decode(event.data)) as Map<String, dynamic>;
      final message = ChatMessage(
        id: json['id'] as String,
        tripId: json['tripId'] as String,
        userId: json['userId'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isDiveCenterStaff: json['isDiveCenterStaff'] as bool? ?? false,
      );
      // Only this trip's own messages matter here — the shared channel this listener is
      // attached to is scoped to exactly one trip at a time already, but a stale listener
      // from a just-superseded selectTrip() call (its unsubscribe still in flight) could
      // otherwise briefly append into the wrong conversation.
      if (message.tripId != _selectedTripId) {
        return;
      }
      if (_messages.any((m) => m.id == message.id)) {
        return;
      }
      // A sender who wasn't in the initially-loaded history (e.g. their very first message
      // in this Bubble) never went through selectTrip's _resolveSenderProfiles — resolve it
      // now so the row doesn't fall back to the generic "Diver"/person-icon placeholder.
      if (!_senderProfiles.containsKey(message.userId)) {
        try {
          _senderProfiles[message.userId] = await _profileRepository.getById(message.userId);
        } catch (_) {
          // Best-effort — a failed lookup just falls back to "Diver" in the UI.
        }
      }
      _messages = [..._messages, message];
      notifyListeners();
    });
  }

  Future<void> _unsubscribeCurrent() async {
    _publicationListener?.cancel();
    _publicationListener = null;
    final sub = _subscription;
    _subscription = null;
    if (sub != null) {
      await _realtimeService.unsubscribe(sub);
    }
  }

  @override
  void dispose() {
    _unsubscribeCurrent();
    super.dispose();
  }

  Future<void> _resolveSenderProfiles() async {
    final missing = _messages.map((m) => m.userId).toSet()..removeWhere(_senderProfiles.containsKey);
    for (final userId in missing) {
      try {
        _senderProfiles[userId] = await _profileRepository.getById(userId);
      } catch (_) {
        // Best-effort — a failed lookup just falls back to "Diver" in the UI.
      }
    }
  }

  Future<String?> send(String body) async {
    final tripId = _selectedTripId;
    if (tripId == null || body.trim().isEmpty) return null;
    _isSending = true;
    notifyListeners();
    try {
      await _messageRepository.sendMessage(tripId, body.trim());
      _messages = await _messageRepository.getMessages(tripId);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }
}
