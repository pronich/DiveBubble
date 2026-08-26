import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/chat_link.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/media_item.dart';
import 'access_token_provider.dart';
import 'auth_required_exception.dart';

/// No realtime (Centrifugo) wiring yet — REST only, same reload-after-send shape as
/// app/'s own chat before its realtime round landed. A diver's own app already gets live
/// delivery; admin/ catching up is a deferred enhancement, not a correctness gap (see
/// CLAUDE.md's Bubbles section).
class MessageApiService {
  MessageApiService({required this.baseUrl, required this.getAccessToken, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final AccessTokenProvider getAccessToken;
  final http.Client _client;

  Future<Map<String, String>> _authHeaders() async {
    final token = await getAccessToken();
    if (token == null) throw const AuthRequiredException();
    return {'Authorization': 'Bearer $token'};
  }

  Future<List<ChatMessage>> fetchMessages(String tripId) async {
    final res = await _client.get(Uri.parse('$baseUrl/trips/$tripId/messages'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchMessages failed: ${res.statusCode} ${res.body}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> fetchRealtimeToken() async {
    final res = await _client.get(Uri.parse('$baseUrl/realtime/token'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchRealtimeToken failed: ${res.statusCode} ${res.body}');
    }
    return (jsonDecode(res.body) as Map<String, dynamic>)['token'] as String;
  }

  Future<ChatMessage> sendMessage(String tripId, String body) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/trips/$tripId/messages'),
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode({'body': body}),
    );
    if (res.statusCode != 201) {
      throw Exception('sendMessage failed: ${res.statusCode} ${res.body}');
    }
    return ChatMessage.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // Backs the Media ("type=media", image+video) / Files ("type=pdf") tabs on TripDetailPage.
  Future<List<MediaItem>> fetchAttachments(String tripId, {required String type}) async {
    final uri = Uri.parse('$baseUrl/trips/$tripId/messages/attachments').replace(queryParameters: {'type': type});
    final res = await _client.get(uri, headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchAttachments failed: ${res.statusCode} ${res.body}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => MediaItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Backs the Links tab — every URL mentioned in the trip's main chat text.
  Future<List<ChatLink>> fetchLinks(String tripId) async {
    final res = await _client.get(Uri.parse('$baseUrl/trips/$tripId/messages/links'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchLinks failed: ${res.statusCode} ${res.body}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => ChatLink.fromJson(e as Map<String, dynamic>)).toList();
  }
}
