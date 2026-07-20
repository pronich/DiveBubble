import '../../domain/entities/my_profile.dart';
import '../services/profile_api_service.dart';

class ProfileRepository {
  ProfileRepository({required ProfileApiService service}) : _service = service;

  final ProfileApiService _service;

  Future<MyProfile> getMe() => _service.fetchMe();

  Future<MyProfile> getById(String userId) => _service.fetchById(userId);

  Future<MyProfile> update({
    String? displayName,
    String? location,
    String? bio,
    int? diveCount,
    String? certificationLevel,
    String? certificationAgency,
    String? certificationNumber,
    String? languages,
  }) =>
      _service.updateProfile(
        displayName: displayName,
        location: location,
        bio: bio,
        diveCount: diveCount,
        certificationLevel: certificationLevel,
        certificationAgency: certificationAgency,
        certificationNumber: certificationNumber,
        languages: languages,
      );

  Future<MyProfile> uploadAvatar(List<int> bytes, String filename) => _service.uploadAvatar(bytes, filename);
}
