/// Transport-only result of uploading a chat attachment — discarded immediately after being
/// passed into ChatRepository.sendMessage, never persisted on its own.
class AttachmentUploadResult {
  const AttachmentUploadResult({
    required this.url,
    required this.type,
    required this.filename,
    required this.sizeBytes,
  });

  final String url;
  final String type; // 'image' | 'pdf'
  final String filename;
  final int sizeBytes;
}
