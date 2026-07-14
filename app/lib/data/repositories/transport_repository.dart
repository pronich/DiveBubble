import '../../domain/entities/transport_offer.dart';
import '../mappers/transport_offer_api_mapper.dart';
import '../services/transport_api_service.dart';

class TransportRepository {
  TransportRepository({required TransportApiService service}) : _service = service;

  final TransportApiService _service;

  Future<List<TransportOffer>> getOffers(String tripId) async {
    final apiModels = await _service.fetchOffers(tripId);
    return apiModels.map((m) => m.toDomain()).toList();
  }

  Future<TransportOffer> createOffer(String tripId, {required String type, int? seats, String? details}) async {
    final apiModel = await _service.createOffer(tripId, type: type, seats: seats, details: details);
    return apiModel.toDomain();
  }

  Future<void> joinOffer(String tripId, String offerId) => _service.joinOffer(tripId, offerId);
}
