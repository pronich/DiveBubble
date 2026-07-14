import 'package:flutter/foundation.dart';

import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/services/auth_required_exception.dart';
import '../../../../domain/entities/profile.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({required ProfileRepository repository}) : _repository = repository;

  final ProfileRepository _repository;

  Profile? _profile;
  Profile? get profile => _profile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _error;
  String? get error => _error;

  bool _needsSignIn = false;
  bool get needsSignIn => _needsSignIn;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    _needsSignIn = false;
    notifyListeners();

    try {
      _profile = await _repository.getProfile();
    } on AuthRequiredException {
      _needsSignIn = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submit({
    required String displayName,
    required String location,
    required String bio,
    required int diveCount,
    required String certificationLevel,
    required String languages,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      _profile = await _repository.updateProfile(
        displayName: displayName,
        location: location,
        bio: bio,
        diveCount: diveCount,
        certificationLevel: certificationLevel,
        languages: languages,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
