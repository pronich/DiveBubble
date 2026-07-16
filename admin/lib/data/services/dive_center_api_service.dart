import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/dive_center_api_model.dart';
import 'access_token_provider.dart';
import 'auth_required_exception.dart';
import 'multipart_upload.dart';

class DiveCenterApiService {
  DiveCenterApiService({required this.baseUrl, required this.getAccessToken, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final AccessTokenProvider getAccessToken;
  final http.Client _client;

  Future<Map<String, String>> _authHeaders() async {
    final token = await getAccessToken();
    if (token == null) throw const AuthRequiredException();
    return {'Authorization': 'Bearer $token'};
  }

  Future<List<DiveCenterApiModel>> fetchMine() async {
    final res = await _client.get(Uri.parse('$baseUrl/dive-centers/mine'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchMine failed: ${res.statusCode} ${res.body}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => DiveCenterApiModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DiveCenterApiModel> fetchById(String id) async {
    final res = await _client.get(Uri.parse('$baseUrl/dive-centers/$id'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchById failed: ${res.statusCode} ${res.body}');
    }
    return DiveCenterApiModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<DiveCenterApiModel> create({
    required String name,
    String? location,
    String? description,
    String? agency,
    String? agencyDetail,
    String? languages,
    String? website,
    String? phone,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      if (location != null) 'location': location,
      if (description != null) 'description': description,
      if (agency != null) 'agency': agency,
      if (agencyDetail != null) 'agencyDetail': agencyDetail,
      if (languages != null) 'languages': languages,
      if (website != null) 'website': website,
      if (phone != null) 'phone': phone,
    };
    final res = await _client.post(
      Uri.parse('$baseUrl/dive-centers'),
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 201) {
      throw Exception('create failed: ${res.statusCode} ${res.body}');
    }
    return DiveCenterApiModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<String> uploadLogo(String id, List<int> bytes, String filename) async {
    final json = await uploadImageBytes(
      Uri.parse('$baseUrl/dive-centers/$id/logo'),
      bytes: bytes,
      filename: filename,
      headers: await _authHeaders(),
    );
    return json['logoUrl'] as String;
  }
}
