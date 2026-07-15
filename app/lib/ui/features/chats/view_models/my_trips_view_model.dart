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
  })  : _repository = repository,
        _realtimeService = realtimeService;

  final TripRepository _repository;
  final RealtimeService _realtimeService;
  final String currentUserId;

  // One subscription per joined trip, kept alive for as long as this ViewModel is (the
  // whole Bubbles tab's lifetime) — this is what makes the list update live, WhatsApp/
  // Telegram-style, while just sitting on the list instead of only refreshing on reopen.
  final Map<String, centrifuge.Subscription> _subscriptions = {};
  final Map<String, StreamSubscription<centrifuge.PublicationEvent>> _publicationListeners = {};

  List<Trip> _trips = [];
  List<Trip> get trips => _trips;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _needsSignIn = false;
  bool get needsSignIn => _needsSignIn;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    _needsSignIn = false;
    notifyListeners();

    try {
      _trips = await _repository.getMyTrips();
      await _subscribeToAll();
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
      _publicationListeners[trip.id] = sub.publication.listen((event) => _onMessage(trip.id, event));
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
    final updated = trip.copyWith(unreadCount: senderId == currentUserId ? trip.unreadCount : trip.unreadCount + 1);

    // Move to the front, same "most recent activity" ordering the backend applies.
    _trips = [updated, ..._trips.where((t) => t.id != tripId)];
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
