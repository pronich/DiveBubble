import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_attachment.freezed.dart';

/// A message can carry up to 9 of these now (migration 000054), replacing the old single attachmentUrl/Type/Filename/SizeBytes scalar fields ChatMessage used to have directly.
@freezed
abstract class ChatAttachment with _$ChatAttachment {
  const factory ChatAttachment({
    // Null only for a pending item still uploading; always set once it came from the REST list or realtime.
    String? url,
    required String type, // 'image' | 'video' | 'pdf'
    String? filename,
    int? sizeBytes,
    // Video only.
    int? durationSeconds,
    // Set only on a pending item, before url exists — lets the bubble render the picked file immediately while the upload is in flight.
    String? localPath,
    // False only for a pending item whose upload hasn't completed yet.
    @Default(true) bool isUploaded,
  }) = _ChatAttachment;
}
