import 'package:freezed_annotation/freezed_annotation.dart';

part 'specialty_certification.freezed.dart';

@freezed
abstract class SpecialtyCertification with _$SpecialtyCertification {
  const factory SpecialtyCertification({
    required String id,
    required String specialty,
    String? customLabel,
    String? agency,
    String? certNumber,
    String? photoUrl,
    @Default(false) bool verified,
    required DateTime createdAt,
  }) = _SpecialtyCertification;
}
