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

  Future<List<Trip>> getMyTrips() async {
    final apiModels = await _service.fetchMyTrips();
    return apiModels.map((m) => m.toDomain()).toList();
  }
}
