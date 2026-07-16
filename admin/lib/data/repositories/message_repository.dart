import '../../domain/entities/chat_message.dart';
import '../services/message_api_service.dart';

class MessageRepository {
  MessageRepository({required MessageApiService service}) : _service = service;

  final MessageApiService _service;

  Future<List<ChatMessage>> getMessages(String tripId) => _service.fetchMessages(tripId);

  Future<ChatMessage> sendMessage(String tripId, String body) => _service.sendMessage(tripId, body);
}
