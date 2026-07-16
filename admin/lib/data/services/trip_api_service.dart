import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/trip_api_model.dart';
import 'access_token_provider.dart';
import 'auth_required_exception.dart';

/// Trimmed to what admin/ actually needs — no join/leave/cancel/participants here, those
/// stay diver-facing actions in app/. Business trip creation/listing only.
class TripApiService {
  TripApiService({required this.baseUrl, required this.getAccessToken, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final AccessTokenProvider getAccessToken;
  final http.Client _client;

  Future<Map<String, String>> _authHeaders() async {
    final token = await getAccessToken();
    if (token == null) throw const AuthRequiredException();
    return {'Authorization': 'Bearer $token'};
  }

  // GET /trips/mine already includes every trip a dive-center member has access to (see
  // trip.Repository.ListJoinedByUser's dive_center_members branch) — no separate
  // "list this dive center's trips" endpoint exists or is needed.
  Future<List<TripApiModel>> fetchMyTrips() async {
    final res = await _client.get(Uri.parse('$baseUrl/trips/mine'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchMyTrips failed: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(res.body) as List<dynamic>;
    return decoded.map((e) => TripApiModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TripApiModel> createTrip({
    required String title,
    required String location,
    required DateTime startTime,
    required String diveCenterId,
    DateTime? endDate,
    String? description,
    String? meetingPoint,
    int? diveCountMin,
    int? diveCountMax,
    int? depthMinM,
    int? depthMaxM,
    String? minCertification,
    int? maxParticipants,
    int? priceMinor,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'location': location,
      'startTime': startTime.toUtc().toIso8601String(),
      'diveCenterId': diveCenterId,
      if (endDate != null) 'endDate': endDate.toUtc().toIso8601String(),
      if (description != null) 'description': description,
      if (meetingPoint != null) 'meetingPoint': meetingPoint,
      if (diveCountMin != null) 'diveCountMin': diveCountMin,
      if (diveCountMax != null) 'diveCountMax': diveCountMax,
      if (depthMinM != null) 'depthMinM': depthMinM,
      if (depthMaxM != null) 'depthMaxM': depthMaxM,
      if (minCertification != null) 'minCertification': minCertification,
      if (maxParticipants != null) 'maxParticipants': maxParticipants,
      if (priceMinor != null) 'priceMinor': priceMinor,
    };
    final res = await _client.post(
      Uri.parse('$baseUrl/trips'),
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 201) {
      throw Exception('createTrip failed: ${res.statusCode} ${res.body}');
    }
    return TripApiModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // diveCenterId isn't here — ownership doesn't change via an edit (see trip.UpdateParams'
  // own comment on the backend). Every other field is nullable/optional, matching PATCH
  // semantics: only fields present in the body get changed.
  Future<TripApiModel> updateTrip({
    required String id,
    String? title,
    String? location,
    DateTime? startTime,
    DateTime? endDate,
    String? description,
    String? meetingPoint,
    int? diveCountMin,
    int? diveCountMax,
    int? depthMinM,
    int? depthMaxM,
    String? minCertification,
    int? maxParticipants,
    int? priceMinor,
  }) async {
    final body = <String, dynamic>{
      if (title != null) 'title': title,
      if (location != null) 'location': location,
      if (startTime != null) 'startTime': startTime.toUtc().toIso8601String(),
      if (endDate != null) 'endDate': endDate.toUtc().toIso8601String(),
      if (description != null) 'description': description,
      if (meetingPoint != null) 'meetingPoint': meetingPoint,
      if (diveCountMin != null) 'diveCountMin': diveCountMin,
      if (diveCountMax != null) 'diveCountMax': diveCountMax,
      if (depthMinM != null) 'depthMinM': depthMinM,
      if (depthMaxM != null) 'depthMaxM': depthMaxM,
      if (minCertification != null) 'minCertification': minCertification,
      if (maxParticipants != null) 'maxParticipants': maxParticipants,
      if (priceMinor != null) 'priceMinor': priceMinor,
    };
    final res = await _client.patch(
      Uri.parse('$baseUrl/trips/$id'),
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      throw Exception('updateTrip failed: ${res.statusCode} ${res.body}');
    }
    return TripApiModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
