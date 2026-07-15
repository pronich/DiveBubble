import '../../domain/entities/trip.dart';
import '../mappers/trip_api_mapper.dart';
import '../services/trip_api_service.dart';

class TripRepository {
  TripRepository({required TripApiService service}) : _service = service;

  final TripApiService _service;

  Future<List<Trip>> getTrips() async {
    final apiModels = await _service.fetchTrips();
    return apiModels.map((m) => m.toDomain()).toList();
  }

  Future<Trip> getTrip(String id) async {
    final apiModel = await _service.fetchTrip(id);
    return apiModel.toDomain();
  }

  Future<void> joinTrip(String id) => _service.joinTrip(id);

  Future<void> leaveTrip(String id) => _service.leaveTrip(id);

  Future<void> cancelTrip(String id) => _service.cancelTrip(id);

  Future<List<String>> getParticipantUserIds(String id) => _service.fetchParticipantUserIds(id);

  Future<void> markRead(String id) => _service.markRead(id);

  Future<String> uploadTripPhoto(String id, String filePath) => _service.uploadTripPhoto(id, filePath);

  Future<List<Trip>> getMyTrips() async {
    final apiModels = await _service.fetchMyTrips();
    return apiModels.map((m) => m.toDomain()).toList();
  }

  Future<Trip> createTrip({
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
    final apiModel = await _service.createTrip(
      title: title,
      location: location,
      startTime: startTime,
      endDate: endDate,
      description: description,
      meetingPoint: meetingPoint,
      diveCountMin: diveCountMin,
      diveCountMax: diveCountMax,
      depthMinM: depthMinM,
      depthMaxM: depthMaxM,
      minCertification: minCertification,
      maxParticipants: maxParticipants,
    );
    return apiModel.toDomain();
  }
}
