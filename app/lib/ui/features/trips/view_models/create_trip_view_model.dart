import 'package:flutter/foundation.dart';

import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/entities/trip.dart';

class CreateTripViewModel extends ChangeNotifier {
  CreateTripViewModel({required TripRepository repository}) : _repository = repository;

  final TripRepository _repository;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _error;
  String? get error => _error;

  Future<Trip?> submit({
    required String title,
    required String location,
    required DateTime startTime,
    DateTime? endDate,
    String? description,
    String? meetingPoint,
    int? diveCountMin,
    int? diveCountMax,
    int? depthMinM,
    int? depthMaxM,
    String? minCertification,
    int? maxParticipants,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      return await _repository.createTrip(
        title: title,
        location: location,
        startTime: startTime,
        endDate: endDate,
        description: description,
        meetingPoint: meetingPoint,
        diveCountMin: diveCountMin,
        diveCountMax: diveCountMax,
        depthMinM: depthMinM,
        depthMaxM: depthMaxM,
        minCertification: minCertification,
        maxParticipants: maxParticipants,
      );
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Best-effort — the trip itself already exists by the time this is called, so a failed
  /// photo upload shouldn't block navigating to it; the organizer can retry from Trip
  /// Page's own hero-image camera button.
  Future<void> uploadPhoto(String tripId, String filePath) async {
    try {
      await _repository.addTripPhoto(tripId, filePath);
    } catch (_) {
      // ignore — see above
    }
  }
}
