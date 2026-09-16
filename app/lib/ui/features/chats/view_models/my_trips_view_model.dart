import 'dart:async';

import '../../../../data/services/error_codes.dart';
import 'dart:convert';

import 'package:centrifuge/centrifuge.dart' as centrifuge;
import 'package:flutter/foundation.dart';

import '../../../../data/repositories/trip_repository.dart';
import '../../../../data/services/auth_required_exception.dart';
import '../../../../data/services/realtime_service.dart';
import '../../../../domain/entities/trip.dart';

class MyTripsViewModel extends ChangeNotifier {
  MyTripsViewModel({
    required TripRepository repository,
    required RealtimeService realtimeService,
    required this.currentUserId,
  }) : _repository = repository,
       _realtimeService = realtimeService;

  final TripRepository _repository;
  final RealtimeService _realtimeService;

  // Not final — the signed-in id can change later (login-gated sign-in, or a sign-out/sign-in cycle without an app restart), pushed in via didUpdateWidget.
  String currentUserId;

  // One subscription per joined trip, kept alive for this ViewModel's lifetime — this is what makes the list update live instead of only on reopen.
  final Map<String, centrifuge.Subscription> _subscriptions = {};
  final Map<String, StreamSubscription<centrifuge.PublicationEvent>> _publicationListeners = {};

  List<Trip> _trips = [];
  List<Trip> get trips => _trips;

  // A snapshot refreshed on each load(), not live — subscribing to every archived trip's channel just for one badge would double the socket footprint for a number the diver only glances at.
  List<Trip> _archivedTrips = [];
  int get archivedCount => _archivedTrips.length;

  // Archived chats with unread messages specifically, not archived chats in general.
  int get archivedUnreadCount => _archivedTrips.where((t) => t.unreadCount > 0).length;

  String get archivedPreviewText => _archivedTrips.take(2).map((t) => t.title).join(', ');

  bool get hasAnyAttention =>
      _trips.any((t) => t.unreadCount > 0 || t.hasTransportAlert || t.hasBuddyAlert);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _needsSignIn = false;
  bool get needsSignIn => _needsSignIn;

  Future<void>? _loadFuture;

  // Coalesced: load() has three independent triggers that can fire close together, and without this, overlapping calls could both pass the per-trip "already subscribed?" check and double-subscribe.
  Future<void> load() {
    final existing = _loadFuture;
    if (existing != null) return existing;
    final future = _loadImpl();
    _loadFuture = future;
    future.whenComplete(() => _loadFuture = null);
    return future;
  }

  Future<void> _loadImpl() async {
    _isLoading = true;
    _error = null;
    _needsSignIn = false;
    notifyListeners();

    try {
      _trips = await _repository.getMyTrips();
      await _subscribeToAll();
      try {
        _archivedTrips = await _repository.getMyTrips(archived: true);
      } catch (_) {
        // Best-effort — the reveal cell just shows stale/empty preview until the next load.
      }
    } on AuthRequiredException {
      _needsSignIn = true;
    } catch (e) {
      _error = friendlyError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _subscribeToAll() async {
    for (final trip in _trips) {
      if (_subscriptions.containsKey(trip.id)) continue;
      final sub = await _realtimeService.subscribe('trip:${trip.id}');
      _publicationListeners[trip.id] = sub.publication.listen(
        (event) => _onMessage(trip.id, event),
      );
      _subscriptions[trip.id] = sub;
    }
  }

  void _onMessage(String tripId, centrifuge.PublicationEvent event) {
    final index = _trips.indexWhere((t) => t.id == tripId);
    if (index == -1) return;

    final json = jsonDecode(utf8.decode(event.data)) as Map<String, dynamic>;
    final eventType = json['event'] as String?;
    // Other event shapes (e.g. reaction_update, which has no 'userId') also land on this shared channel and must be shrugged off rather than crash the cast below.
    if (eventType != null && eventType != 'sub_chat_activity') return;

    final senderId = json['userId'] as String?;
    if (senderId == null) return;
    final trip = _trips[index];
    final isOwn = senderId == currentUserId;
    // A car/buddy chat message sums into the same unreadCount as a main-chat message, plus its own dot.
    final scope = eventType == 'sub_chat_activity' ? json['scope'] as String? : null;

    // Own activity never counts as unread for yourself, matching the backend's rule.
    final updated = trip.copyWith(
      unreadCount: isOwn ? trip.unreadCount : trip.unreadCount + 1,
      hasUnreadTransportMessages: !isOwn && scope == 'transport' ? true : trip.hasUnreadTransportMessages,
      hasUnreadBuddyMessages: !isOwn && scope == 'buddy' ? true : trip.hasUnreadBuddyMessages,
    );

    // Move to the front, same "most recent activity" ordering the backend applies.
    _trips = [updated, ..._trips.where((t) => t.id != tripId)];
    notifyListeners();
  }

  // Optimistic — rolls back into place if the request fails rather than leaving the trip stuck in limbo.
  Future<void> archiveTrip(String tripId) async {
    final index = _trips.indexWhere((t) => t.id == tripId);
    if (index == -1) return;
    final trip = _trips[index];
    _trips = _trips.where((t) => t.id != tripId).toList();
    _archivedTrips = [trip, ..._archivedTrips];
    notifyListeners();

    final listener = _publicationListeners.remove(tripId);
    final sub = _subscriptions.remove(tripId);
    if (listener != null) await listener.cancel();
    if (sub != null) _realtimeService.unsubscribe(sub);

    try {
      await _repository.archiveTrip(tripId);
    } catch (e) {
      _trips = [trip, ..._trips];
      _archivedTrips = _archivedTrips.where((t) => t.id != tripId).toList();
      await _subscribeToAll();
      notifyListeners();
      rethrow;
    }
  }

  void markTransportAlertCleared(String tripId) {
    final index = _trips.indexWhere((t) => t.id == tripId);
    if (index == -1) return;
    _trips[index] = _trips[index].copyWith(hasTransportAlert: false);
    notifyListeners();
  }

  void markBuddyAlertCleared(String tripId) {
    final index = _trips.indexWhere((t) => t.id == tripId);
    if (index == -1) return;
    _trips[index] = _trips[index].copyWith(hasBuddyAlert: false);
    notifyListeners();
  }

  @override
  void dispose() {
    for (final listener in _publicationListeners.values) {
      listener.cancel();
    }
    for (final sub in _subscriptions.values) {
      _realtimeService.unsubscribe(sub);
    }
    super.dispose();
  }
}
