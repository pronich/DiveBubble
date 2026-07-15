import 'package:flutter/foundation.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/entities/profile.dart';
import '../../../../domain/entities/trip.dart';

class TripViewModel extends ChangeNotifier {
  TripViewModel({
    required TripRepository repository,
    required this.authRepository,
    required this.profileRepository,
    required String tripId,
    required this.currentUserId,
  })  : _repository = repository,
        _tripId = tripId;

  final TripRepository _repository;
  final String _tripId;
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final String currentUserId;

  Trip? _trip;
  Trip? get trip => _trip;

  Profile? _organizerProfile;
  Profile? get organizerProfile => _organizerProfile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _isJoining = false;
  bool get isJoining => _isJoining;

  bool _isLeaving = false;
  bool get isLeaving => _isLeaving;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _trip = await _repository.getTrip(_tripId);
      final creatorId = _trip?.creatorUserId;
      // Best-effort — an organizer profile fetch failing shouldn't block viewing the trip.
      if (creatorId != null) {
        try {
          _organizerProfile = await profileRepository.getPublicProfile(creatorId);
        } catch (_) {
          _organizerProfile = null;
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> join() async {
    _isJoining = true;
    notifyListeners();

    try {
      await _repository.joinTrip(_tripId);
      _trip = await _repository.getTrip(_tripId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isJoining = false;
      notifyListeners();
    }
  }

  /// Returns null on success, or an error message on failure (e.g. the organizer trying
  /// to leave their own trip) — scoped to the confirmation dialog rather than the shared
  /// [error] field, since a rejected leave shouldn't blow away the whole page.
  Future<String?> leave() async {
    _isLeaving = true;
    notifyListeners();

    try {
      await _repository.leaveTrip(_tripId);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLeaving = false;
      notifyListeners();
    }
  }
}
