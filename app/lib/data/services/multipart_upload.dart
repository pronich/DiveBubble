import 'dart:convert';

import 'package:http/http.dart' as http;

import 'error_codes.dart';

/// Not image-specific despite older call sites' names — nothing here assumes the file is an image.
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
