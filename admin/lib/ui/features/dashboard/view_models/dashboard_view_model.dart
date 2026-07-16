import 'package:flutter/foundation.dart';

import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/entities/trip.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({required TripRepository repository, required this.diveCenterId}) : _repository = repository;

  final TripRepository _repository;
  final String diveCenterId;

  List<Trip> _trips = [];
  List<Trip> get trips => _trips;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // GET /trips/mine returns every trip this user has access to, personal or business — see
  // TripApiService's own comment. Filtered here to this dive center specifically, since a
  // future multi-center owner/staff member could have trips from more than one.
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final all = await _repository.getMyTrips();
      _trips = all.where((t) => t.diveCenterId == diveCenterId).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
