import 'package:flutter/foundation.dart';

import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/entities/trip.dart';

class CreateTripViewModel extends ChangeNotifier {
  CreateTripViewModel({required TripRepository repository, this.existingTripId}) : _repository = repository;

  final TripRepository _repository;

  // Non-null means this form is editing an existing trip rather than creating one — same
  // form, same submit() call site, just routed to a different repository call (see below).
  final String? existingTripId;
  bool get isEditing => existingTripId != null;

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
    double? latitude,
    double? longitude,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      if (existingTripId != null) {
        return await _repository.updateTrip(
          id: existingTripId!,
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
          latitude: latitude,
          longitude: longitude,
        );
      }
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
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
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
