import '../../domain/entities/attachment_upload_result.dart';
import '../../domain/entities/chat_link.dart';
import '../../domain/entities/chat_message.dart';
import '../mappers/chat_message_api_mapper.dart';
import '../services/chat_api_service.dart';

class ChatRepository {
  ChatRepository({required ChatApiService service}) : _service = service;

  final ChatApiService _service;

  Future<List<ChatMessage>> getMessages(String tripId, {String? offerId, String? buddyRequestId}) async {
    final apiModels = await _service.fetchMessages(tripId, offerId: offerId, buddyRequestId: buddyRequestId);
    return apiModels.map((m) => m.toDomain()).toList();
  }

  Future<void> sendMessage(
    String tripId,
    String body, {
    String? offerId,
    String? buddyRequestId,
    bool mentionsDiveCenter = false,
    String? attachmentUrl,
    String? attachmentType,
    String? attachmentFilename,
    int? attachmentSizeBytes,
  }) =>
      _service.sendMessage(
        tripId,
        body,
        offerId: offerId,
        buddyRequestId: buddyRequestId,
        mentionsDiveCenter: mentionsDiveCenter,
        attachmentUrl: attachmentUrl,
        attachmentType: attachmentType,
        attachmentFilename: attachmentFilename,
        attachmentSizeBytes: attachmentSizeBytes,
      );

  // Returns the transport-only upload result (url/type/filename/sizeBytes) — the caller passes
  // it straight into sendMessage above; nothing here is persisted independently.
  Future<AttachmentUploadResult> uploadAttachment(String tripId, String filePath) async {
    final json = await _service.uploadAttachment(tripId, filePath);
    return AttachmentUploadResult(
      url: json['url'] as String,
      type: json['type'] as String,
      filename: json['filename'] as String,
      sizeBytes: json['sizeBytes'] as int,
    );
  }

  Future<void> reportMessage(String tripId, String messageId, String reason, {String? details}) =>
      _service.reportMessage(tripId, messageId, reason, details: details);

  Future<void> submitFeedback(String tripId, int rating, List<String> helpedWith, String? comment, bool contactOk) =>
      _service.submitFeedback(tripId, rating, helpedWith, comment, contactOk);

  Future<String> getRealtimeToken() => _service.fetchRealtimeToken();

  // Chat Info's Media/Files/Links tabs — main trip chat only (v1 scope, see the backend plan).
  Future<List<ChatMessage>> getMediaAttachments(String tripId, {DateTime? before, int limit = 50}) async {
    final apiModels = await _service.fetchAttachments(tripId, type: 'image', before: before, limit: limit);
    return apiModels.map((m) => m.toDomain()).toList();
  }

  Future<List<ChatMessage>> getFileAttachments(String tripId, {DateTime? before, int limit = 50}) async {
    final apiModels = await _service.fetchAttachments(tripId, type: 'pdf', before: before, limit: limit);
    return apiModels.map((m) => m.toDomain()).toList();
  }

  Future<List<ChatLink>> getLinks(String tripId, {DateTime? before, int limit = 50}) =>
      _service.fetchLinks(tripId, before: before, limit: limit);
}
