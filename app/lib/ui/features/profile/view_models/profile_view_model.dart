import 'package:flutter/foundation.dart';

import '../../../../data/repositories/gear_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/specialty_repository.dart';
import '../../../../data/services/auth_required_exception.dart';
import '../../../../domain/entities/gear_ownership.dart';
import '../../../../domain/entities/profile.dart';
import '../../../../domain/entities/specialty_certification.dart';

class ProfileViewModel extends ChangeNotifier {
  // specialtyRepository/gearRepository are optional — the throwaway ProfileViewModel
  // LoginSheet builds just to open EditProfilePage during onboarding only ever calls
  // submit(), so it doesn't need the full Certifications/Gear data wired through it.
  ProfileViewModel({
    required ProfileRepository repository,
    SpecialtyRepository? specialtyRepository,
    GearRepository? gearRepository,
  })  : _repository = repository,
        _specialtyRepository = specialtyRepository,
        _gearRepository = gearRepository;

  final ProfileRepository _repository;
  final SpecialtyRepository? _specialtyRepository;
  final GearRepository? _gearRepository;

  Profile? _profile;
  Profile? get profile => _profile;

  List<SpecialtyCertification> _specialties = [];
  List<SpecialtyCertification> get specialties => _specialties;

  List<GearOwnership> _gear = [];
  List<GearOwnership> get gear => _gear;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  bool _isUploadingPhoto = false;
  bool get isUploadingPhoto => _isUploadingPhoto;

  // Specialty photo tracks *which* card is uploading (unlike the shared flag above) since
  // several specialty cards can be on screen at once — a shared bool would spin all of them.
  String? _uploadingSpecialtyId;
  String? get uploadingSpecialtyId => _uploadingSpecialtyId;

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
      // Fired concurrently, then awaited in order — Future.wait's mixed-type list would
      // otherwise need casts back out since specialties/gear are optional.
      final profileFuture = _repository.getProfile();
      final specialtiesFuture = _specialtyRepository?.fetchSpecialties() ?? Future.value(const []);
      final gearFuture = _gearRepository?.fetchGear() ?? Future.value(const []);
      _profile = await profileFuture;
      _specialties = await specialtiesFuture;
      _gear = await gearFuture;
    } on AuthRequiredException {
      _needsSignIn = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSpecialty({
    required String specialty,
    String? customLabel,
    String? agency,
    String? certNumber,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final added = await _specialtyRepository!.addSpecialty(
        specialty: specialty,
        customLabel: customLabel,
        agency: agency,
        certNumber: certNumber,
      );
      _specialties = [..._specialties, added];
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> removeSpecialty(String id) async {
    try {
      await _specialtyRepository!.removeSpecialty(id);
      _specialties = _specialties.where((s) => s.id != id).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> setGearStatus({required String itemKey, required String status}) async {
    try {
      final updated = await _gearRepository!.setGearStatus(itemKey: itemKey, status: status);
      _gear = [..._gear.where((g) => g.itemKey != itemKey), updated];
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeGear(String itemKey) async {
    try {
      await _gearRepository!.deleteGear(itemKey);
      _gear = _gear.where((g) => g.itemKey != itemKey).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateLevel({
    required String certificationLevel,
    String? certificationAgency,
    String? certificationNumber,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      _profile = await _repository.updateProfile(
        certificationLevel: certificationLevel,
        certificationAgency: certificationAgency,
        certificationNumber: certificationNumber,
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

  Future<bool> uploadAvatar(String filePath) async {
    _isUploadingPhoto = true;
    notifyListeners();

    try {
      _profile = await _repository.uploadAvatar(filePath);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isUploadingPhoto = false;
      notifyListeners();
    }
  }

  Future<bool> uploadCertificationPhoto(String filePath) async {
    _isUploadingPhoto = true;
    notifyListeners();

    try {
      _profile = await _repository.uploadCertificationPhoto(filePath);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isUploadingPhoto = false;
      notifyListeners();
    }
  }

  Future<bool> uploadSpecialtyPhoto(String id, String filePath) async {
    _uploadingSpecialtyId = id;
    notifyListeners();

    try {
      final url = await _specialtyRepository!.uploadSpecialtyPhoto(id, filePath);
      _specialties = [
        for (final s in _specialties)
          if (s.id == id) s.copyWith(photoUrl: url) else s,
      ];
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _uploadingSpecialtyId = null;
      notifyListeners();
    }
  }

  Future<bool> submit({
    required String displayName,
    required String location,
    required String bio,
    required int diveCount,
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
