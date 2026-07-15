// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'specialty_certification_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SpecialtyCertificationApiModel _$SpecialtyCertificationApiModelFromJson(
  Map<String, dynamic> json,
) => _SpecialtyCertificationApiModel(
  id: json['id'] as String,
  specialty: json['specialty'] as String,
  customLabel: json['customLabel'] as String?,
  agency: json['agency'] as String?,
  certNumber: json['certNumber'] as String?,
  photoUrl: json['photoUrl'] as String?,
  verified: json['verified'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$SpecialtyCertificationApiModelToJson(
  _SpecialtyCertificationApiModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'specialty': instance.specialty,
  'customLabel': instance.customLabel,
  'agency': instance.agency,
  'certNumber': instance.certNumber,
  'photoUrl': instance.photoUrl,
  'verified': instance.verified,
  'createdAt': instance.createdAt.toIso8601String(),
};
