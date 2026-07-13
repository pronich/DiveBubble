import 'package:flutter/foundation.dart';

import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/entities/trip.dart';

class TripsListViewModel extends ChangeNotifier {
  TripsListViewModel({required TripRepository repository})
      : _repository = repository;

  final TripRepository _repository;

  List<Trip> _trips = [];
  List<Trip> get trips => _trips;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadTrips() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _trips = await _repository.getTrips();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
