import 'package:flutter/foundation.dart';

import '../../../../data/repositories/message_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/entities/chat_message.dart';
import '../../../../domain/entities/my_profile.dart';
import '../../../../domain/entities/trip.dart';

/// No realtime here yet (see MessageApiService's own comment) — selecting a trip loads its
/// history once; sending reloads it. A diver's own app still gets live delivery via
/// Centrifugo regardless of how the organization's reply got sent.
class BubblesViewModel extends ChangeNotifier {
  BubblesViewModel({
    required TripRepository tripRepository,
    required MessageRepository messageRepository,
    required ProfileRepository profileRepository,
    required this.diveCenterId,
    required this.currentUserId,
  })  : _tripRepository = tripRepository,
        _messageRepository = messageRepository,
        _profileRepository = profileRepository;

  final TripRepository _tripRepository;
  final MessageRepository _messageRepository;
  final ProfileRepository _profileRepository;
  final String diveCenterId;
  final String currentUserId;

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
    _selectedTripId = tripId;
    _isLoadingMessages = true;
    _error = null;
    notifyListeners();
    try {
      _messages = await _messageRepository.getMessages(tripId);
      await _resolveSenderProfiles();
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
