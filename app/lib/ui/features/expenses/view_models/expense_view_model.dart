import 'package:flutter/foundation.dart';

import '../../../../data/repositories/expense_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/entities/expense.dart';
import '../../../../domain/entities/profile.dart';

class ExpenseViewModel extends ChangeNotifier {
  ExpenseViewModel({
    required ExpenseRepository repository,
    required TripRepository tripRepository,
    required ProfileRepository profileRepository,
    required this.tripId,
    required this.currentUserId,
  }) : _repository = repository,
       _tripRepository = tripRepository,
       _profileRepository = profileRepository;

  final ExpenseRepository _repository;
  final TripRepository _tripRepository;
  final ProfileRepository _profileRepository;
  final String tripId;
  final String currentUserId;

  List<Expense> _expenses = [];
  List<Expense> get expenses => _expenses;

  ExpenseBalanceSummary _balance = const ExpenseBalanceSummary(balances: [], settlements: []);
  ExpenseBalanceSummary get balance => _balance;

  Map<String, Profile> _participants = {};
  // Every current trip participant, keyed by id — used for the payer picker, split
  // checklist, and every name shown throughout this tab.
  List<Profile> get participants => _participants.values.toList();

  String displayName(String userId) {
    if (userId == currentUserId) return 'You';
    return _participants[userId]?.displayName ?? 'Diver';
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _error;
  String? get error => _error;

  /// My own net position — positive: the trip owes me, negative: I owe the trip.
  int get myBalanceMinor {
    for (final b in _balance.balances) {
      if (b.userId == currentUserId) return b.amountMinor;
    }
    return 0;
  }

  /// The simplified transfers that involve me, either direction — what the balance card's
  /// "tap for details" sheet shows.
  List<ExpenseSettlement> get mySettlements => _balance.settlements
      .where((s) => s.fromUserId == currentUserId || s.toUserId == currentUserId)
      .toList();

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final ids = await _tripRepository.getParticipantUserIds(tripId);
      final profiles = await Future.wait(ids.map(_fetchProfileOrNull));
      _participants = {for (final p in profiles.whereType<Profile>()) p.id: p};
      _expenses = await _repository.getExpenses(tripId);
      _balance = await _repository.getBalance(tripId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Profile?> _fetchProfileOrNull(String userId) async {
    try {
      return await _profileRepository.getPublicProfile(userId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _reloadExpensesAndBalance() async {
    _expenses = await _repository.getExpenses(tripId);
    _balance = await _repository.getBalance(tripId);
  }

  /// Returns null on success, or an error message on failure — same reasoning as
  /// TransportViewModel.submit: a failed create shouldn't blow away the whole list, just
  /// the still-open form.
  Future<String?> createExpense({
    required String payerUserId,
    required String title,
    required int amountMinor,
    required String splitType,
    required DateTime occurredAt,
    required List<ExpenseShareInput> shares,
  }) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _repository.createExpense(
        tripId,
        payerUserId: payerUserId,
        title: title,
        amountMinor: amountMinor,
        splitType: splitType,
        occurredAt: occurredAt,
        shares: shares,
      );
      await _reloadExpensesAndBalance();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<String?> updateExpense(
    String expenseId, {
    required String payerUserId,
    required String title,
    required int amountMinor,
    required String splitType,
    required DateTime occurredAt,
    required List<ExpenseShareInput> shares,
  }) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _repository.updateExpense(
        tripId,
        expenseId,
        payerUserId: payerUserId,
        title: title,
        amountMinor: amountMinor,
        splitType: splitType,
        occurredAt: occurredAt,
        shares: shares,
      );
      await _reloadExpensesAndBalance();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Creator-only server-side (expense.Service.Delete) — anyone else gets a 403 surfaced as
  /// this error string.
  Future<String?> deleteExpense(String expenseId) async {
    try {
      await _repository.deleteExpense(tripId, expenseId);
      await _reloadExpensesAndBalance();
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Records one suggested transfer as paid — any participant may do this (not just the
  /// debtor), per the product decision that settling has no stricter permission than editing.
  Future<String?> settle(ExpenseSettlement suggestion) async {
    try {
      await _repository.createSettlement(
        tripId,
        fromUserId: suggestion.fromUserId,
        toUserId: suggestion.toUserId,
        amountMinor: suggestion.amountMinor,
      );
      _balance = await _repository.getBalance(tripId);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}
