import 'package:flutter/foundation.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/dive_center_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/entities/dive_center.dart';
import '../../../../domain/entities/profile.dart';
import '../../../../domain/entities/trip.dart';

class TripViewModel extends ChangeNotifier {
  TripViewModel({
    required TripRepository repository,
    required this.authRepository,
    required this.profileRepository,
    required this.diveCenterRepository,
    required String tripId,
    required this.currentUserId,
  })  : _repository = repository,
        _tripId = tripId;

  final TripRepository _repository;
  final String _tripId;
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final DiveCenterRepository diveCenterRepository;
  final String currentUserId;

  Trip? _trip;
  Trip? get trip => _trip;

  Profile? _organizerProfile;
  Profile? get organizerProfile => _organizerProfile;

  DiveCenter? _organizerDiveCenter;
  DiveCenter? get organizerDiveCenter => _organizerDiveCenter;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _isJoining = false;
  bool get isJoining => _isJoining;

  bool _isLeaving = false;
  bool get isLeaving => _isLeaving;

  bool _isCancelling = false;
  bool get isCancelling => _isCancelling;

  bool _isUploadingPhoto = false;
  bool get isUploadingPhoto => _isUploadingPhoto;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _trip = await _repository.getTrip(_tripId);
      final creatorId = _trip?.creatorUserId;
      final diveCenterId = _trip?.diveCenterId;
      // Best-effort — an organizer profile/dive-center fetch failing shouldn't block
      // viewing the trip. Both are fetched when present (not mutually exclusive) — the UI
      // decides which one to actually display (see TripPage's _OrganizerCard: dive center
      // takes priority when the trip is business-organized).
      if (creatorId != null) {
        try {
          _organizerProfile = await profileRepository.getPublicProfile(creatorId);
        } catch (_) {
          _organizerProfile = null;
        }
      }
      if (diveCenterId != null) {
        try {
          _organizerDiveCenter = await diveCenterRepository.getById(diveCenterId);
        } catch (_) {
          _organizerDiveCenter = null;
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

  /// Returns null on success, or an error message on failure (e.g. a non-organizer
  /// somehow reaching this) — same scoped pattern as [leave]. Reloads the trip on success
  /// so [trip.bookingStatus] flips to "cancelled" and the pill/action area update in place.
  Future<String?> cancel() async {
    _isCancelling = true;
    notifyListeners();

    try {
      await _repository.cancelTrip(_tripId);
      _trip = await _repository.getTrip(_tripId);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isCancelling = false;
      notifyListeners();
    }
  }

  /// Returns null on success, or an error message on failure. Organizer-only server-side
  /// (see trip.ErrOnlyOrganizerCanEditTrip) — the UI only ever surfaces the picker to the
  /// organizer in the first place, so a rejection here would mean something's out of sync.
  Future<String?> uploadPhoto(String filePath) async {
    _isUploadingPhoto = true;
    notifyListeners();

    try {
      await _repository.uploadTripPhoto(_tripId, filePath);
      _trip = await _repository.getTrip(_tripId);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isUploadingPhoto = false;
      notifyListeners();
    }
  }
}
