import 'package:flutter/foundation.dart';

import '../../../../data/repositories/dive_log_repository.dart';
import '../../../../data/repositories/gear_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/specialty_repository.dart';
import '../../../../data/services/auth_required_exception.dart';
import '../../../../domain/entities/dive_log_entry.dart';
import '../../../../domain/entities/gear_ownership.dart';
import '../../../../domain/entities/profile.dart';
import '../../../../domain/entities/specialty_certification.dart';

class ProfileViewModel extends ChangeNotifier {
  // specialtyRepository/gearRepository/diveLogRepository are optional — the throwaway
  // ProfileViewModel LoginSheet builds just to open EditProfilePage during onboarding only
  // ever calls submit(), so it doesn't need the full Certifications/Gear/DiveLog data wired
  // through it.
  ProfileViewModel({
    required ProfileRepository repository,
    SpecialtyRepository? specialtyRepository,
    GearRepository? gearRepository,
    DiveLogRepository? diveLogRepository,
  }) : _repository = repository,
       _specialtyRepository = specialtyRepository,
       _gearRepository = gearRepository,
       _diveLogRepository = diveLogRepository;

  final ProfileRepository _repository;
  final SpecialtyRepository? _specialtyRepository;
  final GearRepository? _gearRepository;
  final DiveLogRepository? _diveLogRepository;

  Profile? _profile;
  Profile? get profile => _profile;

  List<SpecialtyCertification> _specialties = [];
  List<SpecialtyCertification> get specialties => _specialties;

  List<GearOwnership> _gear = [];
  List<GearOwnership> get gear => _gear;

  List<DiveLogEntry> _diveLog = [];
  List<DiveLogEntry> get diveLog => _diveLog;

  /// Profile.diveCount ("unlogged dives", see EditProfilePage) plus however many are
  /// actually in the Dive Log — the number the profile's own "Dives" stat card should show,
  /// since diveCount alone under-counts the moment a diver has logged anything (most visibly
  /// once they've zeroed it out via "All my dives are logged" and it'd otherwise read 0).
  int get totalDiveCount => (_profile?.diveCount ?? 0) + _diveLog.length;

  bool _isSubmittingDiveLog = false;
  bool get isSubmittingDiveLog => _isSubmittingDiveLog;

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
      final diveLogFuture = _diveLogRepository?.getEntries() ?? Future.value(const []);
      _profile = await profileFuture;
      _specialties = await specialtiesFuture;
      _gear = await gearFuture;
      _diveLog = await diveLogFuture;
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

  Future<bool> removeAvatar() async {
    _isUploadingPhoto = true;
    notifyListeners();

    try {
      _profile = await _repository.removeAvatar();
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

  /// True right after the diver's very first-ever dive log entry lands (manual or imported)
  /// — the UI reads this once to prompt "update your unlogged-dives count in Edit Profile if
  /// some of these were already counted there", then it's cleared so the prompt doesn't
  /// repeat on every subsequent add.
  bool _justLoggedFirstEntry = false;
  bool consumeJustLoggedFirstEntry() {
    final v = _justLoggedFirstEntry;
    _justLoggedFirstEntry = false;
    return v;
  }

  Future<String?> addManualDiveLogEntry({
    required DateTime divedAt,
    double? maxDepthM,
    int? durationMinutes,
    double? minTemperatureC,
    String? country,
    String? siteName,
    String? notes,
  }) async {
    _isSubmittingDiveLog = true;
    notifyListeners();
    try {
      final wasEmpty = _diveLog.isEmpty;
      final entry = await _diveLogRepository!.createEntry(
        divedAt: divedAt,
        maxDepthM: maxDepthM,
        durationMinutes: durationMinutes,
        minTemperatureC: minTemperatureC,
        country: country,
        siteName: siteName,
        notes: notes,
      );
      _diveLog = [entry, ..._diveLog]..sort((a, b) => b.divedAt.compareTo(a.divedAt));
      if (wasEmpty) _justLoggedFirstEntry = true;
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isSubmittingDiveLog = false;
      notifyListeners();
    }
  }

  /// Returns null (and reloads the log) on success, or an error message on failure. A
  /// successful import that found zero new dives (all duplicates of what's already logged)
  /// still returns null with an ImportResult the caller can inspect for the "N new, M
  /// already logged" toast — see DiveLogListPage.
  Future<DiveLogImportResult?> importDiveLog(String filePath) async {
    _isSubmittingDiveLog = true;
    notifyListeners();
    try {
      final wasEmpty = _diveLog.isEmpty;
      final result = await _diveLogRepository!.importFile(filePath);
      _diveLog = await _diveLogRepository.getEntries();
      if (wasEmpty && result.imported > 0) _justLoggedFirstEntry = true;
      return result;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isSubmittingDiveLog = false;
      notifyListeners();
    }
  }

  Future<String?> updateDiveLogEntry(
    String id, {
    required DateTime divedAt,
    double? maxDepthM,
    int? durationMinutes,
    double? minTemperatureC,
    String? country,
    String? siteName,
    String? notes,
  }) async {
    _isSubmittingDiveLog = true;
    notifyListeners();
    try {
      final updated = await _diveLogRepository!.updateEntry(
        id,
        divedAt: divedAt,
        maxDepthM: maxDepthM,
        durationMinutes: durationMinutes,
        minTemperatureC: minTemperatureC,
        country: country,
        siteName: siteName,
        notes: notes,
      );
      _diveLog = [
        for (final e in _diveLog)
          if (e.id == id) updated else e,
      ]..sort((a, b) => b.divedAt.compareTo(a.divedAt));
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isSubmittingDiveLog = false;
      notifyListeners();
    }
  }

  Future<bool> deleteDiveLogEntry(String id) async {
    try {
      await _diveLogRepository!.deleteEntry(id);
      _diveLog = _diveLog.where((e) => e.id != id).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Bulk delete for multi-select — best-effort per entry (one failing mid-batch doesn't
  /// abandon the rest), returns the ids that actually got deleted so the caller can report
  /// a partial failure if fewer came back than were asked for.
  Future<List<String>> deleteDiveLogEntries(List<String> ids) async {
    final deleted = <String>[];
    for (final id in ids) {
      try {
        await _diveLogRepository!.deleteEntry(id);
        deleted.add(id);
      } catch (e) {
        _error = e.toString();
      }
    }
    _diveLog = _diveLog.where((e) => !deleted.contains(e.id)).toList();
    notifyListeners();
    return deleted;
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
