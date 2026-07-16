import 'package:flutter/foundation.dart';

import '../../../../data/repositories/dive_center_repository.dart';
import '../../../../domain/entities/dive_center_member.dart';

class UsersViewModel extends ChangeNotifier {
  UsersViewModel({required DiveCenterRepository repository, required this.diveCenterId}) : _repository = repository;

  final DiveCenterRepository _repository;
  final String diveCenterId;

  List<DiveCenterMember> _members = [];
  List<DiveCenterMember> get members => _members;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _members = await _repository.getMembers(diveCenterId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Returns null on success, or an error message to show — mirrors app/'s
  // TransportViewModel.join() pattern (scoped failures shouldn't blow away the whole list).
  Future<String?> removeMember(String userId) async {
    try {
      await _repository.removeMember(diveCenterId, userId);
      await load();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}
