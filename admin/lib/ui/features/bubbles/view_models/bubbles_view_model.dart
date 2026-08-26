import 'dart:async';
import 'dart:convert';

import 'package:centrifuge/centrifuge.dart' as centrifuge;
import 'package:flutter/foundation.dart';

import '../../../../data/repositories/message_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../data/services/realtime_service.dart';
import '../../../../domain/entities/chat_attachment.dart';
import '../../../../domain/entities/chat_message.dart';
import '../../../../domain/entities/chat_reaction.dart';
import '../../../../domain/entities/my_profile.dart';
import '../../../../domain/entities/trip.dart';

/// The selected conversation's own message history stays scoped to one live subscription at
/// a time (re-subscribed on every selectTrip call, see _subscribeToRealtime) — but every
/// trip in the inbox also gets a lightweight subscription (see _subscribeToAllTrips) purely
/// to keep unreadCount/hasUnreadMention live for the sidebar dot, mirroring app/'s
/// MyTripsViewModel, which needs the same thing for its own bottom-nav dot.
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

  // One subscription per trip in the inbox, kept alive for this ViewModel's whole lifetime
  // (see class doc) — this is what makes the sidebar mention dot react without the staff
  // member having to click into Bubbles first.
  final Map<String, centrifuge.Subscription> _tripSubscriptions = {};
  final Map<String, StreamSubscription<centrifuge.PublicationEvent>> _tripPublicationListeners = {};

  List<Trip> _trips = [];
  List<Trip> get trips => _trips;

  // Backs the Bubbles-sidebar mention dot in AdminShell (see BubblesPage's
  // onMentionStateChanged callback) — recomputed on every notifyListeners, same as
  // app/'s MyTripsViewModel.hasAnyAttention driving RootShell's bottom-nav Badge.
  bool get hasUnreadMention => _trips.any((t) => t.hasUnreadMention);

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
      await _subscribeToAllTrips();
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
      await _subscribeToAllTrips();
      notifyListeners();
    } catch (_) {
      // Not worth surfacing — the inbox badge just stays stale until the next successful call.
    }
  }

  // Idempotent — a trip already in _tripSubscriptions is skipped, so calling this again
  // after every reload only picks up trips new to the list (e.g. one just created).
  Future<void> _subscribeToAllTrips() async {
    for (final trip in _trips) {
      if (_tripSubscriptions.containsKey(trip.id)) continue;
      final sub = await _realtimeService.subscribe('trip:${trip.id}');
      _tripPublicationListeners[trip.id] = sub.publication.listen((event) => _onAnyTripMessage(trip.id, event));
      _tripSubscriptions[trip.id] = sub;
    }
  }

  void _onAnyTripMessage(String tripId, centrifuge.PublicationEvent event) {
    // The selected trip's own transcript is already handled live by _subscribeToRealtime —
    // and a staff member looking straight at it shouldn't have it flagged as unread/mentioned.
    if (tripId == _selectedTripId) return;
    final index = _trips.indexWhere((t) => t.id == tripId);
    if (index == -1) return;

    final json = jsonDecode(utf8.decode(event.data)) as Map<String, dynamic>;
    if (json['userId'] as String == currentUserId) return;
    final mentionsDiveCenter = json['mentionsDiveCenter'] as bool? ?? false;

    final trip = _trips[index];
    _trips[index] = trip.copyWith(
      unreadCount: trip.unreadCount + 1,
      hasUnreadMention: trip.hasUnreadMention || mentionsDiveCenter,
    );
    notifyListeners();
  }

  Future<void> _subscribeToRealtime(String tripId) async {
    _subscription = await _realtimeService.subscribe('trip:$tripId');
    _publicationListener = _subscription!.publication.listen((event) async {
      final json = jsonDecode(utf8.decode(event.data)) as Map<String, dynamic>;
      // Reaction changes get their own small sentinel (see publishReactionUpdate) instead of a
      // full message republish — a Centrifugo publish is one shared payload for every
      // subscriber, and ReactedByMe is per-viewer, so it can never be correct in a broadcast.
      // Only per-emoji Count travels over the wire; _applyReactionUpdate merges that in while
      // leaving each emoji's locally-known ReactedByMe untouched (it only ever changes via this
      // viewer's own reactToMessage call, never via someone else's reaction).
      if (json['event'] == 'reaction_update') {
        _applyReactionUpdate(json);
        return;
      }
      final message = ChatMessage(
        id: json['id'] as String,
        tripId: json['tripId'] as String,
        userId: json['userId'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isDiveCenterStaff: json['isDiveCenterStaff'] as bool? ?? false,
        mentionsDiveCenter: json['mentionsDiveCenter'] as bool? ?? false,
        // Hand-decoded like every other field above, not via ChatMessage.fromJson (same
        // precedent as app/'s own realtime handler) — easy to forget when adding a new
        // message field, so don't skip these on the next one.
        attachments: ((json['attachments'] as List<dynamic>?) ?? [])
            .map((e) => ChatAttachment.fromJson(e as Map<String, dynamic>))
            .toList(),
        replyToId: json['replyToId'] as String?,
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

  // Mobile layout only (see BubblesPage) — returns to the inbox list. Only tears down the
  // selected-conversation subscription, not _subscribeToAllTrips's per-trip ones, which
  // need to stay alive regardless of what's selected for the sidebar mention dot.
  Future<void> clearSelection() async {
    await _unsubscribeCurrent();
    _selectedTripId = null;
    _messages = [];
    notifyListeners();
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
    for (final listener in _tripPublicationListeners.values) {
      listener.cancel();
    }
    for (final sub in _tripSubscriptions.values) {
      _realtimeService.unsubscribe(sub);
    }
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

  Future<String?> send(String body, {List<ChatAttachment> attachments = const [], String? replyToId}) async {
    final tripId = _selectedTripId;
    if (tripId == null || (body.trim().isEmpty && attachments.isEmpty)) return null;
    _isSending = true;
    notifyListeners();
    try {
      await _messageRepository.sendMessage(tripId, body.trim(), attachments: attachments, replyToId: replyToId);
      _messages = await _messageRepository.getMessages(tripId);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<ChatAttachment> uploadAttachment(List<int> bytes, String filename) async {
    final tripId = _selectedTripId;
    if (tripId == null) throw Exception('no trip selected');
    return _messageRepository.uploadAttachment(tripId, bytes, filename);
  }

  void _applyReactionUpdate(Map<String, dynamic> json) {
    final messageId = json['messageId'] as String;
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    final message = _messages[index];
    final counts = (json['counts'] as Map<String, dynamic>? ?? {});
    final updated = {
      for (final entry in counts.entries)
        entry.key: ChatReaction(count: entry.value as int, reactedByMe: message.reactions[entry.key]?.reactedByMe ?? false),
    };
    _messages = [for (final m in _messages) if (m.id == messageId) m.copyWith(reactions: updated) else m];
    notifyListeners();
  }

  // Toggles the caller's own reaction — tapping the same emoji already reacted with removes it
  // (Messenger semantics), tapping a different one replaces it.
  Future<String?> reactToMessage(String messageId, String emoji) async {
    final tripId = _selectedTripId;
    if (tripId == null) return null;
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return null;
    final removing = _messages[index].reactions[emoji]?.reactedByMe ?? false;
    try {
      final reactions = removing
          ? await _messageRepository.removeReaction(tripId, messageId)
          : await _messageRepository.setReaction(tripId, messageId, emoji);
      _messages = [for (final m in _messages) if (m.id == messageId) m.copyWith(reactions: reactions) else m];
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}
