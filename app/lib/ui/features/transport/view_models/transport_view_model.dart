import 'package:flutter/foundation.dart';

import '../../../../data/repositories/transport_repository.dart';
import '../../../../domain/entities/transport_offer.dart';

class TransportViewModel extends ChangeNotifier {
  TransportViewModel({required TransportRepository repository, required this.tripId}) : _repository = repository;

  final TransportRepository _repository;
  final String tripId;

  List<TransportOffer> _offers = [];
  List<TransportOffer> get offers => _offers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _error;
  String? get error => _error;

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
}
