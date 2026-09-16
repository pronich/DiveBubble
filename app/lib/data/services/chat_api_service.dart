import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/attachment_upload_result.dart';
import '../../domain/entities/chat_link.dart';
import '../models/chat_message_api_model.dart';
import '../models/chat_reaction_api_model.dart';
import '../models/media_item_api_model.dart';
import 'access_token_provider.dart';
import 'auth_required_exception.dart';
import 'error_codes.dart';
import 'multipart_upload.dart';

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

  // Server errors come back as {"error": "<code>"}; describeErrorCode maps it to a message or passes it through unchanged if unrecognized.
  String? _extractError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['error'] is String) {
        return describeErrorCode(decoded['error'] as String);
      }
    } catch (_) {
      // fall through
    }
    return null;
  }

  Future<List<ChatMessageApiModel>> fetchMessages(String tripId, {String? offerId, String? buddyRequestId}) async {
    final res = await _client.get(
      Uri.parse('$baseUrl${_messagesPath(tripId, offerId, buddyRequestId)}'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'fetchMessages failed: ${res.statusCode}');
    }
    final decoded = jsonDecode(res.body) as List<dynamic>;
    return decoded
        .map((e) => ChatMessageApiModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // offerId and buddyRequestId are mutually exclusive, mirroring the DB's own CHECK constraint.
  String _messagesPath(String tripId, String? offerId, String? buddyRequestId) {
    if (offerId != null) return '/trips/$tripId/transport/$offerId/messages';
    if (buddyRequestId != null) return '/trips/$tripId/buddy/$buddyRequestId/messages';
    return '/trips/$tripId/messages';
  }

  Future<String> fetchRealtimeToken() async {
    final res = await _client.get(Uri.parse('$baseUrl/realtime/token'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'fetchRealtimeToken failed: ${res.statusCode}');
    }
    return (jsonDecode(res.body) as Map<String, dynamic>)['token'] as String;
  }

  Future<ChatMessageApiModel> sendMessage(
    String tripId,
    String body, {
    String? offerId,
    String? buddyRequestId,
    bool mentionsDiveCenter = false,
    List<AttachmentUploadResult> attachments = const [],
    String? replyToId,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl${_messagesPath(tripId, offerId, buddyRequestId)}'),
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'body': body,
        'mentionsDiveCenter': mentionsDiveCenter,
        if (attachments.isNotEmpty)
          'attachments': [
            for (final a in attachments)
              {
                'url': a.url,
                'type': a.type,
                'filename': a.filename,
                'sizeBytes': a.sizeBytes,
                if (a.durationSeconds != null) 'durationSeconds': a.durationSeconds,
              },
          ],
        if (replyToId != null) 'replyToId': replyToId,
      }),
    );
    if (res.statusCode != 201) {
      throw Exception(_extractError(res.body) ?? 'sendMessage failed: ${res.statusCode}');
    }
    return ChatMessageApiModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // Scope-agnostic (backend resolves the trip off the message row itself) and returns the now-redacted message so the caller can splice it straight into its local list.
  Future<ChatMessageApiModel> deleteMessage(String tripId, String messageId) async {
    final res = await _client.delete(
      Uri.parse('$baseUrl/trips/$tripId/messages/$messageId'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'deleteMessage failed: ${res.statusCode}');
    }
    return ChatMessageApiModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // Idempotent: setting the same emoji again is just an upsert; removing one never set is a no-op.
  Future<Map<String, ChatReactionApiModel>> setReaction(String tripId, String messageId, String emoji) async {
    final res = await _client.put(
      Uri.parse('$baseUrl/trips/$tripId/messages/$messageId/reaction'),
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode({'emoji': emoji}),
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'setReaction failed: ${res.statusCode}');
    }
    return _decodeReactions(res.body);
  }

  Future<Map<String, ChatReactionApiModel>> removeReaction(String tripId, String messageId) async {
    final res = await _client.delete(
      Uri.parse('$baseUrl/trips/$tripId/messages/$messageId/reaction'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'removeReaction failed: ${res.statusCode}');
    }
    return _decodeReactions(res.body);
  }

  Map<String, ChatReactionApiModel> _decodeReactions(String body) {
    final reactions = (jsonDecode(body) as Map<String, dynamic>)['reactions'] as Map<String, dynamic>? ?? {};
    return reactions.map((emoji, raw) => MapEntry(emoji, ChatReactionApiModel.fromJson(raw as Map<String, dynamic>)));
  }

  // Scope-agnostic by design — the backend only needs the caller to be a trip participant, not which chat the message will land in.
  Future<Map<String, dynamic>> uploadAttachment(String tripId, String filePath) async =>
      uploadFile(Uri.parse('$baseUrl/trips/$tripId/messages/attachment'), filePath: filePath, headers: await _authHeaders());

  // One row per attachment (see MediaItemApiModel), not per message, since a message can carry several attachments.
  Future<List<MediaItemApiModel>> fetchAttachments(
    String tripId, {
    required String type,
    DateTime? before,
    int limit = 50,
  }) async {
    final query = {
      'type': type,
      'limit': '$limit',
      if (before != null) 'before': before.toUtc().toIso8601String(),
    };
    final uri = Uri.parse('$baseUrl/trips/$tripId/messages/attachments').replace(queryParameters: query);
    final res = await _client.get(uri, headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'fetchAttachments failed: ${res.statusCode}');
    }
    final decoded = jsonDecode(res.body) as List<dynamic>;
    return decoded.map((e) => MediaItemApiModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Backs the Links tab in Chat Info — every URL mentioned in main-chat message text.
  Future<List<ChatLink>> fetchLinks(String tripId, {DateTime? before, int limit = 50}) async {
    final query = {
      'limit': '$limit',
      if (before != null) 'before': before.toUtc().toIso8601String(),
    };
    final uri = Uri.parse('$baseUrl/trips/$tripId/messages/links').replace(queryParameters: query);
    final res = await _client.get(uri, headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'fetchLinks failed: ${res.statusCode}');
    }
    final decoded = jsonDecode(res.body) as List<dynamic>;
    return decoded.map((e) => ChatLink.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> reportMessage(String tripId, String messageId, String reason, {String? details}) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/trips/$tripId/messages/$messageId/report'),
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode({'reason': reason, 'details': details ?? ''}),
    );
    if (res.statusCode != 201) {
      throw Exception(_extractError(res.body) ?? 'reportMessage failed: ${res.statusCode}');
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
      throw Exception(_extractError(res.body) ?? 'submitFeedback failed: ${res.statusCode}');
    }
  }
}
