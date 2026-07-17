// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatMessageApiModel _$ChatMessageApiModelFromJson(Map<String, dynamic> json) =>
    _ChatMessageApiModel(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      userId: json['userId'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isDiveCenterStaff: json['isDiveCenterStaff'] as bool? ?? false,
      mentionsDiveCenter: json['mentionsDiveCenter'] as bool? ?? false,
    );

Map<String, dynamic> _$ChatMessageApiModelToJson(
  _ChatMessageApiModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'tripId': instance.tripId,
  'userId': instance.userId,
  'body': instance.body,
  'createdAt': instance.createdAt.toIso8601String(),
  'isDiveCenterStaff': instance.isDiveCenterStaff,
  'mentionsDiveCenter': instance.mentionsDiveCenter,
};
