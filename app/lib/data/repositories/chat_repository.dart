import '../../domain/entities/chat_message.dart';
import '../mappers/chat_message_api_mapper.dart';
import '../services/chat_api_service.dart';

class ChatRepository {
  ChatRepository({required ChatApiService service}) : _service = service;

  final ChatApiService _service;

  Future<List<ChatMessage>> getMessages(String tripId) async {
    final apiModels = await _service.fetchMessages(tripId);
    return apiModels.map((m) => m.toDomain()).toList();
  }

  Future<void> sendMessage(String tripId, String body) => _service.sendMessage(tripId, body);
}
