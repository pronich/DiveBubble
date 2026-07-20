import '../../domain/entities/specialty_certification.dart';
import '../services/specialty_api_service.dart';

class SpecialtyRepository {
  SpecialtyRepository({required SpecialtyApiService service}) : _service = service;

  final SpecialtyApiService _service;

  Future<List<SpecialtyCertification>> getAll() => _service.fetchSpecialties();

  Future<SpecialtyCertification> add({
    required String specialty,
    String? customLabel,
    String? agency,
    String? certNumber,
  }) =>
      _service.addSpecialty(specialty: specialty, customLabel: customLabel, agency: agency, certNumber: certNumber);

  Future<void> remove(String id) => _service.removeSpecialty(id);
}
