import '../../domain/entities/chat_message.dart';
import '../mappers/chat_message_api_mapper.dart';
import '../services/chat_api_service.dart';

class ChatRepository {
  ChatRepository({required ChatApiService service}) : _service = service;

  final ChatApiService _service;

  Future<List<ChatMessage>> getMessages(String tripId, {String? offerId}) async {
    final apiModels = await _service.fetchMessages(tripId, offerId: offerId);
    return apiModels.map((m) => m.toDomain()).toList();
  }

  Future<void> sendMessage(String tripId, String body, {String? offerId, bool mentionsDiveCenter = false}) =>
      _service.sendMessage(tripId, body, offerId: offerId, mentionsDiveCenter: mentionsDiveCenter);

  Future<void> reportMessage(String tripId, String messageId, String reason, {String? details}) =>
      _service.reportMessage(tripId, messageId, reason, details: details);

  Future<void> submitFeedback(String tripId, int rating, List<String> helpedWith, String? comment, bool contactOk) =>
      _service.submitFeedback(tripId, rating, helpedWith, comment, contactOk);

  Future<String> getRealtimeToken() => _service.fetchRealtimeToken();
}
