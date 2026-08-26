import '../../domain/entities/chat_attachment.dart';
import '../../domain/entities/chat_link.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/media_item.dart';
import '../services/message_api_service.dart';

class MessageRepository {
  MessageRepository({required MessageApiService service}) : _service = service;

  final MessageApiService _service;

  Future<List<ChatMessage>> getMessages(String tripId) => _service.fetchMessages(tripId);

  Future<ChatMessage> sendMessage(
    String tripId,
    String body, {
    List<ChatAttachment> attachments = const [],
    String? replyToId,
  }) =>
      _service.sendMessage(tripId, body, attachments: attachments, replyToId: replyToId);

  Future<ChatAttachment> uploadAttachment(String tripId, List<int> bytes, String filename) =>
      _service.uploadAttachment(tripId, bytes, filename);

  Future<String> getRealtimeToken() => _service.fetchRealtimeToken();

  Future<List<MediaItem>> getMediaAttachments(String tripId) => _service.fetchAttachments(tripId, type: 'media');

  Future<List<MediaItem>> getFileAttachments(String tripId) => _service.fetchAttachments(tripId, type: 'pdf');

  Future<List<ChatLink>> getLinks(String tripId) => _service.fetchLinks(tripId);
}
