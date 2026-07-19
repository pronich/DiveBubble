import '../services/push_api_service.dart';

class PushRepository {
  PushRepository({required PushApiService service}) : _service = service;

  final PushApiService _service;

  Future<void> registerToken({required String token, required String platform}) =>
      _service.registerToken(token: token, platform: platform);

  Future<void> unregisterToken(String token) => _service.unregisterToken(token);
}
