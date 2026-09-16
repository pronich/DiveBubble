import 'package:flutter/foundation.dart';

import '../../../../data/services/error_codes.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../data/repositories/trip_repository.dart';
import '../../../../data/services/location_service.dart';
import '../../../../domain/entities/trip.dart';
import '../../../core/utils/distance.dart';

enum SortMode { soonest, nearest }

class TripsListViewModel extends ChangeNotifier {
  TripsListViewModel({required TripRepository repository, LocationService? locationService})
      : _repository = repository,
        _locationService = locationService ?? LocationService();

  final TripRepository _repository;
  final LocationService _locationService;

  List<Trip> _trips = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String _query = '';
  String get query => _query;

  SortMode _sortMode = SortMode.soonest;
  SortMode get sortMode => _sortMode;

  bool get hasActiveFilters => _query.isNotEmpty || _sortMode != SortMode.soonest;

  Position? _myPosition;
  bool _isResolvingPosition = false;
  bool get isResolvingPosition => _isResolvingPosition;

  /// Nearest-sorted trips with null coordinates sort to the end, since they can't be placed but shouldn't disappear.
  List<Trip> get trips {
    if (_sortMode != SortMode.nearest || _myPosition == null) return _trips;

    final withDistance = <Trip, double?>{
      for (final t in _trips)
        t: (t.latitude != null && t.longitude != null)
            ? haversineKm(_myPosition!.latitude, _myPosition!.longitude, t.latitude!, t.longitude!)
            : null,
    };
    final sorted = _trips.toList()
      ..sort((a, b) {
        final da = withDistance[a];
        final db = withDistance[b];
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
    return sorted;
  }

  Future<void> loadTrips() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _trips = await _repository.getTrips(query: _query);
    } catch (e) {
      _error = friendlyError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Re-fetches from the backend when the query changed (search is server-side), and resolves the diver's position first if switching to "Nearest" (distance sort is client-side).
  Future<void> applyFilters({required String query, required SortMode sortMode}) async {
    final queryChanged = query != _query;
    _query = query;
    _sortMode = sortMode;

    if (sortMode == SortMode.nearest && _myPosition == null) {
      await resolvePosition();
    }

    if (queryChanged) {
      await loadTrips();
    } else {
      notifyListeners();
    }
  }

  void clearFilters() {
    _query = '';
    _sortMode = SortMode.soonest;
    loadTrips();
  }

  /// Best-effort — a denied/failed permission just falls back to date order rather than blocking the sheet or erroring.
  Future<bool> resolvePosition() async {
    _isResolvingPosition = true;
    notifyListeners();
    try {
      _myPosition = await _locationService.currentPosition();
      return _myPosition != null;
    } finally {
      _isResolvingPosition = false;
      notifyListeners();
    }
  }
}
