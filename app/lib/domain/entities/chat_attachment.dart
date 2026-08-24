import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_attachment.freezed.dart';

/// One file on a message — a message can carry several now (see migration 000054 backend-side,
/// up to 9, mixed photo/video/pdf), replacing the old single attachmentUrl/Type/Filename/
/// SizeBytes scalar fields ChatMessage used to have directly.
@freezed
abstract class ChatAttachment with _$ChatAttachment {
  const factory ChatAttachment({
    // Null only for a pending item still uploading (see localPath/isUploaded below) — every
    // attachment that came from the REST list or realtime always has this set.
    String? url,
    required String type, // 'image' | 'video' | 'pdf'
    String? filename,
    int? sizeBytes,
    // Video only.
    int? durationSeconds,
    // Set only on a pending item, before url exists — lets the bubble render the picked file
    // immediately (thumbnail/filename) while the upload is in flight. Mirrors what
    // ChatMessage.localAttachmentPath used to do for the single-attachment case.
    String? localPath,
    // False only for a pending item whose upload hasn't completed yet.
    @Default(true) bool isUploaded,
  }) = _ChatAttachment;
}
