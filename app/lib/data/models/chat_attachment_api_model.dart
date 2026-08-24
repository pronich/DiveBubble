import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_attachment_api_model.freezed.dart';
part 'chat_attachment_api_model.g.dart';

/// Mirrors backend's attachmentResponse (routes_message.go) — url/type always present on a
/// server-sent attachment; filename/sizeBytes/durationSeconds are omitted when empty/zero.
@freezed
abstract class ChatAttachmentApiModel with _$ChatAttachmentApiModel {
  const factory ChatAttachmentApiModel({
    required String url,
    required String type,
    String? filename,
    int? sizeBytes,
    int? durationSeconds,
  }) = _ChatAttachmentApiModel;

  factory ChatAttachmentApiModel.fromJson(Map<String, dynamic> json) =>
      _$ChatAttachmentApiModelFromJson(json);
}
