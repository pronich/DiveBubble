import '../../domain/entities/my_profile.dart';
import '../services/profile_api_service.dart';

class ProfileRepository {
  ProfileRepository({required ProfileApiService service}) : _service = service;

  final ProfileApiService _service;

  Future<MyProfile> getMe() => _service.fetchMe();
}
