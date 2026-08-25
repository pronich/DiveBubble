import '../../domain/entities/expense.dart';
import '../services/expense_api_service.dart';

class ExpenseRepository {
  ExpenseRepository({required ExpenseApiService service}) : _service = service;

  final ExpenseApiService _service;

  Future<List<Expense>> getExpenses(String tripId) => _service.fetchExpenses(tripId);

  Future<Expense> createExpense(
    String tripId, {
    required String payerUserId,
    required String title,
    required int amountMinor,
    required String splitType,
    required List<ExpenseShareInput> shares,
  }) => _service.createExpense(
    tripId,
    payerUserId: payerUserId,
    title: title,
    amountMinor: amountMinor,
    splitType: splitType,
    shares: shares,
  );

  Future<Expense> updateExpense(
    String tripId,
    String expenseId, {
    required String payerUserId,
    required String title,
    required int amountMinor,
    required String splitType,
    required List<ExpenseShareInput> shares,
  }) => _service.updateExpense(
    tripId,
    expenseId,
    payerUserId: payerUserId,
    title: title,
    amountMinor: amountMinor,
    splitType: splitType,
    shares: shares,
  );

  Future<void> deleteExpense(String tripId, String expenseId) =>
      _service.deleteExpense(tripId, expenseId);

  Future<ExpenseBalanceSummary> getBalance(String tripId) => _service.fetchBalance(tripId);

  Future<void> createSettlement(
    String tripId, {
    required String fromUserId,
    required String toUserId,
    required int amountMinor,
  }) => _service.createSettlement(
    tripId,
    fromUserId: fromUserId,
    toUserId: toUserId,
    amountMinor: amountMinor,
  );
}
