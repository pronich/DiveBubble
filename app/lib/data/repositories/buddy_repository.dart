import '../../domain/entities/buddy_request.dart';
import '../mappers/buddy_request_api_mapper.dart';
import '../services/buddy_api_service.dart';

class BuddyRepository {
  BuddyRepository({required BuddyApiService service}) : _service = service;

  final BuddyApiService _service;

  Future<List<BuddyRequest>> getRequests(String tripId) async {
    final apiModels = await _service.fetchRequests(tripId);
    return apiModels.map((m) => m.toDomain()).toList();
  }

  Future<BuddyRequest> createRequest(String tripId) async {
    final apiModel = await _service.createRequest(tripId);
    return apiModel.toDomain();
  }

  Future<void> joinRequest(String tripId, String requestId) => _service.joinRequest(tripId, requestId);

  Future<List<String>> getJoinedUserIds(String tripId, String requestId) =>
      _service.fetchJoinedUserIds(tripId, requestId);

  Future<void> leaveRequest(String tripId, String requestId) => _service.leaveRequest(tripId, requestId);

  Future<void> dissolveRequest(String tripId, String requestId) => _service.dissolveRequest(tripId, requestId);

  Future<bool> getHasAlert(String tripId) => _service.fetchHasAlert(tripId);
}
