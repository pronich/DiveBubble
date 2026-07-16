import 'package:flutter/foundation.dart';

import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/transport_repository.dart';
import '../../../../domain/entities/my_profile.dart';
import '../../../../domain/entities/transport_offer.dart';

/// Scoped to a single trip — one instance per open Bubble, recreated whenever the selected
/// trip changes (same "per-trip, not long-lived" shape as app/'s own TransportViewModel),
/// unlike BubblesViewModel which stays alive across trip switches for the whole tab.
class TransportViewModel extends ChangeNotifier {
  TransportViewModel({
    required TransportRepository transportRepository,
    required ProfileRepository profileRepository,
    required this.tripId,
  })  : _transportRepository = transportRepository,
        _profileRepository = profileRepository;

  final TransportRepository _transportRepository;
  final ProfileRepository _profileRepository;
  final String tripId;

  List<TransportOffer> _offers = [];
  List<TransportOffer> get offers => _offers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _error;
  String? get error => _error;

  final Map<String, MyProfile> _profiles = {};
  Map<String, MyProfile> get profiles => _profiles;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _offers = await _transportRepository.getOffers(tripId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submit({required String type, int? seats, String? details}) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _transportRepository.createOffer(tripId, type: type, seats: seats, details: details);
      _offers = await _transportRepository.getOffers(tripId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<List<String>> getJoinedUserIds(String offerId) => _transportRepository.getJoinedUserIds(tripId, offerId);

  // Best-effort, one-at-a-time — a failed lookup just falls back to "Diver" in the UI,
  // same precedent as BubblesViewModel._resolveSenderProfiles.
  Future<void> resolveProfile(String userId) async {
    if (_profiles.containsKey(userId)) return;
    try {
      _profiles[userId] = await _profileRepository.getById(userId);
      notifyListeners();
    } catch (_) {
      // ignore — row falls back to "Diver"
    }
  }
}
