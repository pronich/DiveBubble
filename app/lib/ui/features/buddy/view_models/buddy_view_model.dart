import 'package:flutter/foundation.dart';

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

  /// The buddy group (created or joined) this diver is currently part of on this trip, if
  /// any — at most one, since joining is capped to one group per trip (see
  /// buddy.ErrAlreadyBooked server-side). Drives both the Buddy tab's chat-vs-list swap
  /// (BuddyView) and the ⓘ affordance's visibility (TripConversationPage).
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
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Seeds the alert dot from data the caller already has (e.g. Trip.hasBuddyAlert) instead
  /// of a fresh network round-trip — the flag isn't cleared server-side by this, only
  /// [checkAlert] (called on an actual Buddy-tab visit) does that.
  void seedAlert(bool value) {
    _hasAlert = value;
    notifyListeners();
  }

  /// Checks (and, server-side, clears) whether the buddy list changed under this diver since
  /// they last looked — call whenever the Buddy tab is actually shown, not on every [load],
  /// since viewing is what acknowledges the alert.
  Future<void> checkAlert() async {
    try {
      _hasAlert = await _repository.getHasAlert(tripId);
    } catch (_) {
      // Best-effort — a failed check just leaves the dot as it was, not worth surfacing.
    }
    notifyListeners();
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
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Returns null on success, or an error message on failure — a join failure (e.g. already
  /// booked elsewhere on this trip) shouldn't blow away the whole list via the shared [error]
  /// field, just that one action.
  Future<String?> join(String requestId) async {
    _joiningRequestIds.add(requestId);
    notifyListeners();

    try {
      await _repository.joinRequest(tripId, requestId);
      _requests = await _repository.getRequests(tripId);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
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
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Creator-only: cancels the buddy group outright. Returns an error message on failure,
  /// null on success.
  Future<String?> dissolve(String requestId) async {
    try {
      await _repository.dissolveRequest(tripId, requestId);
      _requests = await _repository.getRequests(tripId);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}
