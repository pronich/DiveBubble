/// Read-mostly and always replaced wholesale after a mutation, same reasoning as ChatLink for skipping the freezed/API-model/mapper split.
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
  // Distinct from createdAt (when the record was entered), so a diver can log a purchase from a day or two ago.
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
  // Only meaningful for split_type 'shares'; kept so re-opening an expense for edit shows the raw count instead of a derived amount.
  final int? shares;
  final int amountMinor;

  factory ExpenseShare.fromJson(Map<String, dynamic> json) => ExpenseShare(
    userId: json['userId'] as String,
    shares: json['shares'] as int?,
    amountMinor: json['amountMinor'] as int,
  );
}

/// Positive means the trip owes them, negative means they owe the trip.
class ExpenseBalance {
  const ExpenseBalance({required this.userId, required this.amountMinor});

  final String userId;
  final int amountMinor;

  factory ExpenseBalance.fromJson(Map<String, dynamic> json) =>
      ExpenseBalance(userId: json['userId'] as String, amountMinor: json['amountMinor'] as int);
}

/// Derived from a trip's balances by the backend's expense.Simplify.
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

/// Which fields matter depends on the expense's splitType (equal only needs userId, shares needs `shares`, exact needs `amountMinor`).
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
