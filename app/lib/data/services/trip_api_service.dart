import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/trip_api_model.dart';

class TripApiService {
  TripApiService({required this.baseUrl, required this.userId, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final String userId;
  final http.Client _client;

  Map<String, String> get _headers => {'X-User-Id': userId};

  Future<List<TripApiModel>> fetchTrips() async {
    final res = await _client.get(Uri.parse('$baseUrl/trips'), headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('fetchTrips failed: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(res.body) as List<dynamic>;
    return decoded
        .map((e) => TripApiModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TripApiModel> fetchTrip(String id) async {
    final res = await _client.get(Uri.parse('$baseUrl/trips/$id'), headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('fetchTrip failed: ${res.statusCode} ${res.body}');
    }
    return TripApiModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> joinTrip(String id) async {
    final res = await _client.post(Uri.parse('$baseUrl/trips/$id/join'), headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('joinTrip failed: ${res.statusCode} ${res.body}');
    }
  }
}
