import 'package:flutter/foundation.dart';

import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/entities/trip.dart';

/// Simpler sibling to MyTripsViewModel — no realtime subscriptions (see ArchiveRevealList's
/// own doc comment on why the archived-vs-live tradeoff was made), just load + unarchive.
class ArchivedTripsViewModel extends ChangeNotifier {
  ArchivedTripsViewModel({required TripRepository repository}) : _repository = repository;

  final TripRepository _repository;

  List<Trip> _trips = [];
  List<Trip> get trips => _trips;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _trips = await _repository.getMyTrips(archived: true);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Optimistic, same rollback-on-failure shape as MyTripsViewModel.archiveTrip.
  Future<void> unarchiveTrip(String tripId) async {
    final index = _trips.indexWhere((t) => t.id == tripId);
    if (index == -1) return;
    final trip = _trips[index];
    _trips = _trips.where((t) => t.id != tripId).toList();
    notifyListeners();

    try {
      await _repository.unarchiveTrip(tripId);
    } catch (e) {
      _trips = [trip, ..._trips];
      notifyListeners();
      rethrow;
    }
  }
}
