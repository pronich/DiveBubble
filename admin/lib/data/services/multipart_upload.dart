import 'dart:convert';

import 'package:http/http.dart' as http;

/// Bytes-based, not path-based (unlike app/'s equivalent) — this is a web-only build, and
/// there's no real filesystem to read an `XFile.path` from; `image_picker` on web gives you
/// a blob URI you can only get at via `readAsBytes()`. Every upload call site collects
/// bytes + a filename from `image_picker`'s `XFile` before calling this.
Future<Map<String, dynamic>> uploadImageBytes(
  Uri uri, {
  required List<int> bytes,
  required String filename,
  required Map<String, String> headers,
}) async {
  final request = http.MultipartRequest('POST', uri)
    ..headers.addAll(headers)
    ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);
  if (response.statusCode != 200) {
    throw Exception('upload failed: ${response.statusCode} ${response.body}');
  }
  return jsonDecode(response.body) as Map<String, dynamic>;
}
