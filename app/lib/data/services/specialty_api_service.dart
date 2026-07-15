import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/specialty_certification_api_model.dart';
import 'access_token_provider.dart';
import 'auth_required_exception.dart';

class SpecialtyApiService {
  SpecialtyApiService({required this.baseUrl, required this.getAccessToken, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final AccessTokenProvider getAccessToken;
  final http.Client _client;

  Future<Map<String, String>> _authHeaders() async {
    final token = await getAccessToken();
    if (token == null) throw const AuthRequiredException();
    return {'Authorization': 'Bearer $token'};
  }

  Future<List<SpecialtyCertificationApiModel>> fetchSpecialties() async {
    final res = await _client.get(Uri.parse('$baseUrl/me/specialties'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchSpecialties failed: ${res.statusCode} ${res.body}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => SpecialtyCertificationApiModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SpecialtyCertificationApiModel> addSpecialty({
    required String specialty,
    String? customLabel,
    String? agency,
    String? certNumber,
  }) async {
    final body = <String, dynamic>{
      'specialty': specialty,
      if (customLabel != null) 'customLabel': customLabel,
      if (agency != null) 'agency': agency,
      if (certNumber != null) 'certNumber': certNumber,
    };
    final res = await _client.post(
      Uri.parse('$baseUrl/me/specialties'),
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 201) {
      throw Exception('addSpecialty failed: ${res.statusCode} ${res.body}');
    }
    return SpecialtyCertificationApiModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> removeSpecialty(String id) async {
    final res = await _client.delete(
      Uri.parse('$baseUrl/me/specialties/$id'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 204) {
      throw Exception('removeSpecialty failed: ${res.statusCode} ${res.body}');
    }
  }
}
