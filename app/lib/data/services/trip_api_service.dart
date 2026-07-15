import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/trip_api_model.dart';
import 'access_token_provider.dart';
import 'auth_required_exception.dart';

class TripApiService {
  TripApiService({required this.baseUrl, required this.getAccessToken, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final AccessTokenProvider getAccessToken;
  final http.Client _client;

  // Trip detail stays browsable without an account — attach a token if signed in
  // (personalizes "joined"), but don't require one.
  Future<Map<String, String>> _optionalAuthHeaders() async {
    final token = await getAccessToken();
    return token == null ? {} : {'Authorization': 'Bearer $token'};
  }

  Future<Map<String, String>> _requiredAuthHeaders() async {
    final token = await getAccessToken();
    if (token == null) throw const AuthRequiredException();
    return {'Authorization': 'Bearer $token'};
  }

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

  Future<TripApiModel> fetchTrip(String id) async {
    final res = await _client.get(Uri.parse('$baseUrl/trips/$id'), headers: await _optionalAuthHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchTrip failed: ${res.statusCode} ${res.body}');
    }
    return TripApiModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<TripApiModel>> fetchMyTrips() async {
    final res = await _client.get(Uri.parse('$baseUrl/trips/mine'), headers: await _requiredAuthHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchMyTrips failed: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(res.body) as List<dynamic>;
    return decoded
        .map((e) => TripApiModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> joinTrip(String id) async {
    final res = await _client.post(Uri.parse('$baseUrl/trips/$id/join'), headers: await _requiredAuthHeaders());
    if (res.statusCode != 200) {
      throw Exception('joinTrip failed: ${res.statusCode} ${res.body}');
    }
  }

  // 403 (mapped to an Exception here) if the caller is the trip's organizer — they cancel
  // the trip instead of leaving it.
  Future<void> leaveTrip(String id) async {
    final res = await _client.post(Uri.parse('$baseUrl/trips/$id/leave'), headers: await _requiredAuthHeaders());
    if (res.statusCode != 204) {
      throw Exception('leaveTrip failed: ${res.statusCode} ${res.body}');
    }
  }

  // Gated to participants server-side — who joined a trip isn't public.
  Future<List<String>> fetchParticipantUserIds(String id) async {
    final res = await _client.get(Uri.parse('$baseUrl/trips/$id/participants'), headers: await _requiredAuthHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchParticipantUserIds failed: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(res.body) as List<dynamic>;
    return decoded.cast<String>();
  }

  Future<void> markRead(String id) async {
    final res = await _client.post(Uri.parse('$baseUrl/trips/$id/read'), headers: await _requiredAuthHeaders());
    if (res.statusCode != 204) {
      throw Exception('markRead failed: ${res.statusCode} ${res.body}');
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
      headers: {...await _requiredAuthHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 201) {
      throw Exception('createTrip failed: ${res.statusCode} ${res.body}');
    }
    return TripApiModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
