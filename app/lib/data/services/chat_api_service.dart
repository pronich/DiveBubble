import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_message_api_model.dart';
import 'access_token_provider.dart';
import 'auth_required_exception.dart';

class ChatApiService {
  ChatApiService({required this.baseUrl, required this.getAccessToken, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final AccessTokenProvider getAccessToken;
  final http.Client _client;

  Future<Map<String, String>> _authHeaders() async {
    final token = await getAccessToken();
    if (token == null) throw const AuthRequiredException();
    return {'Authorization': 'Bearer $token'};
  }

  Future<List<ChatMessageApiModel>> fetchMessages(String tripId, {String? offerId, String? buddyRequestId}) async {
    final res = await _client.get(
      Uri.parse('$baseUrl${_messagesPath(tripId, offerId, buddyRequestId)}'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception('fetchMessages failed: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(res.body) as List<dynamic>;
    return decoded
        .map((e) => ChatMessageApiModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Neither set: the trip's main chat. offerId: a car offer's own chat. buddyRequestId: a
  // buddy group's own chat. The two are mutually exclusive (mirrors the DB's own CHECK).
  String _messagesPath(String tripId, String? offerId, String? buddyRequestId) {
    if (offerId != null) return '/trips/$tripId/transport/$offerId/messages';
    if (buddyRequestId != null) return '/trips/$tripId/buddy/$buddyRequestId/messages';
    return '/trips/$tripId/messages';
  }

  Future<String> fetchRealtimeToken() async {
    final res = await _client.get(Uri.parse('$baseUrl/realtime/token'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchRealtimeToken failed: ${res.statusCode} ${res.body}');
    }
    return (jsonDecode(res.body) as Map<String, dynamic>)['token'] as String;
  }

  Future<void> sendMessage(
    String tripId,
    String body, {
    String? offerId,
    String? buddyRequestId,
    bool mentionsDiveCenter = false,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl${_messagesPath(tripId, offerId, buddyRequestId)}'),
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode({'body': body, 'mentionsDiveCenter': mentionsDiveCenter}),
    );
    if (res.statusCode != 201) {
      throw Exception('sendMessage failed: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> reportMessage(String tripId, String messageId, String reason, {String? details}) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/trips/$tripId/messages/$messageId/report'),
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode({'reason': reason, 'details': details ?? ''}),
    );
    if (res.statusCode != 201) {
      throw Exception('reportMessage failed: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> submitFeedback(
    String tripId,
    int rating,
    List<String> helpedWith,
    String? comment,
    bool contactOk,
  ) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/trips/$tripId/feedback'),
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'rating': rating,
        'helpedWith': helpedWith,
        'comment': comment ?? '',
        'contactOk': contactOk,
      }),
    );
    if (res.statusCode != 204) {
      throw Exception('submitFeedback failed: ${res.statusCode} ${res.body}');
    }
  }
}
