import 'package:flutter/foundation.dart';

import '../../../../data/repositories/transport_repository.dart';
import '../../../../domain/entities/transport_offer.dart';

class TransportViewModel extends ChangeNotifier {
  TransportViewModel({
    required TransportRepository repository,
    required this.tripId,
    required this.currentUserId,
  }) : _repository = repository;

  final TransportRepository _repository;
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

  Future<void> join(String offerId) async {
    _joiningOfferIds.add(offerId);
    notifyListeners();

    try {
      await _repository.joinOffer(tripId, offerId);
      _offers = await _repository.getOffers(tripId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _joiningOfferIds.remove(offerId);
      notifyListeners();
    }
  }

  Future<List<String>> getJoinedUserIds(String offerId) => _repository.getJoinedUserIds(tripId, offerId);
}
