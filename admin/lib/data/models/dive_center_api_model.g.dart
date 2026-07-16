// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dive_center_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DiveCenterApiModel _$DiveCenterApiModelFromJson(Map<String, dynamic> json) =>
    _DiveCenterApiModel(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String?,
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      agency: json['agency'] as String?,
      agencyDetail: json['agencyDetail'] as String?,
      languages: json['languages'] as String? ?? '',
      website: json['website'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      role: json['role'] as String?,
    );

Map<String, dynamic> _$DiveCenterApiModelToJson(_DiveCenterApiModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'location': instance.location,
      'description': instance.description,
      'logoUrl': instance.logoUrl,
      'agency': instance.agency,
      'agencyDetail': instance.agencyDetail,
      'languages': instance.languages,
      'website': instance.website,
      'phone': instance.phone,
      'email': instance.email,
      'createdAt': instance.createdAt.toIso8601String(),
      'role': instance.role,
    };
