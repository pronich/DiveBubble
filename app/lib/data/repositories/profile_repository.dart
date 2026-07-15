import '../../domain/entities/profile.dart';
import '../mappers/profile_api_mapper.dart';
import '../services/profile_api_service.dart';

class ProfileRepository {
  ProfileRepository({required ProfileApiService service}) : _service = service;

  final ProfileApiService _service;

  Future<Profile> getProfile() async {
    final apiModel = await _service.fetchProfile();
    return apiModel.toDomain();
  }

  Future<Profile> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? location,
    String? bio,
    int? diveCount,
    String? certificationLevel,
    String? certificationAgency,
    String? certificationNumber,
    String? languages,
  }) async {
    final apiModel = await _service.updateProfile(
      displayName: displayName,
      avatarUrl: avatarUrl,
      location: location,
      bio: bio,
      diveCount: diveCount,
      certificationLevel: certificationLevel,
      certificationAgency: certificationAgency,
      certificationNumber: certificationNumber,
      languages: languages,
    );
    return apiModel.toDomain();
  }
}
