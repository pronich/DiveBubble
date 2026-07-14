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

  Future<List<TripApiModel>> fetchMyTrips() async {
    final res = await _client.get(Uri.parse('$baseUrl/trips/mine'), headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('fetchMyTrips failed: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(res.body) as List<dynamic>;
    return decoded
        .map((e) => TripApiModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> joinTrip(String id) async {
    final res = await _client.post(Uri.parse('$baseUrl/trips/$id/join'), headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('joinTrip failed: ${res.statusCode} ${res.body}');
    }
  }

  Future<TripApiModel> createTrip({
    required String title,
    required String location,
    required DateTime startTime,
    DateTime? endDate,
    String? description,
    String? meetingPoint,
    int? diveCountMin,
    int? diveCountMax,
    int? depthMinM,
    int? depthMaxM,
    String? minCertification,
    int? maxParticipants,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'location': location,
      'startTime': startTime.toUtc().toIso8601String(),
      if (endDate != null) 'endDate': endDate.toUtc().toIso8601String(),
      if (description != null) 'description': description,
      if (meetingPoint != null) 'meetingPoint': meetingPoint,
      if (diveCountMin != null) 'diveCountMin': diveCountMin,
      if (diveCountMax != null) 'diveCountMax': diveCountMax,
      if (depthMinM != null) 'depthMinM': depthMinM,
      if (depthMaxM != null) 'depthMaxM': depthMaxM,
      if (minCertification != null) 'minCertification': minCertification,
      if (maxParticipants != null) 'maxParticipants': maxParticipants,
    };
    final res = await _client.post(
      Uri.parse('$baseUrl/trips'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 201) {
      throw Exception('createTrip failed: ${res.statusCode} ${res.body}');
    }
    return TripApiModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
