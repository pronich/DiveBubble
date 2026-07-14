import 'package:flutter/foundation.dart';

import '../../../../data/repositories/trip_repository.dart';
import '../../../../data/services/auth_required_exception.dart';
import '../../../../domain/entities/trip.dart';

class MyTripsViewModel extends ChangeNotifier {
  MyTripsViewModel({required TripRepository repository}) : _repository = repository;

  final TripRepository _repository;

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
    } on AuthRequiredException {
      _needsSignIn = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
