import 'package:flutter/foundation.dart';

import '../../../../data/services/error_codes.dart';

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

  /// At most one, since joining is capped to one ride per trip (transport.ErrAlreadyBooked server-side).
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

  /// Clears the alert server-side too, so only call this on an actual Transport-tab visit, not on every [load].
  Future<void> checkAlert() async {
    try {
      _hasAlert = await _repository.getHasAlert(tripId);
    } catch (_) {
      // Best-effort — a failed check just leaves the dot as it was, not worth surfacing.
    }
    notifyListeners();
  }

  /// Updates the local flag optimistically so the pill dot clears immediately rather than waiting on the next [load].
  Future<void> markMyOfferRead() async {
    final offer = myOffer;
    if (offer == null || !offer.hasUnreadMessages) return;
    _offers = [
      for (final o in _offers)
        if (o.id == offer.id) o.copyWith(hasUnreadMessages: false) else o,
    ];
    notifyListeners();
    try {
      await _repository.markOfferRead(tripId, offer.id);
    } catch (_) {
      // Best-effort — worst case the dot reappears on the next load().
    }
  }

  /// Returns an error message instead of using the shared [error] field, so a failed submission doesn't blow away the whole list, just the still-open sheet.
  Future<String?> submit({required String type, int? seats, String? details}) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      await _repository.createOffer(tripId, type: type, seats: seats, details: details);
      _offers = await _repository.getOffers(tripId);
      return null;
    } catch (e) {
      return friendlyError(e);
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Returns an error message instead of using the shared [error] field, so a join failure doesn't blow away the whole list, just that one action.
  Future<String?> join(String offerId) async {
    _joiningOfferIds.add(offerId);
    notifyListeners();

    try {
      await _repository.joinOffer(tripId, offerId);
      _offers = await _repository.getOffers(tripId);
      return null;
    } catch (e) {
      return friendlyError(e);
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
      return friendlyError(e);
    }
  }

  /// Creator-only: cancels the car outright.
  Future<String?> dissolve(String offerId) async {
    try {
      await _repository.dissolveOffer(tripId, offerId);
      _offers = await _repository.getOffers(tripId);
      notifyListeners();
      return null;
    } catch (e) {
      return friendlyError(e);
    }
  }
}
