import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// Stub identity — persisted client-generated id, no real auth yet.
class UserIdentityService {
  static const _key = 'device_user_id';

  Future<String> getOrCreateId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null) return existing;

    final id = const Uuid().v4();
    await prefs.setString(_key, id);
    return id;
  }
}
