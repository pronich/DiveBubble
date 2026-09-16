import 'dart:convert';

import 'package:http/http.dart' as http;

/// Bytes-based, not path-based like app/'s equivalent — this is web-only, and image_picker's web XFile gives only a blob URI readable via readAsBytes(), not a real filesystem path.
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
