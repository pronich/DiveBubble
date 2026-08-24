import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/attachment_upload_result.dart';
import '../../domain/entities/chat_link.dart';
import '../models/chat_message_api_model.dart';
import '../models/media_item_api_model.dart';
import 'access_token_provider.dart';
import 'auth_required_exception.dart';
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
      throw Exception('sendMessage failed: ${res.statusCode} ${res.body}');
    }
    return ChatMessageApiModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // Soft-delete — author-only, enforced server-side. Scope-agnostic path (works for main chat,
  // offer chat, or buddy chat messages alike; the backend resolves the trip off the message
  // row itself), so no offerId/buddyRequestId param needed here, unlike sendMessage/fetchMessages.
  // Returns the now-redacted message (body/attachment blanked, deletedAt set) — the caller
  // splices this straight into its local list rather than hand-building the "deleted" shape.
  Future<ChatMessageApiModel> deleteMessage(String tripId, String messageId) async {
    final res = await _client.delete(
      Uri.parse('$baseUrl/trips/$tripId/messages/$messageId'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception('deleteMessage failed: ${res.statusCode} ${res.body}');
    }
    return ChatMessageApiModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // Scope-agnostic by design (no offerId/buddyRequestId) — the backend only needs the caller to
  // be a trip participant, not which chat the resulting message will land in. Upload first, then
  // pass the returned fields into sendMessage above.
  Future<Map<String, dynamic>> uploadAttachment(String tripId, String filePath) async =>
      uploadFile(Uri.parse('$baseUrl/trips/$tripId/messages/attachment'), filePath: filePath, headers: await _authHeaders());

  // Backs the Media ("type=media", image+video) / Files ("type=pdf") tabs in Chat Info — main
  // trip chat only, newest-first, cursor-paginated. One row per attachment (see MediaItemApiModel),
  // not per message — a message can carry several attachments now.
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
      throw Exception('fetchAttachments failed: ${res.statusCode} ${res.body}');
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
      throw Exception('fetchLinks failed: ${res.statusCode} ${res.body}');
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
