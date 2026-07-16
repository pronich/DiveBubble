import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/transport_offer.dart';
import 'access_token_provider.dart';
import 'auth_required_exception.dart';

// Staff only ever creates/lists offers and looks at who joined — never "joins" one
// themselves, unlike app/'s own TransportApiService, so there's no joinOffer/getHasAlert here.
class TransportApiService {
  TransportApiService({required this.baseUrl, required this.getAccessToken, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final AccessTokenProvider getAccessToken;
  final http.Client _client;

  Future<Map<String, String>> _authHeaders() async {
    final token = await getAccessToken();
    if (token == null) throw const AuthRequiredException();
    return {'Authorization': 'Bearer $token'};
  }

  Future<List<TransportOffer>> fetchOffers(String tripId) async {
    final res = await _client.get(Uri.parse('$baseUrl/trips/$tripId/transport'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchOffers failed: ${res.statusCode} ${res.body}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => TransportOffer.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TransportOffer> createOffer(String tripId, {required String type, int? seats, String? details}) async {
    final body = <String, dynamic>{
      'type': type,
      if (seats != null) 'seats': seats,
      if (details != null) 'details': details,
    };
    final res = await _client.post(
      Uri.parse('$baseUrl/trips/$tripId/transport'),
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 201) {
      throw Exception('createOffer failed: ${res.statusCode} ${res.body}');
    }
    return TransportOffer.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<String>> fetchJoinedUserIds(String tripId, String offerId) async {
    final res = await _client.get(
      Uri.parse('$baseUrl/trips/$tripId/transport/$offerId/joins'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception('fetchJoinedUserIds failed: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(res.body) as List<dynamic>;
    return decoded.map((e) => (e as Map<String, dynamic>)['userId'] as String).toList();
  }
}
