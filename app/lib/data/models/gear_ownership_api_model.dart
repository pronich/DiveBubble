import 'package:freezed_annotation/freezed_annotation.dart';

part 'gear_ownership_api_model.freezed.dart';
part 'gear_ownership_api_model.g.dart';

@freezed
abstract class GearOwnershipApiModel with _$GearOwnershipApiModel {
  const factory GearOwnershipApiModel({
    required String itemKey,
    required String status,
    required DateTime updatedAt,
  }) = _GearOwnershipApiModel;

  factory GearOwnershipApiModel.fromJson(Map<String, dynamic> json) =>
      _$GearOwnershipApiModelFromJson(json);
}
