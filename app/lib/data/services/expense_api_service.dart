import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/expense.dart';
import 'access_token_provider.dart';
import 'auth_required_exception.dart';

class ExpenseApiService {
  ExpenseApiService({required this.baseUrl, required this.getAccessToken, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final AccessTokenProvider getAccessToken;
  final http.Client _client;

  Future<Map<String, String>> _authHeaders() async {
    final token = await getAccessToken();
    if (token == null) throw const AuthRequiredException();
    return {'Authorization': 'Bearer $token'};
  }

  // Server errors come back as {"error": "..."} — surface that message directly instead of
  // the raw body, same convention as every other *ApiService in this app.
  String? _extractError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      // fall through
    }
    return null;
  }

  Future<List<Expense>> fetchExpenses(String tripId) async {
    final res = await _client.get(
      Uri.parse('$baseUrl/trips/$tripId/expenses'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception('fetchExpenses failed: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(res.body) as List<dynamic>;
    return decoded.map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Expense> createExpense(
    String tripId, {
    required String payerUserId,
    required String title,
    required int amountMinor,
    required String splitType,
    required List<ExpenseShareInput> shares,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/trips/$tripId/expenses'),
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'payerUserId': payerUserId,
        'title': title,
        'amountMinor': amountMinor,
        'splitType': splitType,
        'shares': shares.map((s) => s.toJson()).toList(),
      }),
    );
    if (res.statusCode != 201) {
      throw Exception(_extractError(res.body) ?? 'createExpense failed: ${res.statusCode}');
    }
    return Expense.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Expense> updateExpense(
    String tripId,
    String expenseId, {
    required String payerUserId,
    required String title,
    required int amountMinor,
    required String splitType,
    required List<ExpenseShareInput> shares,
  }) async {
    final res = await _client.put(
      Uri.parse('$baseUrl/trips/$tripId/expenses/$expenseId'),
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'payerUserId': payerUserId,
        'title': title,
        'amountMinor': amountMinor,
        'splitType': splitType,
        'shares': shares.map((s) => s.toJson()).toList(),
      }),
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'updateExpense failed: ${res.statusCode}');
    }
    return Expense.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteExpense(String tripId, String expenseId) async {
    final res = await _client.delete(
      Uri.parse('$baseUrl/trips/$tripId/expenses/$expenseId'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 204) {
      throw Exception(_extractError(res.body) ?? 'deleteExpense failed: ${res.statusCode}');
    }
  }

  Future<ExpenseBalanceSummary> fetchBalance(String tripId) async {
    final res = await _client.get(
      Uri.parse('$baseUrl/trips/$tripId/expenses/balance'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception('fetchBalance failed: ${res.statusCode} ${res.body}');
    }
    return ExpenseBalanceSummary.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> createSettlement(
    String tripId, {
    required String fromUserId,
    required String toUserId,
    required int amountMinor,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/trips/$tripId/expenses/settlements'),
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'amountMinor': amountMinor,
      }),
    );
    if (res.statusCode != 201) {
      throw Exception(_extractError(res.body) ?? 'createSettlement failed: ${res.statusCode}');
    }
  }
}
