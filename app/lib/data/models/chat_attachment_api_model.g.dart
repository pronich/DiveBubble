// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_attachment_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatAttachmentApiModel _$ChatAttachmentApiModelFromJson(
  Map<String, dynamic> json,
) => _ChatAttachmentApiModel(
  url: json['url'] as String,
  type: json['type'] as String,
  filename: json['filename'] as String?,
  sizeBytes: (json['sizeBytes'] as num?)?.toInt(),
  durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
);

Map<String, dynamic> _$ChatAttachmentApiModelToJson(
  _ChatAttachmentApiModel instance,
) => <String, dynamic>{
  'url': instance.url,
  'type': instance.type,
  'filename': instance.filename,
  'sizeBytes': instance.sizeBytes,
  'durationSeconds': instance.durationSeconds,
};
