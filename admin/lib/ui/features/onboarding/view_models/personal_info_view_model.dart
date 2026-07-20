import 'package:flutter/foundation.dart';

import '../../../../data/repositories/profile_repository.dart';
import '../../../../domain/entities/my_profile.dart';
import '../../../core/widgets/pick_image.dart';

class PersonalInfoViewModel extends ChangeNotifier {
  PersonalInfoViewModel({required ProfileRepository repository}) : _repository = repository;

  final ProfileRepository _repository;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _error;
  String? get error => _error;

  MyProfile? _initial;
  MyProfile? get initial => _initial;

  Future<void> load() async {
    try {
      _initial = await _repository.getMe();
    } catch (_) {
      // Best-effort prefill (name/avatar already seeded from Google on account creation) —
      // an empty form still works fine if this fails.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Avatar upload (if any) happens first — it's a standalone endpoint that already
  /// persists avatar_url server-side, so the display-name/location/bio PATCH afterwards
  /// never needs to carry it too.
  Future<bool> submit({required String displayName, String? location, String? bio, PickedImage? avatar}) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      if (avatar != null) {
        await _repository.uploadAvatar(avatar.bytes, avatar.filename);
      }
      await _repository.update(displayName: displayName, location: location, bio: bio);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
