import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_api_model.freezed.dart';
part 'profile_api_model.g.dart';

@freezed
abstract class ProfileApiModel with _$ProfileApiModel {
  const factory ProfileApiModel({
    required String id,
    String? displayName,
    String? avatarUrl,
    String? location,
    String? bio,
    @Default(0) int diveCount,
    String? certificationLevel,
    String? certificationAgency,
    String? certificationNumber,
    String? certificationPhotoUrl,
    @Default(false) bool certificationVerified,
    @Default('') String languages,
    required DateTime memberSince,
    @Default(false) bool isProductObserver,
  }) = _ProfileApiModel;

  factory ProfileApiModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileApiModelFromJson(json);
}
