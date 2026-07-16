import 'package:freezed_annotation/freezed_annotation.dart';

part 'dive_center.freezed.dart';

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
    required DateTime createdAt,
    // '' when the API omits it (e.g. a plain GET by id) — only ListMine/Create populate a
    // real role, since "your role" only makes sense in the context of the caller.
    @Default('') String role,
  }) = _DiveCenter;
}
