import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/dive_log_entry.dart';
import 'access_token_provider.dart';
import 'auth_required_exception.dart';
import 'multipart_upload.dart';

class DiveLogApiService {
  DiveLogApiService({required this.baseUrl, required this.getAccessToken, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final AccessTokenProvider getAccessToken;
  final http.Client _client;

  Future<Map<String, String>> _authHeaders() async {
    final token = await getAccessToken();
    if (token == null) throw const AuthRequiredException();
    return {'Authorization': 'Bearer $token'};
  }

  String? _extractError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      // fall through
    }
    return null;
  }

  Future<List<DiveLogEntry>> fetchEntries() async {
    final res = await _client.get(Uri.parse('$baseUrl/divelog'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchEntries failed: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(res.body) as List<dynamic>;
    return decoded.map((e) => DiveLogEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DiveLogEntry> createEntry({
    required DateTime divedAt,
    double? maxDepthM,
    int? durationMinutes,
    double? minTemperatureC,
    String? siteName,
    String? notes,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/divelog'),
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'divedAt': divedAt.toUtc().toIso8601String(),
        if (maxDepthM != null) 'maxDepthM': maxDepthM,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        if (minTemperatureC != null) 'minTemperatureC': minTemperatureC,
        if (siteName != null) 'siteName': siteName,
        if (notes != null) 'notes': notes,
      }),
    );
    if (res.statusCode != 201) {
      throw Exception(_extractError(res.body) ?? 'createEntry failed: ${res.statusCode}');
    }
    return DiveLogEntry.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<DiveLogEntry> updateEntry(
    String id, {
    required DateTime divedAt,
    double? maxDepthM,
    int? durationMinutes,
    double? minTemperatureC,
    String? siteName,
    String? notes,
  }) async {
    final res = await _client.put(
      Uri.parse('$baseUrl/divelog/$id'),
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'divedAt': divedAt.toUtc().toIso8601String(),
        if (maxDepthM != null) 'maxDepthM': maxDepthM,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        if (minTemperatureC != null) 'minTemperatureC': minTemperatureC,
        if (siteName != null) 'siteName': siteName,
        if (notes != null) 'notes': notes,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'updateEntry failed: ${res.statusCode}');
    }
    return DiveLogEntry.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<DiveLogImportResult> importUDDF(String filePath) async {
    final token = await getAccessToken();
    if (token == null) throw const AuthRequiredException();
    try {
      final body = await uploadFile(
        Uri.parse('$baseUrl/divelog/import'),
        filePath: filePath,
        headers: {'Authorization': 'Bearer $token'},
      );
      return DiveLogImportResult.fromJson(body);
    } catch (e) {
      // uploadFile's own exception message embeds the raw response body after "NNN " —
      // pull the {"error": "..."} JSON back out of it for a readable message instead of
      // surfacing the whole "Exception: upload failed: 400 {...}" wrapper string.
      final message = e.toString();
      final jsonStart = message.indexOf('{');
      throw Exception(
        (jsonStart != -1 ? _extractError(message.substring(jsonStart)) : null) ??
            'Could not import dive log',
      );
    }
  }

  Future<void> deleteEntry(String id) async {
    final res = await _client.delete(
      Uri.parse('$baseUrl/divelog/$id'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 204) {
      throw Exception(_extractError(res.body) ?? 'deleteEntry failed: ${res.statusCode}');
    }
  }
}
