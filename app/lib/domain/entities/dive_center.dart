import 'package:freezed_annotation/freezed_annotation.dart';

part 'dive_center.freezed.dart';

/// Every field here is public-facing by design — collected during admin/'s onboarding
/// specifically to be shown to divers considering a trip (see CLAUDE.md's Business/dive
/// centers section), unlike Profile which has a private/public split. No `role` field like
/// admin/'s equivalent entity — a diver viewing a dive center isn't a member of it.
@freezed
abstract class DiveCenter with _$DiveCenter {
  const factory DiveCenter({
    required String id,
    required String name,
    String? location,
    String? description,
    String? logoUrl,
    String? agency,
    String? agencyDetail,
    @Default('') String languages,
    String? website,
    String? phone,
    String? email,
    required DateTime createdAt,
  }) = _DiveCenter;
}
