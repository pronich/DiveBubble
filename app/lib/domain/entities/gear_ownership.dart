import 'package:freezed_annotation/freezed_annotation.dart';

part 'gear_ownership.freezed.dart';

@freezed
abstract class GearOwnership with _$GearOwnership {
  const factory GearOwnership({
    required String itemKey,
    required String status,
  }) = _GearOwnership;
}
