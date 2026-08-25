/// Splitwise-style per-trip expense. Read-mostly and always replaced wholesale after a
/// mutation (create/update/delete all just reload the list) — same reasoning as ChatLink for
/// skipping the freezed/API-model/mapper split, a plain class with fromJson is enough.
class Expense {
  const Expense({
    required this.id,
    required this.tripId,
    required this.payerUserId,
    required this.createdBy,
    required this.title,
    required this.amountMinor,
    required this.splitType,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    required this.shares,
  });

  final String id;
  final String tripId;
  final String payerUserId;
  final String createdBy;
  final String title;
  final int amountMinor;
  final String splitType; // 'equal' | 'shares' | 'exact'
  // The date the expense actually happened — distinct from createdAt (when the record was
  // entered), so a diver can log a purchase from a day or two ago.
  final DateTime occurredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ExpenseShare> shares;

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'] as String,
    tripId: json['tripId'] as String,
    payerUserId: json['payerUserId'] as String,
    createdBy: json['createdBy'] as String,
    title: json['title'] as String,
    amountMinor: json['amountMinor'] as int,
    splitType: json['splitType'] as String,
    occurredAt: DateTime.parse(json['occurredAt'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    shares: (json['shares'] as List<dynamic>? ?? [])
        .map((e) => ExpenseShare.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class ExpenseShare {
  const ExpenseShare({required this.userId, this.shares, required this.amountMinor});

  final String userId;
  // Only meaningful for split_type 'shares' — the raw 1/2/3 count the payer entered, kept
  // around so re-opening an expense for edit shows that instead of a derived amount.
  final int? shares;
  final int amountMinor;

  factory ExpenseShare.fromJson(Map<String, dynamic> json) => ExpenseShare(
    userId: json['userId'] as String,
    shares: json['shares'] as int?,
    amountMinor: json['amountMinor'] as int,
  );
}

/// One participant's net position on a trip — positive means the trip owes them, negative
/// means they owe the trip.
class ExpenseBalance {
  const ExpenseBalance({required this.userId, required this.amountMinor});

  final String userId;
  final int amountMinor;

  factory ExpenseBalance.fromJson(Map<String, dynamic> json) =>
      ExpenseBalance(userId: json['userId'] as String, amountMinor: json['amountMinor'] as int);
}

/// One suggested transfer from the simplified "who pays whom" graph — see the backend's
/// expense.Simplify for how these are derived from a trip's balances.
class ExpenseSettlement {
  const ExpenseSettlement({
    required this.fromUserId,
    required this.toUserId,
    required this.amountMinor,
  });

  final String fromUserId;
  final String toUserId;
  final int amountMinor;

  factory ExpenseSettlement.fromJson(Map<String, dynamic> json) => ExpenseSettlement(
    fromUserId: json['fromUserId'] as String,
    toUserId: json['toUserId'] as String,
    amountMinor: json['amountMinor'] as int,
  );
}

/// One row of a create/update request's split — which fields matter depends on the
/// expense's splitType (equal only needs userId, shares needs `shares`, exact needs
/// `amountMinor`). Built by the add/edit form, not read back from the server.
class ExpenseShareInput {
  const ExpenseShareInput({required this.userId, this.shares, this.amountMinor});

  final String userId;
  final int? shares;
  final int? amountMinor;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    if (shares != null) 'shares': shares,
    if (amountMinor != null) 'amountMinor': amountMinor,
  };
}

class ExpenseBalanceSummary {
  const ExpenseBalanceSummary({required this.balances, required this.settlements});

  final List<ExpenseBalance> balances;
  final List<ExpenseSettlement> settlements;

  factory ExpenseBalanceSummary.fromJson(Map<String, dynamic> json) => ExpenseBalanceSummary(
    balances: (json['balances'] as List<dynamic>? ?? [])
        .map((e) => ExpenseBalance.fromJson(e as Map<String, dynamic>))
        .toList(),
    settlements: (json['settlements'] as List<dynamic>? ?? [])
        .map((e) => ExpenseSettlement.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
