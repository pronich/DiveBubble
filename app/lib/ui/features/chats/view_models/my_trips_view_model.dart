import 'dart:async';
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

  // Not final — RootShell is built once (see its own `late final` comment) but the real
  // signed-in id can change later (anonymous browsing followed by a login-gated sign-in, or
  // a sign-out/sign-in cycle without an app restart), so RootShell pushes a fresh value in
  // via didUpdateWidget whenever AppEntryGate re-resolves it.
  String currentUserId;

  // One subscription per joined trip, kept alive for as long as this ViewModel is (the
  // whole Bubbles tab's lifetime) — this is what makes the list update live, WhatsApp/
  // Telegram-style, while just sitting on the list instead of only refreshing on reopen.
  final Map<String, centrifuge.Subscription> _subscriptions = {};
  final Map<String, StreamSubscription<centrifuge.PublicationEvent>> _publicationListeners = {};

  List<Trip> _trips = [];
  List<Trip> get trips => _trips;

  // Fetched alongside the main list purely for the Archive reveal cell's preview/badge (see
  // ArchivedTripsRevealList) — archived trips never get a realtime subscription here, so this
  // is a snapshot refreshed on each load()/pull-to-refresh, not a live-updating count. That's
  // a deliberate simplification: subscribing to every archived trip's channel too just to keep
  // one badge live would double the socket footprint for a number the diver only glances at.
  List<Trip> _archivedTrips = [];
  int get archivedCount => _archivedTrips.length;

  // The badge shown on the Archive row itself — count of archived chats with unread
  // messages, not archived chats in general (an archived chat you've already read
  // shouldn't keep contributing to a number that reads as "needs attention").
  int get archivedUnreadCount => _archivedTrips.where((t) => t.unreadCount > 0).length;

  // Matches the two-line preview Telegram's own Archived Chats cell shows — most recent
  // first, same ordering the backend already returns.
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

  // load() has three independent triggers (initState, the authRepository listener, and
  // tapping the Bubbles tab) that can fire close together — without coalescing, two
  // overlapping calls would both pass _subscribeToAll's per-trip "already subscribed?"
  // check before either finishes awaiting, so both would call RealtimeService.subscribe
  // and register a second sub.publication.listen() for the same trip (double-counting
  // unread messages), while dispose() would only ever cancel one of the two. A concurrent
  // caller just awaits the same in-flight load instead of starting its own.
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
      _error = e.toString();
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
    final senderId = json['userId'] as String;
    final trip = _trips[index];
    // Own messages never count as unread for yourself (matches the backend's rule) —
    // this only fires for the optimistic client-side bump between reloads.
    final updated = trip.copyWith(
      unreadCount: senderId == currentUserId ? trip.unreadCount : trip.unreadCount + 1,
    );

    // Move to the front, same "most recent activity" ordering the backend applies.
    _trips = [updated, ..._trips.where((t) => t.id != tripId)];
    notifyListeners();
  }

  // Optimistic — leaves the row visible until the request actually settles (Dismissible/the
  // long-press sheet call this only after the diver already committed to the action), and
  // rolls back into place if the request fails rather than leaving the trip stuck in limbo.
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
