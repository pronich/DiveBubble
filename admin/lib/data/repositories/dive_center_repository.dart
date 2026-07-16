import '../../domain/entities/dive_center.dart';
import '../../domain/entities/dive_center_member.dart';
import '../mappers/dive_center_api_mapper.dart';
import '../services/dive_center_api_service.dart';

class DiveCenterRepository {
  DiveCenterRepository({required DiveCenterApiService service}) : _service = service;

  final DiveCenterApiService _service;

  Future<List<DiveCenter>> getMine() async {
    final apiModels = await _service.fetchMine();
    return apiModels.map((m) => m.toDomain()).toList();
  }

  Future<DiveCenter> getById(String id) async {
    final apiModel = await _service.fetchById(id);
    return apiModel.toDomain();
  }

  Future<DiveCenter> create({
    required String name,
    String? location,
    String? description,
    String? agency,
    String? agencyDetail,
    String? languages,
    String? website,
    String? phone,
  }) async {
    final apiModel = await _service.create(
      name: name,
      location: location,
      description: description,
      agency: agency,
      agencyDetail: agencyDetail,
      languages: languages,
      website: website,
      phone: phone,
    );
    return apiModel.toDomain();
  }

  Future<DiveCenter> update(
    String id, {
    String? name,
    String? location,
    String? description,
    String? agency,
    String? agencyDetail,
    String? languages,
    String? website,
    String? phone,
    String? email,
  }) async {
    final apiModel = await _service.update(
      id,
      name: name,
      location: location,
      description: description,
      agency: agency,
      agencyDetail: agencyDetail,
      languages: languages,
      website: website,
      phone: phone,
      email: email,
    );
    return apiModel.toDomain();
  }

  Future<String> uploadLogo(String id, List<int> bytes, String filename) => _service.uploadLogo(id, bytes, filename);

  Future<List<DiveCenterMember>> getMembers(String diveCenterId) => _service.fetchMembers(diveCenterId);

  Future<MemberPreview> searchMemberByEmail(String diveCenterId, String email) =>
      _service.searchMemberByEmail(diveCenterId, email);

  Future<void> addMember(String diveCenterId, String userId, String role) =>
      _service.addMember(diveCenterId, userId, role);

  Future<void> removeMember(String diveCenterId, String userId) => _service.removeMember(diveCenterId, userId);
}
