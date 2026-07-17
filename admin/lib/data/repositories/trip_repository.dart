import '../../domain/entities/trip.dart';
import '../../domain/entities/trip_photo.dart';
import '../mappers/trip_api_mapper.dart';
import '../services/trip_api_service.dart';

class TripRepository {
  TripRepository({required TripApiService service}) : _service = service;

  final TripApiService _service;

  Future<List<Trip>> getMyTrips() async {
    final apiModels = await _service.fetchMyTrips();
    return apiModels.map((m) => m.toDomain()).toList();
  }

  Future<Trip> createTrip({
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
    String? bookingUrl,
  }) async {
    final apiModel = await _service.createTrip(
      title: title,
      location: location,
      startTime: startTime,
      diveCenterId: diveCenterId,
      endDate: endDate,
      description: description,
      meetingPoint: meetingPoint,
      diveCountMin: diveCountMin,
      diveCountMax: diveCountMax,
      depthMinM: depthMinM,
      depthMaxM: depthMaxM,
      minCertification: minCertification,
      maxParticipants: maxParticipants,
      priceMinor: priceMinor,
      bookingUrl: bookingUrl,
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
    int? priceMinor,
    String? bookingUrl,
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
      priceMinor: priceMinor,
      bookingUrl: bookingUrl,
    );
    return apiModel.toDomain();
  }

  Future<void> markRead(String tripId) => _service.markRead(tripId);

  Future<void> cancelTrip(String tripId) => _service.cancelTrip(tripId);

  Future<List<TripPhoto>> getTripPhotos(String tripId) => _service.fetchTripPhotos(tripId);

  Future<TripPhoto> addTripPhoto(String tripId, List<int> bytes, String filename) =>
      _service.addTripPhoto(tripId, bytes, filename);

  Future<void> removeTripPhoto(String tripId, String photoId) => _service.removeTripPhoto(tripId, photoId);
}
