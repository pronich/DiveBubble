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
      kind: json['kind'] as String? ?? 'user',
      feedbackProvided: json['feedbackProvided'] as bool? ?? false,
      attachmentUrl: json['attachmentUrl'] as String?,
      attachmentType: json['attachmentType'] as String?,
      attachmentFilename: json['attachmentFilename'] as String?,
      attachmentSizeBytes: (json['attachmentSizeBytes'] as num?)?.toInt(),
      replyToId: json['replyToId'] as String?,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
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
  'kind': instance.kind,
  'feedbackProvided': instance.feedbackProvided,
  'attachmentUrl': instance.attachmentUrl,
  'attachmentType': instance.attachmentType,
  'attachmentFilename': instance.attachmentFilename,
  'attachmentSizeBytes': instance.attachmentSizeBytes,
  'replyToId': instance.replyToId,
  'deletedAt': instance.deletedAt?.toIso8601String(),
};
