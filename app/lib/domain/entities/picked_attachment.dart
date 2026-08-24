/// A file picked for a chat attachment, not yet uploaded — local path plus enough metadata
/// (type, filename, size) to show a pending-attachment chip/thumbnail and pre-check the size
/// before uploading. Plain data, no Flutter/UI dependency, so ChatViewModel can accept it
/// directly (see pick_attachment.dart for the picker UI function that produces these).
class PickedAttachment {
  const PickedAttachment({
    required this.path,
    required this.type,
    required this.filename,
    required this.sizeBytes,
  });

  final String path;
  final String type; // 'image' | 'pdf' — 'video' joins in the video stage
  final String filename;
  final int sizeBytes;
}
