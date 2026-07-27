import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_request_api_model.freezed.dart';
part 'buddy_request_api_model.g.dart';

@freezed
abstract class BuddyRequestApiModel with _$BuddyRequestApiModel {
  const factory BuddyRequestApiModel({
    required String id,
    required String tripId,
    required String userId,
    required DateTime createdAt,
    @Default(0) int joinedCount,
    @Default(false) bool joined,
    @Default(3) int maxMembers,
    @Default('') String creatorName,
    String? creatorLevel,
    @Default(0) int creatorDiveCount,
  }) = _BuddyRequestApiModel;

  factory BuddyRequestApiModel.fromJson(Map<String, dynamic> json) =>
      _$BuddyRequestApiModelFromJson(json);
}
