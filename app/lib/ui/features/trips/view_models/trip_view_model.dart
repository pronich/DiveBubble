import 'package:flutter/foundation.dart';

import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/entities/trip.dart';

class TripViewModel extends ChangeNotifier {
  TripViewModel({required TripRepository repository, required String tripId})
      : _repository = repository,
        _tripId = tripId;

  final TripRepository _repository;
  final String _tripId;

  Trip? _trip;
  Trip? get trip => _trip;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _trip = await _repository.getTrip(_tripId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
