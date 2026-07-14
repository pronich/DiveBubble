import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/transport_offer_api_model.dart';

class TransportApiService {
  TransportApiService({required this.baseUrl, required this.userId, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final String userId;
  final http.Client _client;

  Map<String, String> get _headers => {'X-User-Id': userId};

  Future<List<TransportOfferApiModel>> fetchOffers(String tripId) async {
    final res = await _client.get(Uri.parse('$baseUrl/trips/$tripId/transport'), headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('fetchOffers failed: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(res.body) as List<dynamic>;
    return decoded
        .map((e) => TransportOfferApiModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TransportOfferApiModel> createOffer(
    String tripId, {
    required String type,
    int? seats,
    String? details,
  }) async {
    final body = <String, dynamic>{
      'type': type,
      if (seats != null) 'seats': seats,
      if (details != null) 'details': details,
    };
    final res = await _client.post(
      Uri.parse('$baseUrl/trips/$tripId/transport'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 201) {
      throw Exception('createOffer failed: ${res.statusCode} ${res.body}');
    }
    return TransportOfferApiModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
