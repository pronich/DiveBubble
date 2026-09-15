import 'dart:convert';

import 'package:http/http.dart' as http;

import 'error_codes.dart';

/// Shared by every multipart file-upload call site (avatar, trip photo, certification/specialty
/// photos, chat attachments) — one multipart POST with a single "file" field, matching the
/// backend's upload.Service.Save/SaveAttachment contract. Returns the decoded JSON body on
/// success. Not image-specific despite older call sites' names — nothing here assumes the file
/// is an image.
Future<Map<String, dynamic>> uploadFile(
  Uri uri, {
  required String filePath,
  required Map<String, String> headers,
}) async {
  final request = http.MultipartRequest('POST', uri)
    ..headers.addAll(headers)
    ..files.add(await http.MultipartFile.fromPath('file', filePath));
  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);
  if (response.statusCode != 200) {
    throw Exception(_extractError(response.body) ?? 'upload failed: ${response.statusCode}');
  }
  return jsonDecode(response.body) as Map<String, dynamic>;
}

// Server errors come back as {"error": "<code>"} — describeErrorCode maps the code to a
// message to show, or passes it through unchanged if it's not one this file knows about yet.
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
