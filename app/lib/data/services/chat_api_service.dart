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

  Future<List<ChatMessageApiModel>> fetchMessages(String tripId) async {
    final res = await _client.get(Uri.parse('$baseUrl/trips/$tripId/messages'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchMessages failed: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(res.body) as List<dynamic>;
    return decoded
        .map((e) => ChatMessageApiModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> fetchRealtimeToken() async {
    final res = await _client.get(Uri.parse('$baseUrl/realtime/token'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchRealtimeToken failed: ${res.statusCode} ${res.body}');
    }
    return (jsonDecode(res.body) as Map<String, dynamic>)['token'] as String;
  }

  Future<void> sendMessage(String tripId, String body, {bool mentionsDiveCenter = false}) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/trips/$tripId/messages'),
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
}
