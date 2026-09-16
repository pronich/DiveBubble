/// Plain data with no Flutter/UI dependency, so ChatViewModel can accept it directly (pick_attachment.dart's picker UI function produces these).
class PickedAttachment {
  const PickedAttachment({
    required this.path,
    required this.type,
    required this.filename,
    required this.sizeBytes,
    this.durationSeconds,
  });

  final String path;
  final String type; // 'image' | 'pdf' | 'video'
  final String filename;
  final int sizeBytes;
  final int? durationSeconds; // video only
}
