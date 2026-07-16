import '../../domain/entities/dive_center.dart';
import '../mappers/dive_center_api_mapper.dart';
import '../services/dive_center_api_service.dart';

class DiveCenterRepository {
  DiveCenterRepository({required DiveCenterApiService service}) : _service = service;

  final DiveCenterApiService _service;

  Future<DiveCenter> getById(String id) async {
    final apiModel = await _service.fetchById(id);
    return apiModel.toDomain();
  }

  Future<bool> isMember(String id) => _service.fetchIsMember(id);
}
