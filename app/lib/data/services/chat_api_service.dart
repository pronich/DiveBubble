import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_message_api_model.dart';

class ChatApiService {
  ChatApiService({required this.baseUrl, required this.userId, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final String userId;
  final http.Client _client;

  Map<String, String> get _headers => {'X-User-Id': userId};

  Future<List<ChatMessageApiModel>> fetchMessages(String tripId) async {
    final res = await _client.get(Uri.parse('$baseUrl/trips/$tripId/messages'), headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('fetchMessages failed: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(res.body) as List<dynamic>;
    return decoded
        .map((e) => ChatMessageApiModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> fetchRealtimeToken() async {
    final res = await _client.get(Uri.parse('$baseUrl/realtime/token'), headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('fetchRealtimeToken failed: ${res.statusCode} ${res.body}');
    }
    return (jsonDecode(res.body) as Map<String, dynamic>)['token'] as String;
  }

  Future<void> sendMessage(String tripId, String body) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/trips/$tripId/messages'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'body': body}),
    );
    if (res.statusCode != 201) {
      throw Exception('sendMessage failed: ${res.statusCode} ${res.body}');
    }
  }
}
