import 'package:freezed_annotation/freezed_annotation.dart';

part 'transport_offer_api_model.freezed.dart';
part 'transport_offer_api_model.g.dart';

@freezed
abstract class TransportOfferApiModel with _$TransportOfferApiModel {
  const factory TransportOfferApiModel({
    required String id,
    required String tripId,
    required String userId,
    required String type,
    int? seats,
    String? details,
    required DateTime createdAt,
    @Default(0) int joinedCount,
    @Default(false) bool joined,
    @Default(false) bool isDiveCenterStaff,
  }) = _TransportOfferApiModel;

  factory TransportOfferApiModel.fromJson(Map<String, dynamic> json) =>
      _$TransportOfferApiModelFromJson(json);
}
