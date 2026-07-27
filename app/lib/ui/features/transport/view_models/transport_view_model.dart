import 'package:flutter/foundation.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/push_repository.dart';
import '../../../../data/repositories/transport_repository.dart';
import '../../../../domain/entities/transport_offer.dart';

class TransportViewModel extends ChangeNotifier {
  TransportViewModel({
    required TransportRepository repository,
    required this.authRepository,
    required this.profileRepository,
    required this.pushRepository,
    required this.tripId,
    required this.currentUserId,
  }) : _repository = repository;

  final TransportRepository _repository;
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final PushRepository pushRepository;
  final String tripId;
  final String currentUserId;

  List<TransportOffer> _offers = [];
  List<TransportOffer> get offers => _offers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _error;
  String? get error => _error;

  final Set<String> _joiningOfferIds = {};
  bool isJoining(String offerId) => _joiningOfferIds.contains(offerId);

  bool _hasAlert = false;
  bool get hasAlert => _hasAlert;

  /// The car (created or joined) this diver is currently part of on this trip, if any — at
  /// most one, since joining is capped to one ride per trip (see transport.ErrAlreadyBooked
  /// server-side). Drives both the Transport tab's chat-vs-list swap (TransportView) and the
  /// ⓘ affordance's visibility (TripConversationPage).
  TransportOffer? get myOffer {
    for (final o in _offers) {
      if (o.joined || o.userId == currentUserId) return o;
    }
    return null;
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _offers = await _repository.getOffers(tripId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Seeds the alert dot from data the caller already has (e.g. Trip.hasTransportAlert)
  /// instead of a fresh network round-trip — the flag isn't cleared server-side by this,
  /// only [checkAlert] (called on an actual Transport-tab visit) does that.
  void seedAlert(bool value) {
    _hasAlert = value;
    notifyListeners();
  }

  /// Checks (and, server-side, clears) whether transport changed under this diver since
  /// they last looked — call whenever the Transport tab is actually shown, not on every
  /// [load], since viewing is what acknowledges the alert.
  Future<void> checkAlert() async {
    try {
      _hasAlert = await _repository.getHasAlert(tripId);
    } catch (_) {
      // Best-effort — a failed check just leaves the dot as it was, not worth surfacing.
    }
    notifyListeners();
  }

  Future<bool> submit({required String type, int? seats, String? details}) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      await _repository.createOffer(tripId, type: type, seats: seats, details: details);
      _offers = await _repository.getOffers(tripId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Returns null on success, or an error message on failure — a join failure
  /// (e.g. already booked elsewhere on this trip) shouldn't blow away the whole
  /// list via the shared [error] field, just that one action.
  Future<String?> join(String offerId) async {
    _joiningOfferIds.add(offerId);
    notifyListeners();

    try {
      await _repository.joinOffer(tripId, offerId);
      _offers = await _repository.getOffers(tripId);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _joiningOfferIds.remove(offerId);
      notifyListeners();
    }
  }

  Future<List<String>> getJoinedUserIds(String offerId) => _repository.getJoinedUserIds(tripId, offerId);

  /// Steps a joiner out of a car — returns an error message on failure, null on success.
  Future<String?> leave(String offerId) async {
    try {
      await _repository.leaveOffer(tripId, offerId);
      _offers = await _repository.getOffers(tripId);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Creator-only: cancels the car outright. Returns an error message on failure, null on
  /// success.
  Future<String?> dissolve(String offerId) async {
    try {
      await _repository.dissolveOffer(tripId, offerId);
      _offers = await _repository.getOffers(tripId);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}
