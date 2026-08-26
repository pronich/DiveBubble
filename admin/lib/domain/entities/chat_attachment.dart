// One file on a message — mirrors backend's attachmentResponse. No durationSeconds/video
// support here (admin/'s attach flow only offers photos and PDFs, see pick_chat_attachment.dart).
class ChatAttachment {
  const ChatAttachment({required this.url, required this.type, this.filename, this.sizeBytes});

  final String url;
  final String type; // 'image' | 'video' | 'pdf' — video only ever arrives from a diver's app/ upload.
  final String? filename;
  final int? sizeBytes;

  factory ChatAttachment.fromJson(Map<String, dynamic> json) => ChatAttachment(
        url: json['url'] as String,
        type: json['type'] as String,
        filename: json['filename'] as String?,
        sizeBytes: json['sizeBytes'] as int?,
      );
}
