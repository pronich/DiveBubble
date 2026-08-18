import 'dart:convert';

import 'package:http/http.dart' as http;

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
    throw Exception('upload failed: ${response.statusCode} ${response.body}');
  }
  return jsonDecode(response.body) as Map<String, dynamic>;
}
