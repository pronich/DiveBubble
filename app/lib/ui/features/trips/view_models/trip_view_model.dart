import 'package:flutter/foundation.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/dive_center_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
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

  List<TripPhoto> _photos = [];
  List<TripPhoto> get photos => _photos;

  Profile? _organizerProfile;
  Profile? get organizerProfile => _organizerProfile;

  DiveCenter? _organizerDiveCenter;
  DiveCenter? get organizerDiveCenter => _organizerDiveCenter;

  bool _isDiveCenterStaff = false;

  /// True for the trip's literal creator *or* any member of the dive center running it —
  /// matches the backend's own trip.Service.isOrganizer exactly (see CLAUDE.md's
  /// Business/dive centers section). Gates Cancel/photo-upload/Join visibility below.
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
        try {
          _isDiveCenterStaff = await diveCenterRepository.isMember(diveCenterId);
        } catch (_) {
          _isDiveCenterStaff = false;
        }
      } else {
        _isDiveCenterStaff = false;
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

  /// Returns null on success, or an error message on failure — organizer-only and capped at
  /// trip.MaxPhotosPerTrip server-side (see trip.ErrOnlyOrganizerCanEditTrip/ErrTooManyPhotos);
  /// the UI only ever surfaces the "+" tile to the organizer and hides it once already at the
  /// cap, so a rejection here would mean something's out of sync rather than an expected path.
  Future<String?> addPhoto(String filePath) async {
    try {
      final photo = await _repository.addTripPhoto(_tripId, filePath);
      _photos = [..._photos, photo];
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  final Set<String> _removingPhotoIds = {};
  bool isRemovingPhoto(String photoId) => _removingPhotoIds.contains(photoId);

  /// Returns null on success, or an error message on failure — same organizer-only posture
  /// as [addPhoto].
  Future<String?> removePhoto(String photoId) async {
    _removingPhotoIds.add(photoId);
    notifyListeners();

    try {
      await _repository.removeTripPhoto(_tripId, photoId);
      _photos = _photos.where((p) => p.id != photoId).toList();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _removingPhotoIds.remove(photoId);
      notifyListeners();
    }
  }
}
