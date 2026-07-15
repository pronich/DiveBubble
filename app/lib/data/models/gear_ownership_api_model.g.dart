// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gear_ownership_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GearOwnershipApiModel _$GearOwnershipApiModelFromJson(
  Map<String, dynamic> json,
) => _GearOwnershipApiModel(
  itemKey: json['itemKey'] as String,
  status: json['status'] as String,
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$GearOwnershipApiModelToJson(
  _GearOwnershipApiModel instance,
) => <String, dynamic>{
  'itemKey': instance.itemKey,
  'status': instance.status,
  'updatedAt': instance.updatedAt.toIso8601String(),
};
