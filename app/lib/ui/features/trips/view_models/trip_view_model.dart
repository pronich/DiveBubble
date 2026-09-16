import 'package:flutter/foundation.dart';

import '../../../../data/services/error_codes.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/dive_center_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/push_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/entities/dive_center.dart';
import '../../../../domain/entities/profile.dart';
import '../../../../domain/entities/trip.dart';
import '../../../../domain/entities/trip_photo.dart';

class TripViewModel extends ChangeNotifier {
  TripViewModel({
    required TripRepository repository,
    required this.authRepository,
    required this.profileRepository,
    required this.pushRepository,
    required this.diveCenterRepository,
    required String tripId,
    required this.currentUserId,
  })  : _repository = repository,
        _tripId = tripId;

  final TripRepository _repository;
  final String _tripId;
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final PushRepository pushRepository;
  final DiveCenterRepository diveCenterRepository;
  final String currentUserId;

  Trip? _trip;
  Trip? get trip => _trip;

  List<TripPhoto> _photos = [];
  List<TripPhoto> get photos => _photos;

  Profile? _organizerProfile;
  Profile? get organizerProfile => _organizerProfile;

  DiveCenter? _organizerDiveCenter;
  DiveCenter? get organizerDiveCenter => _organizerDiveCenter;

  bool _isDiveCenterStaff = false;

  /// True for the trip's literal creator *or* any member of the dive center running it, matching the backend's trip.Service.isOrganizer exactly.
  bool get isOrganizer => (_trip?.creatorUserId == currentUserId) || _isDiveCenterStaff;

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

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _trip = await _repository.getTrip(_tripId);
      try {
        _photos = await _repository.getTripPhotos(_tripId);
      } catch (_) {
        // Best-effort — a failed gallery fetch shouldn't block viewing the trip itself.
        _photos = [];
      }
      final creatorId = _trip?.creatorUserId;
      final diveCenterId = _trip?.diveCenterId;
      // Best-effort — both are fetched when present (not mutually exclusive); TripPage's _OrganizerCard decides which one to display.
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
        try {
          _isDiveCenterStaff = await diveCenterRepository.isMember(diveCenterId);
        } catch (_) {
          _isDiveCenterStaff = false;
        }
      } else {
        _isDiveCenterStaff = false;
      }
      try {
        _isMuted = await _repository.getMuted(_tripId);
      } catch (_) {
        // Best-effort — worst case the mute pill shows "unmuted" until the next successful load.
        _isMuted = false;
      }
    } catch (e) {
      _error = friendlyError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Optimistic, no dedicated loading flag — a mute toggle isn't worth a spinner; rolls back on failure.
  Future<void> toggleMute() async {
    final next = !_isMuted;
    _isMuted = next;
    notifyListeners();
    try {
      if (next) {
        await _repository.muteTrip(_tripId);
      } else {
        await _repository.unmuteTrip(_tripId);
      }
    } catch (_) {
      _isMuted = !next;
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
      _error = friendlyError(e);
    } finally {
      _isJoining = false;
      notifyListeners();
    }
  }

  /// Used when this page was reached via an invite link: the code already resolved this exact trip, so Join goes straight through JoinByCode regardless of trip type.
  Future<void> joinByCode(String code) async {
    _isJoining = true;
    notifyListeners();

    try {
      _trip = await _repository.joinTripByCode(code);
    } catch (e) {
      _error = friendlyError(e);
    } finally {
      _isJoining = false;
      notifyListeners();
    }
  }

  /// Returns an error message scoped to the confirmation dialog rather than the shared [error] field, so a rejected leave doesn't blow away the whole page.
  Future<String?> leave() async {
    _isLeaving = true;
    notifyListeners();

    try {
      await _repository.leaveTrip(_tripId);
      return null;
    } catch (e) {
      return friendlyError(e);
    } finally {
      _isLeaving = false;
      notifyListeners();
    }
  }

  /// Same scoped-error pattern as [leave]; reloads the trip on success so [trip.bookingStatus] flips to "cancelled" and the pill/action area update in place.
  Future<String?> cancel() async {
    _isCancelling = true;
    notifyListeners();

    try {
      await _repository.cancelTrip(_tripId);
      _trip = await _repository.getTrip(_tripId);
      return null;
    } catch (e) {
      return friendlyError(e);
    } finally {
      _isCancelling = false;
      notifyListeners();
    }
  }

  /// Organizer-only and capped at trip.MaxPhotosPerTrip server-side; the UI only surfaces the "+" tile to the organizer and hides it at the cap, so a rejection here means something's out of sync.
  Future<String?> addPhoto(String filePath) async {
    try {
      final photo = await _repository.addTripPhoto(_tripId, filePath);
      _photos = [..._photos, photo];
      notifyListeners();
      return null;
    } catch (e) {
      return friendlyError(e);
    }
  }

  final Set<String> _removingPhotoIds = {};
  bool isRemovingPhoto(String photoId) => _removingPhotoIds.contains(photoId);

  /// Same organizer-only posture as [addPhoto].
  Future<String?> removePhoto(String photoId) async {
    _removingPhotoIds.add(photoId);
    notifyListeners();

    try {
      await _repository.removeTripPhoto(_tripId, photoId);
      _photos = _photos.where((p) => p.id != photoId).toList();
      return null;
    } catch (e) {
      return friendlyError(e);
    } finally {
      _removingPhotoIds.remove(photoId);
      notifyListeners();
    }
  }
}
