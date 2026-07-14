// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProfileApiModel _$ProfileApiModelFromJson(Map<String, dynamic> json) =>
    _ProfileApiModel(
      id: json['id'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      location: json['location'] as String?,
      bio: json['bio'] as String?,
      diveCount: (json['diveCount'] as num?)?.toInt() ?? 0,
      certificationLevel: json['certificationLevel'] as String?,
      languages: json['languages'] as String? ?? '',
      memberSince: DateTime.parse(json['memberSince'] as String),
    );

Map<String, dynamic> _$ProfileApiModelToJson(_ProfileApiModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'location': instance.location,
      'bio': instance.bio,
      'diveCount': instance.diveCount,
      'certificationLevel': instance.certificationLevel,
      'languages': instance.languages,
      'memberSince': instance.memberSince.toIso8601String(),
    };
