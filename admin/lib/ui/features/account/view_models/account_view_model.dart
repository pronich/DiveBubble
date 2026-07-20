import 'package:flutter/foundation.dart';

import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/specialty_repository.dart';
import '../../../../domain/entities/my_profile.dart';
import '../../../../domain/entities/specialty_certification.dart';
import '../../../core/widgets/pick_image.dart';

class AccountViewModel extends ChangeNotifier {
  AccountViewModel({required ProfileRepository profileRepository, required SpecialtyRepository specialtyRepository})
      : _profileRepository = profileRepository,
        _specialtyRepository = specialtyRepository;

  final ProfileRepository _profileRepository;
  final SpecialtyRepository _specialtyRepository;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  MyProfile? _profile;
  MyProfile? get profile => _profile;

  List<SpecialtyCertification> _specialties = [];
  List<SpecialtyCertification> get specialties => _specialties;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([_profileRepository.getMe(), _specialtyRepository.getAll()]);
      _profile = results[0] as MyProfile;
      _specialties = results[1] as List<SpecialtyCertification>;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String displayName,
    String? location,
    String? bio,
    int? diveCount,
    String? languages,
    PickedImage? avatar,
  }) async {
    try {
      if (avatar != null) {
        await _profileRepository.uploadAvatar(avatar.bytes, avatar.filename);
      }
      _profile = await _profileRepository.update(
        displayName: displayName,
        location: location,
        bio: bio,
        diveCount: diveCount,
        languages: languages,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateLevel({required String level, String? agency, String? number}) async {
    try {
      // displayName deliberately omitted (stays null) — passing an empty-string fallback
      // here would COALESCE the real name away server-side if it happened to be unset.
      _profile = await _profileRepository.update(
        certificationLevel: level,
        certificationAgency: agency,
        certificationNumber: number,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> addSpecialty({required String specialty, String? customLabel, String? agency, String? certNumber}) async {
    try {
      final added = await _specialtyRepository.add(
        specialty: specialty,
        customLabel: customLabel,
        agency: agency,
        certNumber: certNumber,
      );
      _specialties = [..._specialties, added];
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> removeSpecialty(String id) async {
    final previous = _specialties;
    _specialties = _specialties.where((s) => s.id != id).toList();
    notifyListeners();
    try {
      await _specialtyRepository.remove(id);
    } catch (e) {
      _specialties = previous;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }
}
