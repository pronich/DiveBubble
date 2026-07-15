import '../../domain/entities/specialty_certification.dart';
import '../mappers/specialty_certification_api_mapper.dart';
import '../services/specialty_api_service.dart';

class SpecialtyRepository {
  SpecialtyRepository({required SpecialtyApiService service}) : _service = service;

  final SpecialtyApiService _service;

  Future<List<SpecialtyCertification>> fetchSpecialties() async {
    final apiModels = await _service.fetchSpecialties();
    return apiModels.map((m) => m.toDomain()).toList();
  }

  Future<SpecialtyCertification> addSpecialty({
    required String specialty,
    String? customLabel,
    String? agency,
    String? certNumber,
  }) async {
    final apiModel = await _service.addSpecialty(
      specialty: specialty,
      customLabel: customLabel,
      agency: agency,
      certNumber: certNumber,
    );
    return apiModel.toDomain();
  }

  Future<void> removeSpecialty(String id) => _service.removeSpecialty(id);
}
