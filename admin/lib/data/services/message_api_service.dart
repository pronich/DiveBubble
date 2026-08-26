import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/chat_attachment.dart';
import '../../domain/entities/chat_link.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_reaction.dart';
import '../../domain/entities/media_item.dart';
import 'access_token_provider.dart';
import 'auth_required_exception.dart';
import 'multipart_upload.dart';

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

  Future<ChatMessage> sendMessage(
    String tripId,
    String body, {
    List<ChatAttachment> attachments = const [],
    String? replyToId,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/trips/$tripId/messages'),
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'body': body,
        if (attachments.isNotEmpty)
          'attachments': [
            for (final a in attachments) {'url': a.url, 'type': a.type, 'filename': a.filename, 'sizeBytes': a.sizeBytes},
          ],
        if (replyToId != null) 'replyToId': replyToId,
      }),
    );
    if (res.statusCode != 201) {
      throw Exception('sendMessage failed: ${res.statusCode} ${res.body}');
    }
    return ChatMessage.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // Uploads one file first (returning its url/type/filename/sizeBytes), then that result
  // gets passed into sendMessage's attachments list — same two-step flow as app/'s own chat.
  Future<ChatAttachment> uploadAttachment(String tripId, List<int> bytes, String filename) async {
    final json = await uploadImageBytes(
      Uri.parse('$baseUrl/trips/$tripId/messages/attachment'),
      bytes: bytes,
      filename: filename,
      headers: await _authHeaders(),
    );
    return ChatAttachment.fromJson(json);
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

  // Upserts the caller's own reaction (one per user per message, server-enforced) — returns
  // the message's full updated reaction summary, same shape reactToMessage splices back in.
  Future<Map<String, ChatReaction>> setReaction(String tripId, String messageId, String emoji) async {
    final res = await _client.put(
      Uri.parse('$baseUrl/trips/$tripId/messages/$messageId/reaction'),
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode({'emoji': emoji}),
    );
    if (res.statusCode != 200) {
      throw Exception('setReaction failed: ${res.statusCode} ${res.body}');
    }
    return _decodeReactions(res.body);
  }

  Future<Map<String, ChatReaction>> removeReaction(String tripId, String messageId) async {
    final res = await _client.delete(Uri.parse('$baseUrl/trips/$tripId/messages/$messageId/reaction'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('removeReaction failed: ${res.statusCode} ${res.body}');
    }
    return _decodeReactions(res.body);
  }

  Map<String, ChatReaction> _decodeReactions(String body) {
    final reactions = (jsonDecode(body) as Map<String, dynamic>)['reactions'] as Map<String, dynamic>;
    return reactions.map((emoji, raw) => MapEntry(emoji, ChatReaction.fromJson(raw as Map<String, dynamic>)));
  }
}
