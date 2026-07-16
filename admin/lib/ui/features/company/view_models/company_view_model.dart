import 'package:flutter/foundation.dart';

import '../../../../data/repositories/dive_center_repository.dart';
import '../../../../domain/entities/dive_center.dart';

class CompanyViewModel extends ChangeNotifier {
  CompanyViewModel({required DiveCenterRepository repository, required DiveCenter diveCenter})
      : _repository = repository,
        _diveCenter = diveCenter;

  final DiveCenterRepository _repository;
  DiveCenter _diveCenter;
  DiveCenter get diveCenter => _diveCenter;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _error;
  String? get error => _error;

  Future<bool> save({
    required String name,
    String? location,
    String? description,
    String? agency,
    String? agencyDetail,
    String? languages,
    String? website,
    String? phone,
    String? email,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      _diveCenter = await _repository.update(
        _diveCenter.id,
        name: name,
        location: location,
        description: description,
        agency: agency,
        agencyDetail: agencyDetail,
        languages: languages,
        website: website,
        phone: phone,
        email: email,
      );
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> uploadLogo(List<int> bytes, String filename) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      final logoUrl = await _repository.uploadLogo(_diveCenter.id, bytes, filename);
      _diveCenter = _diveCenter.copyWith(logoUrl: logoUrl);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
