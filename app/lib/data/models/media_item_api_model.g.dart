// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_item_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MediaItemApiModel _$MediaItemApiModelFromJson(Map<String, dynamic> json) =>
    _MediaItemApiModel(
      messageId: json['messageId'] as String,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      attachment: ChatAttachmentApiModel.fromJson(
        json['attachment'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$MediaItemApiModelToJson(_MediaItemApiModel instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'userId': instance.userId,
      'createdAt': instance.createdAt.toIso8601String(),
      'attachment': instance.attachment,
    };
