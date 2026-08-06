import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/trip_api_model.dart';
import '../models/trip_photo_api_model.dart';
import 'access_token_provider.dart';
import 'auth_required_exception.dart';
import 'multipart_upload.dart';

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

  Future<List<TripApiModel>> fetchTrips({String? query}) async {
    final uri = Uri.parse('$baseUrl/trips').replace(
      queryParameters: (query != null && query.trim().isNotEmpty) ? {'q': query.trim()} : null,
    );
    final res = await _client.get(uri, headers: await _optionalAuthHeaders());
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

  // The marketplace redemption path for business trips (see CLAUDE.md's Booking Code flow
  // section) — no trip id needed, the code alone resolves it. Returns the resolved trip so
  // the caller can navigate straight to it.
  Future<TripApiModel> joinTripByCode(String code) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/trips/join-by-code'),
      headers: {...await _requiredAuthHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode({'code': code}),
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'joinTripByCode failed: ${res.statusCode}');
    }
    return TripApiModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // Server errors come back as {"error": "..."} — surface that message directly instead of the raw body.
  String? _extractError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      // fall through
    }
    return null;
  }

  // 403 (mapped to an Exception here) if the caller is the trip's organizer — they cancel
  // the trip instead of leaving it.
  Future<void> leaveTrip(String id) async {
    final res = await _client.post(Uri.parse('$baseUrl/trips/$id/leave'), headers: await _requiredAuthHeaders());
    if (res.statusCode != 204) {
      throw Exception('leaveTrip failed: ${res.statusCode} ${res.body}');
    }
  }

  // 403 if the caller isn't the trip's organizer. Idempotent server-side — cancelling an
  // already-cancelled trip still returns 204.
  Future<void> cancelTrip(String id) async {
    final res = await _client.post(Uri.parse('$baseUrl/trips/$id/cancel'), headers: await _requiredAuthHeaders());
    if (res.statusCode != 204) {
      throw Exception('cancelTrip failed: ${res.statusCode} ${res.body}');
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

  // Same optional-auth posture as fetchTrip — a trip's gallery is part of its public detail.
  Future<List<TripPhotoApiModel>> fetchTripPhotos(String id) async {
    final res = await _client.get(Uri.parse('$baseUrl/trips/$id/photos'), headers: await _optionalAuthHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchTripPhotos failed: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(res.body) as List<dynamic>;
    return decoded.map((e) => TripPhotoApiModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // 403 if the caller isn't the trip's organizer, 409 if the trip is already at the cap
  // (trip.MaxPhotosPerTrip server-side) — both mapped to a plain Exception here.
  Future<TripPhotoApiModel> addTripPhoto(String id, String filePath) async {
    final json = await uploadImageFile(
      Uri.parse('$baseUrl/trips/$id/photos'),
      filePath: filePath,
      headers: await _requiredAuthHeaders(),
    );
    return TripPhotoApiModel.fromJson(json);
  }

  Future<void> removeTripPhoto(String id, String photoId) async {
    final res = await _client.delete(Uri.parse('$baseUrl/trips/$id/photos/$photoId'), headers: await _requiredAuthHeaders());
    if (res.statusCode != 204) {
      throw Exception('removeTripPhoto failed: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> markRead(String id) async {
    final res = await _client.post(Uri.parse('$baseUrl/trips/$id/read'), headers: await _requiredAuthHeaders());
    if (res.statusCode != 204) {
      throw Exception('markRead failed: ${res.statusCode} ${res.body}');
    }
  }

  Future<bool> getMuted(String id) async {
    final res = await _client.get(Uri.parse('$baseUrl/trips/$id/mute'), headers: await _requiredAuthHeaders());
    if (res.statusCode != 200) {
      throw Exception('getMuted failed: ${res.statusCode} ${res.body}');
    }
    return (jsonDecode(res.body) as Map<String, dynamic>)['muted'] as bool;
  }

  Future<void> muteTrip(String id) async {
    final res = await _client.post(Uri.parse('$baseUrl/trips/$id/mute'), headers: await _requiredAuthHeaders());
    if (res.statusCode != 204) {
      throw Exception('muteTrip failed: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> unmuteTrip(String id) async {
    final res = await _client.delete(Uri.parse('$baseUrl/trips/$id/mute'), headers: await _requiredAuthHeaders());
    if (res.statusCode != 204) {
      throw Exception('unmuteTrip failed: ${res.statusCode} ${res.body}');
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
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'location': location,
      'startTime': startTime.toUtc().toIso8601String(),
      // endDate is a pure calendar date (picked date-only, always local midnight) — .toUtc()
      // on that shifts it into the *previous* UTC day for any positive-offset timezone,
      // which then fails the backend's endDate >= startTime check for same-day trips. Build
      // a fresh UTC-midnight DateTime from the Y/M/D instead of converting the local one.
      if (endDate != null) 'endDate': DateTime.utc(endDate.year, endDate.month, endDate.day).toIso8601String(),
      if (description != null) 'description': description,
      if (meetingPoint != null) 'meetingPoint': meetingPoint,
      if (diveCountMin != null) 'diveCountMin': diveCountMin,
      if (diveCountMax != null) 'diveCountMax': diveCountMax,
      if (depthMinM != null) 'depthMinM': depthMinM,
      if (depthMaxM != null) 'depthMaxM': depthMaxM,
      if (minCertification != null) 'minCertification': minCertification,
      if (maxParticipants != null) 'maxParticipants': maxParticipants,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
    final res = await _client.post(
      Uri.parse('$baseUrl/trips'),
      headers: {...await _requiredAuthHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 201) {
      throw Exception(_extractError(res.body) ?? 'createTrip failed: ${res.statusCode}');
    }
    return TripApiModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
