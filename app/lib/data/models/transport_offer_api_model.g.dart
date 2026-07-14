// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transport_offer_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TransportOfferApiModel _$TransportOfferApiModelFromJson(
  Map<String, dynamic> json,
) => _TransportOfferApiModel(
  id: json['id'] as String,
  tripId: json['tripId'] as String,
  userId: json['userId'] as String,
  type: json['type'] as String,
  seats: (json['seats'] as num?)?.toInt(),
  details: json['details'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$TransportOfferApiModelToJson(
  _TransportOfferApiModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'tripId': instance.tripId,
  'userId': instance.userId,
  'type': instance.type,
  'seats': instance.seats,
  'details': instance.details,
  'createdAt': instance.createdAt.toIso8601String(),
};
