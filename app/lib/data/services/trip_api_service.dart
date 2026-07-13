import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/trip_api_model.dart';

class TripApiService {
  TripApiService({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<List<TripApiModel>> fetchTrips() async {
    final res = await _client.get(Uri.parse('$baseUrl/trips'));
    if (res.statusCode != 200) {
      throw Exception('fetchTrips failed: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(res.body) as List<dynamic>;
    return decoded
        .map((e) => TripApiModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
