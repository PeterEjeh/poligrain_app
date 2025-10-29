import 'package:meta/meta.dart';

/// Transaction type enumeration
enum TransactionType {
  payment('Payment'),
  refund('Refund'),
  fee('Fee'),
  bonus('Bonus'),
  withdrawal('Withdrawal'),
  deposit('Deposit');

  const TransactionType(this.value);
  final String value;

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TransactionType.payment,
    );
  }
}

/// Transaction status enumeration
enum TransactionStatus {
  pending('Pending'),
  processing('Processing'),
  completed('Completed'),
  failed('Failed'),
  cancelled('Cancelled'),
  refunded('Refunded');

  const TransactionStatus(this.value);
  final String value;

  static TransactionStatus fromString(String value) {
    return TransactionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TransactionStatus.pending,
    );
  }
}

/// Payment method enumeration
enum PaymentMethod {
  creditCard('Credit Card'),
  debitCard('Debit Card'),
  bankTransfer('Bank Transfer'),
  digitalWallet('Digital Wallet'),
  cash('Cash'),
  mobileMoney('Mobile Money'),
  cryptocurrency('Cryptocurrency');

  const PaymentMethod(this.value);
  final String value;

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => PaymentMethod.creditCard,
    );
  }
}

/// Represents a financial transaction
@immutable
class Transaction {
  final String id;
  final String userId;
  final String? orderId;
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final String currency;
  final PaymentMethod paymentMethod;
  final String? paymentReference;
  final String? gatewayTransactionId;
  final String? gatewayResponse;
  final String description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final String? failureReason;
  final List<TransactionStatusHistory> statusHistory;

  const Transaction({
    required this.id,
    required this.userId,
    this.orderId,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    this.paymentReference,
    this.gatewayTransactionId,
    this.gatewayResponse,
    required this.description,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.failureReason,
    this.statusHistory = const [],
  });

  /// Create Transaction from JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      orderId: json['orderId'] as String?,
      type: TransactionType.fromString(json['type'] as String),
      status: TransactionStatus.fromString(json['status'] as String),
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      paymentMethod: PaymentMethod.fromString(json['paymentMethod'] as String),
      paymentReference: json['paymentReference'] as String?,
      gatewayTransactionId: json['gatewayTransactionId'] as String?,
      gatewayResponse: json['gatewayResponse'] as String?,
      description: json['description'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      failureReason: json['failureReason'] as String?,
      statusHistory: json['statusHistory'] != null
          ? (json['statusHistory'] as List<dynamic>)
              .map((history) => TransactionStatusHistory.fromJson(
                    history as Map<String, dynamic>,
                  ))
              .toList()
          : [],
    );
  }

  /// Convert Transaction to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'orderId': orderId,
      'type': type.value,
      'status': status.value,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod.value,
      'paymentReference': paymentReference,
      'gatewayTransactionId': gatewayTransactionId,
      'gatewayResponse': gatewayResponse,
      'description': description,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'failureReason': failureReason,
      'statusHistory': statusHistory.map((history) => history.toJson()).toList(),
    };
  }

  /// Create a copy with updated fields
  Transaction copyWith({
    String? id,
    String? userId,
    String? orderId,
    TransactionType? type,
    TransactionStatus? status,
    double? amount,
    String? currency,
    PaymentMethod? paymentMethod,
    String? paymentReference,
    String? gatewayTransactionId,
    String? gatewayResponse,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? failureReason,
    List<TransactionStatusHistory>? statusHistory,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderId: orderId ?? this.orderId,
      type: type ?? this.type,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      gatewayTransactionId: gatewayTransactionId ?? this.gatewayTransactionId,
      gatewayResponse: gatewayResponse ?? this.gatewayResponse,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      completedAt: completedAt ?? this.completedAt,
      failureReason: failureReason ?? this.failureReason,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }

  /// Get formatted amount with currency
  String get formattedAmount => '${currency == 'USD' ? '\$' : currency}${amount.toStringAsFixed(2)}';

  /// Check if transaction is completed
  bool get isCompleted => status == TransactionStatus.completed;

  /// Check if transaction is pending
  bool get isPending => status == TransactionStatus.pending;

  /// Check if transaction failed
  bool get isFailed => status == TransactionStatus.failed;

  /// Check if transaction can be refunded
  bool get canBeRefunded => 
      status == TransactionStatus.completed && 
      type == TransactionType.payment;

  /// Get transaction duration (if completed)
  Duration? get processingDuration {
    if (completedAt != null) {
      return completedAt!.difference(createdAt);
    }
    return null;
  }

  /// Check if transaction is for an order
  bool get isOrderTransaction => orderId != null;

  /// Get display color based on status
  String get statusColor {
    switch (status) {
      case TransactionStatus.completed:
        return '#4CAF50'; // Green
      case TransactionStatus.pending:
      case TransactionStatus.processing:
        return '#FF9800'; // Orange
      case TransactionStatus.failed:
      case TransactionStatus.cancelled:
        return '#F44336'; // Red
      case TransactionStatus.refunded:
        return '#2196F3'; // Blue
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Transaction{id: $id, type: ${type.value}, status: ${status.value}, amount: $formattedAmount}';
  }
}

/// Represents transaction status change history
@immutable
class TransactionStatusHistory {
  final TransactionStatus status;
  final DateTime timestamp;
  final String? notes;
  final String? updatedBy;

  const TransactionStatusHistory({
    required this.status,
    required this.timestamp,
    this.notes,
    this.updatedBy,
  });

  factory TransactionStatusHistory.fromJson(Map<String, dynamic> json) {
    return TransactionStatusHistory(
      status: TransactionStatus.fromString(json['status'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      notes: json['notes'] as String?,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.value,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'updatedBy': updatedBy,
    };
  }
}

/// Summary of user transactions for analytics
@immutable
class TransactionSummary {
  final String userId;
  final double totalSpent;
  final double totalRefunded;
  final int totalTransactions;
  final int completedTransactions;
  final int failedTransactions;
  final Map<TransactionType, double> amountByType;
  final Map<PaymentMethod, int> countByPaymentMethod;
  final DateTime periodStart;
  final DateTime periodEnd;

  const TransactionSummary({
    required this.userId,
    required this.totalSpent,
    required this.totalRefunded,
    required this.totalTransactions,
    required this.completedTransactions,
    required this.failedTransactions,
    required this.amountByType,
    required this.countByPaymentMethod,
    required this.periodStart,
    required this.periodEnd,
  });

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      userId: json['userId'] as String,
      totalSpent: (json['totalSpent'] as num).toDouble(),
      totalRefunded: (json['totalRefunded'] as num).toDouble(),
      totalTransactions: json['totalTransactions'] as int,
      completedTransactions: json['completedTransactions'] as int,
      failedTransactions: json['failedTransactions'] as int,
      amountByType: Map<TransactionType, double>.from(
        (json['amountByType'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(
            TransactionType.fromString(key),
            (value as num).toDouble(),
          ),
        ),
      ),
      countByPaymentMethod: Map<PaymentMethod, int>.from(
        (json['countByPaymentMethod'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(
            PaymentMethod.fromString(key),
            value as int,
          ),
        ),
      ),
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalSpent': totalSpent,
      'totalRefunded': totalRefunded,
      'totalTransactions': totalTransactions,
      'completedTransactions': completedTransactions,
      'failedTransactions': failedTransactions,
      'amountByType': amountByType.map(
        (key, value) => MapEntry(key.value, value),
      ),
      'countByPaymentMethod': countByPaymentMethod.map(
        (key, value) => MapEntry(key.value, value),
      ),
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
    };
  }

  /// Get success rate as percentage
  double get successRate {
    if (totalTransactions == 0) return 0.0;
    return (completedTransactions / totalTransactions) * 100;
  }

  /// Get formatted total spent
  String get formattedTotalSpent => '\$${totalSpent.toStringAsFixed(2)}';

  /// Get formatted total refunded
  String get formattedTotalRefunded => '\$${totalRefunded.toStringAsFixed(2)}';

  /// Get net amount (spent - refunded)
  double get netAmount => totalSpent - totalRefunded;

  /// Get formatted net amount
  String get formattedNetAmount => '\$${netAmount.toStringAsFixed(2)}';
}
