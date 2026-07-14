import 'package:freezed_annotation/freezed_annotation.dart';

part 'transport_offer.freezed.dart';

@freezed
abstract class TransportOffer with _$TransportOffer {
  const factory TransportOffer({
    required String id,
    required String tripId,
    required String userId,
    required String type,
    int? seats,
    String? details,
    required DateTime createdAt,
    @Default(0) int joinedCount,
    @Default(false) bool joined,
  }) = _TransportOffer;
}
