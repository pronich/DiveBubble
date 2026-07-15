import 'package:freezed_annotation/freezed_annotation.dart';

part 'specialty_certification_api_model.freezed.dart';
part 'specialty_certification_api_model.g.dart';

@freezed
abstract class SpecialtyCertificationApiModel with _$SpecialtyCertificationApiModel {
  const factory SpecialtyCertificationApiModel({
    required String id,
    required String specialty,
    String? customLabel,
    String? agency,
    String? certNumber,
    String? photoUrl,
    @Default(false) bool verified,
    required DateTime createdAt,
  }) = _SpecialtyCertificationApiModel;

  factory SpecialtyCertificationApiModel.fromJson(Map<String, dynamic> json) =>
      _$SpecialtyCertificationApiModelFromJson(json);
}
