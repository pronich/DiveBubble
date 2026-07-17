import 'package:flutter/foundation.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/transport_repository.dart';
import '../../../../domain/entities/transport_offer.dart';

class TransportViewModel extends ChangeNotifier {
  TransportViewModel({
    required TransportRepository repository,
    required this.authRepository,
    required this.profileRepository,
    required this.tripId,
    required this.currentUserId,
  }) : _repository = repository;

  final TransportRepository _repository;
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
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
}
