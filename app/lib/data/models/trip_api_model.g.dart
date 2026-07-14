// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TripApiModel _$TripApiModelFromJson(Map<String, dynamic> json) =>
    _TripApiModel(
      id: json['id'] as String,
      title: json['title'] as String,
      location: json['location'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      joined: json['joined'] as bool,
      creatorUserId: json['creatorUserId'] as String?,
      participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$TripApiModelToJson(_TripApiModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'location': instance.location,
      'startTime': instance.startTime.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'joined': instance.joined,
      'creatorUserId': instance.creatorUserId,
      'participantCount': instance.participantCount,
    };
