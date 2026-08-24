import 'package:freezed_annotation/freezed_annotation.dart';

import 'chat_attachment_api_model.dart';

part 'media_item_api_model.freezed.dart';
part 'media_item_api_model.g.dart';

/// Mirrors backend's mediaItemResponse (routes_message.go) — backs Bubble Info's Media/Files
/// tabs, one row per attachment rather than per message.
@freezed
abstract class MediaItemApiModel with _$MediaItemApiModel {
  const factory MediaItemApiModel({
    required String messageId,
    required String userId,
    required DateTime createdAt,
    required ChatAttachmentApiModel attachment,
  }) = _MediaItemApiModel;

  factory MediaItemApiModel.fromJson(Map<String, dynamic> json) =>
      _$MediaItemApiModelFromJson(json);
}
