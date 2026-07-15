import '../../domain/entities/gear_ownership.dart';
import '../mappers/gear_ownership_api_mapper.dart';
import '../services/gear_api_service.dart';

class GearRepository {
  GearRepository({required GearApiService service}) : _service = service;

  final GearApiService _service;

  Future<List<GearOwnership>> fetchGear() async {
    final apiModels = await _service.fetchGear();
    return apiModels.map((m) => m.toDomain()).toList();
  }

  Future<GearOwnership> setGearStatus({required String itemKey, required String status}) async {
    final apiModel = await _service.setGearStatus(itemKey: itemKey, status: status);
    return apiModel.toDomain();
  }

  Future<void> deleteGear(String itemKey) => _service.deleteGear(itemKey);
}
