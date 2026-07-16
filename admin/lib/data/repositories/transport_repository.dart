import '../../domain/entities/transport_offer.dart';
import '../services/transport_api_service.dart';

class TransportRepository {
  TransportRepository({required TransportApiService service}) : _service = service;

  final TransportApiService _service;

  Future<List<TransportOffer>> getOffers(String tripId) => _service.fetchOffers(tripId);

  Future<TransportOffer> createOffer(String tripId, {required String type, int? seats, String? details}) =>
      _service.createOffer(tripId, type: type, seats: seats, details: details);

  Future<List<String>> getJoinedUserIds(String tripId, String offerId) => _service.fetchJoinedUserIds(tripId, offerId);
}
