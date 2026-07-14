import '../../domain/entities/transport_offer.dart';
import '../models/transport_offer_api_model.dart';

extension TransportOfferApiMapper on TransportOfferApiModel {
  TransportOffer toDomain() => TransportOffer(
        id: id,
        tripId: tripId,
        userId: userId,
        type: type,
        seats: seats,
        details: details,
        createdAt: createdAt,
        joinedCount: joinedCount,
        joined: joined,
      );
}
