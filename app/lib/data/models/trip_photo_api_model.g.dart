// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_photo_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TripPhotoApiModel _$TripPhotoApiModelFromJson(Map<String, dynamic> json) =>
    _TripPhotoApiModel(
      id: json['id'] as String,
      url: json['url'] as String,
      position: (json['position'] as num).toInt(),
    );

Map<String, dynamic> _$TripPhotoApiModelToJson(_TripPhotoApiModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'position': instance.position,
    };
