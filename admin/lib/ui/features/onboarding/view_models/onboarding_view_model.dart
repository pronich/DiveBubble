import 'package:flutter/foundation.dart';

import '../../../../data/repositories/dive_center_repository.dart';
import '../../../../domain/entities/dive_center.dart';
import '../../../core/widgets/pick_image.dart';

class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel({required DiveCenterRepository repository}) : _repository = repository;

  final DiveCenterRepository _repository;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _error;
  String? get error => _error;

  /// Returns the created dive center on success, or null with [error] set. The logo
  /// upload (if any) is best-effort *after* creation — see uploadLogo's own contract,
  /// the dive center needs to exist first — so a failed logo upload doesn't block
  /// finishing onboarding; it can be added later from the dashboard.
  Future<DiveCenter?> submit({
    required String name,
    String? location,
    String? description,
    String? agency,
    String? agencyDetail,
    String? languages,
    String? website,
    String? phone,
    PickedImage? logo,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      var dc = await _repository.create(
        name: name,
        location: location,
        description: description,
        agency: agency,
        agencyDetail: agencyDetail,
        languages: languages,
        website: website,
        phone: phone,
      );
      if (logo != null) {
        try {
          final url = await _repository.uploadLogo(dc.id, logo.bytes, logo.filename);
          dc = dc.copyWith(logoUrl: url);
        } catch (_) {
          // ignore — see doc comment above
        }
      }
      return dc;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
