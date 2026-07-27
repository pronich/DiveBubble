import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';

@freezed
abstract class Profile with _$Profile {
  const factory Profile({
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
  }) = _Profile;
}
