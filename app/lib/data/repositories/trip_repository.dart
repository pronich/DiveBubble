import '../../domain/entities/trip.dart';
import '../../domain/entities/trip_photo.dart';
import '../mappers/trip_api_mapper.dart';
import '../mappers/trip_photo_api_mapper.dart';
import '../services/trip_api_service.dart';

class TripRepository {
  TripRepository({required TripApiService service}) : _service = service;

  final TripApiService _service;

  Future<List<Trip>> getTrips({String? query}) async {
    final apiModels = await _service.fetchTrips(query: query);
    return apiModels.map((m) => m.toDomain()).toList();
  }

  Future<Trip> getTrip(String id) async {
    final apiModel = await _service.fetchTrip(id);
    return apiModel.toDomain();
  }

  Future<void> joinTrip(String id) => _service.joinTrip(id);

  Future<Trip> joinTripByCode(String code) async {
    final apiModel = await _service.joinTripByCode(code);
    return apiModel.toDomain();
  }

  Future<Trip> resolveTripByCode(String code) async {
    final apiModel = await _service.resolveTripByCode(code);
    return apiModel.toDomain();
  }

  Future<void> leaveTrip(String id) => _service.leaveTrip(id);

  Future<void> cancelTrip(String id) => _service.cancelTrip(id);

  Future<List<String>> getParticipantUserIds(String id) => _service.fetchParticipantUserIds(id);

  Future<void> markRead(String id) => _service.markRead(id);

  Future<bool> getMuted(String id) => _service.getMuted(id);

  Future<void> muteTrip(String id) => _service.muteTrip(id);

  Future<void> unmuteTrip(String id) => _service.unmuteTrip(id);

  Future<List<TripPhoto>> getTripPhotos(String id) async {
    final apiModels = await _service.fetchTripPhotos(id);
    return apiModels.map((m) => m.toDomain()).toList();
  }

  Future<TripPhoto> addTripPhoto(String id, String filePath) async {
    final apiModel = await _service.addTripPhoto(id, filePath);
    return apiModel.toDomain();
  }

  Future<void> removeTripPhoto(String id, String photoId) => _service.removeTripPhoto(id, photoId);

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
    double? latitude,
    double? longitude,
    bool isPrivate = false,
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
      latitude: latitude,
      longitude: longitude,
      isPrivate: isPrivate,
    );
    return apiModel.toDomain();
  }

  Future<Trip> updateTrip({
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
    double? latitude,
    double? longitude,
  }) async {
    final apiModel = await _service.updateTrip(
      id: id,
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
      latitude: latitude,
      longitude: longitude,
    );
    return apiModel.toDomain();
  }
}
