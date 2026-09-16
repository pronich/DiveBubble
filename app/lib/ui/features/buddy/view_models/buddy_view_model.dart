import 'package:flutter/foundation.dart';

import '../../../../data/services/error_codes.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/buddy_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/push_repository.dart';
import '../../../../domain/entities/buddy_request.dart';

class BuddyViewModel extends ChangeNotifier {
  BuddyViewModel({
    required BuddyRepository repository,
    required this.authRepository,
    required this.profileRepository,
    required this.pushRepository,
    required this.tripId,
    required this.currentUserId,
  }) : _repository = repository;

  final BuddyRepository _repository;
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final PushRepository pushRepository;
  final String tripId;
  final String currentUserId;

  List<BuddyRequest> _requests = [];
  List<BuddyRequest> get requests => _requests;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _error;
  String? get error => _error;

  final Set<String> _joiningRequestIds = {};
  bool isJoining(String requestId) => _joiningRequestIds.contains(requestId);

  bool _hasAlert = false;
  bool get hasAlert => _hasAlert;

  /// At most one, since a diver is capped to one buddy group per trip (buddy.ErrAlreadyBooked server-side).
  BuddyRequest? get myRequest {
    for (final r in _requests) {
      if (r.joined || r.userId == currentUserId) return r;
    }
    return null;
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _requests = await _repository.getRequests(tripId);
    } catch (e) {
      _error = friendlyError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Only sets the local flag; unlike [checkAlert] this never clears it server-side.
  void seedAlert(bool value) {
    _hasAlert = value;
    notifyListeners();
  }

  /// Clears the alert server-side too, so only call this on an actual Buddy-tab visit, not on every [load].
  Future<void> checkAlert() async {
    try {
      _hasAlert = await _repository.getHasAlert(tripId);
    } catch (_) {
      // Best-effort — a failed check just leaves the dot as it was, not worth surfacing.
    }
    notifyListeners();
  }

  /// Updates the local flag optimistically so the pill dot clears immediately rather than waiting on the next [load].
  Future<void> markMyRequestRead() async {
    final request = myRequest;
    if (request == null || !request.hasUnreadMessages) return;
    _requests = [
      for (final r in _requests)
        if (r.id == request.id) r.copyWith(hasUnreadMessages: false) else r,
    ];
    notifyListeners();
    try {
      await _repository.markRequestRead(tripId, request.id);
    } catch (_) {
      // Best-effort — worst case the dot reappears on the next load().
    }
  }

  /// No fields at all — a buddy request is just "I want a buddy for this trip".
  Future<bool> submit() async {
    _isSubmitting = true;
    notifyListeners();

    try {
      await _repository.createRequest(tripId);
      _requests = await _repository.getRequests(tripId);
      return true;
    } catch (e) {
      _error = friendlyError(e);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Returns an error message instead of using the shared [error] field, so a join failure doesn't blow away the whole list.
  Future<String?> join(String requestId) async {
    _joiningRequestIds.add(requestId);
    notifyListeners();

    try {
      await _repository.joinRequest(tripId, requestId);
      _requests = await _repository.getRequests(tripId);
      return null;
    } catch (e) {
      return friendlyError(e);
    } finally {
      _joiningRequestIds.remove(requestId);
      notifyListeners();
    }
  }

  Future<List<String>> getJoinedUserIds(String requestId) => _repository.getJoinedUserIds(tripId, requestId);

  /// Steps a joiner out of a buddy group — returns an error message on failure, null on success.
  Future<String?> leave(String requestId) async {
    try {
      await _repository.leaveRequest(tripId, requestId);
      _requests = await _repository.getRequests(tripId);
      notifyListeners();
      return null;
    } catch (e) {
      return friendlyError(e);
    }
  }

  /// Creator-only: cancels the buddy group outright.
  Future<String?> dissolve(String requestId) async {
    try {
      await _repository.dissolveRequest(tripId, requestId);
      _requests = await _repository.getRequests(tripId);
      notifyListeners();
      return null;
    } catch (e) {
      return friendlyError(e);
    }
  }
}
