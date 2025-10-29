import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart' hide NetworkException;
import '../models/transaction.dart';
import '../models/order.dart';
import '../exceptions/transaction_exceptions.dart';

/// Service for managing transactions and payments
class TransactionService {
  static const String _apiName = 'PoligrainAPI';

  /// Create a new payment transaction
  Future<Transaction> createPayment({
    required double amount,
    required PaymentMethod paymentMethod,
    required String description,
    String? orderId,
    String? paymentReference,
    String currency = 'USD',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final requestBody = {
        'type': 'Payment',
        'amount': amount,
        'currency': currency,
        'paymentMethod': paymentMethod.value,
        'description': description,
        if (orderId != null) 'orderId': orderId,
        if (paymentReference != null) 'paymentReference': paymentReference,
        if (metadata != null) 'metadata': metadata,
      };

      final response =
          await Amplify.API
              .post(
                '/transactions',
                apiName: _apiName,
                body: HttpPayload.json(requestBody),
              )
              .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode == 402) {
        // Payment failed
        final transactionData =
            json.decode(responseBody) as Map<String, dynamic>;
        final transaction = Transaction.fromJson(transactionData);
        throw PaymentFailedException(
          'Payment failed: ${transaction.failureReason ?? 'Unknown reason'}',
          transaction: transaction,
        );
      }

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw TransactionCreationException(
          'Failed to create payment: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
          details: errorBody,
        );
      }

      final transactionData = json.decode(responseBody) as Map<String, dynamic>;
      return Transaction.fromJson(transactionData);
    } catch (e) {
      if (e is TransactionException) {
        rethrow;
      }
      throw TransactionCreationException('Failed to create payment: $e');
    }
  }

  /// Get user's transaction history with pagination and filters
  Future<TransactionHistoryResult> getTransactionHistory({
    int limit = 20,
    String? lastKey,
    TransactionType? type,
    TransactionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (lastKey != null) 'lastKey': lastKey,
        if (type != null) 'type': type.value,
        if (status != null) 'status': status.value,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      final response =
          await Amplify.API
              .get(
                '/transactions',
                apiName: _apiName,
                queryParameters: queryParams,
              )
              .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw TransactionFetchException(
          'Failed to fetch transactions: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
        );
      }

      final responseData = json.decode(responseBody) as Map<String, dynamic>;
      final transactions =
          (responseData['transactions'] as List<dynamic>)
              .map(
                (txnData) =>
                    Transaction.fromJson(txnData as Map<String, dynamic>),
              )
              .toList();

      final pagination = responseData['pagination'] as Map<String, dynamic>;

      return TransactionHistoryResult(
        transactions: transactions,
        hasMore: pagination['hasMore'] as bool,
        nextPageKey: pagination['lastKey'] as String?,
      );
    } catch (e) {
      if (e is TransactionException) {
        rethrow;
      }
      throw TransactionFetchException(
        'Failed to fetch transaction history: $e',
      );
    }
  }

  /// Get specific transaction details by ID
  Future<Transaction> getTransactionDetails(String transactionId) async {
    try {
      final response =
          await Amplify.API
              .get('/transactions/$transactionId', apiName: _apiName)
              .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode == 404) {
        throw TransactionNotFoundException(
          'Transaction not found: $transactionId',
        );
      }

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw TransactionFetchException(
          'Failed to fetch transaction: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
        );
      }

      final transactionData = json.decode(responseBody) as Map<String, dynamic>;
      return Transaction.fromJson(transactionData);
    } catch (e) {
      if (e is TransactionException) {
        rethrow;
      }
      throw TransactionFetchException(
        'Failed to fetch transaction details: $e',
      );
    }
  }

  /// Get transaction summary for analytics
  Future<TransactionSummary> getTransactionSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      final response =
          await Amplify.API
              .get(
                '/transactions/summary',
                apiName: _apiName,
                queryParameters: queryParams,
              )
              .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw TransactionFetchException(
          'Failed to fetch transaction summary: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
        );
      }

      final summaryData = json.decode(responseBody) as Map<String, dynamic>;
      return TransactionSummary.fromJson(summaryData);
    } catch (e) {
      if (e is TransactionException) {
        rethrow;
      }
      throw TransactionFetchException(
        'Failed to fetch transaction summary: $e',
      );
    }
  }

  /// Update transaction status (admin function)
  Future<Transaction> updateTransactionStatus({
    required String transactionId,
    required TransactionStatus status,
    String? notes,
  }) async {
    try {
      final requestBody = {
        'status': status.value,
        if (notes != null) 'notes': notes,
      };

      final response =
          await Amplify.API
              .put(
                '/transactions/$transactionId/status',
                apiName: _apiName,
                body: HttpPayload.json(requestBody),
              )
              .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode == 404) {
        throw TransactionNotFoundException(
          'Transaction not found: $transactionId',
        );
      }

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw TransactionUpdateException(
          'Failed to update transaction status: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
        );
      }

      final transactionData = json.decode(responseBody) as Map<String, dynamic>;
      return Transaction.fromJson(transactionData);
    } catch (e) {
      if (e is TransactionException) {
        rethrow;
      }
      throw TransactionUpdateException(
        'Failed to update transaction status: $e',
      );
    }
  }

  /// Process refund for a transaction
  Future<Transaction> processRefund({
    required String originalTransactionId,
    double? amount,
    String? reason,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        if (amount != null) 'amount': amount,
        if (reason != null) 'reason': reason,
      };

      final response =
          await Amplify.API
              .post(
                '/transactions/$originalTransactionId/refund',
                apiName: _apiName,
                body: HttpPayload.json(requestBody),
              )
              .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode == 404) {
        throw TransactionNotFoundException(
          'Original transaction not found: $originalTransactionId',
        );
      }

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw RefundException(
          'Failed to process refund: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
        );
      }

      final refundData = json.decode(responseBody) as Map<String, dynamic>;
      return Transaction.fromJson(refundData);
    } catch (e) {
      if (e is TransactionException) {
        rethrow;
      }
      throw RefundException('Failed to process refund: $e');
    }
  }

  /// Pay for an order
  Future<Transaction> payForOrder({
    required Order order,
    required PaymentMethod paymentMethod,
    String? paymentReference,
  }) async {
    try {
      return await createPayment(
        amount: order.totalAmount,
        paymentMethod: paymentMethod,
        description: 'Payment for order ${order.id}',
        orderId: order.id,
        paymentReference: paymentReference,
        metadata: {
          'orderItems': order.items.length,
          'customerEmail': order.customerEmail,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get transactions by type
  Future<List<Transaction>> getTransactionsByType(TransactionType type) async {
    try {
      final result = await getTransactionHistory(type: type, limit: 100);
      return result.transactions;
    } catch (e) {
      throw TransactionFetchException(
        'Failed to fetch transactions by type: $e',
      );
    }
  }

  /// Get recent transactions (last 10)
  Future<List<Transaction>> getRecentTransactions() async {
    try {
      final result = await getTransactionHistory(limit: 10);
      return result.transactions;
    } catch (e) {
      throw TransactionFetchException(
        'Failed to fetch recent transactions: $e',
      );
    }
  }

  /// Get failed transactions
  Future<List<Transaction>> getFailedTransactions() async {
    try {
      final result = await getTransactionHistory(
        status: TransactionStatus.failed,
        limit: 50,
      );
      return result.transactions;
    } catch (e) {
      throw TransactionFetchException(
        'Failed to fetch failed transactions: $e',
      );
    }
  }

  /// Check if transaction can be refunded
  bool canRefundTransaction(Transaction transaction) {
    return transaction.canBeRefunded;
  }

  /// Get payment method display name
  String getPaymentMethodDisplayName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.digitalWallet:
        return 'Digital Wallet';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.cryptocurrency:
        return 'Cryptocurrency';
    }
  }

  /// Get transaction status display color
  String getTransactionStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return '#FF9800'; // Orange
      case TransactionStatus.processing:
        return '#2196F3'; // Blue
      case TransactionStatus.completed:
        return '#4CAF50'; // Green
      case TransactionStatus.failed:
        return '#F44336'; // Red
      case TransactionStatus.cancelled:
        return '#9E9E9E'; // Grey
      case TransactionStatus.refunded:
        return '#673AB7'; // Deep Purple
    }
  }

  /// Format transaction amount with currency
  String formatTransactionAmount(Transaction transaction) {
    return transaction.formattedAmount;
  }
}

/// Result object for transaction history pagination
class TransactionHistoryResult {
  final List<Transaction> transactions;
  final bool hasMore;
  final String? nextPageKey;

  const TransactionHistoryResult({
    required this.transactions,
    required this.hasMore,
    this.nextPageKey,
  });

  /// Check if there are more transactions to load
  bool get canLoadMore => hasMore && nextPageKey != null;

  /// Get total number of transactions in current page
  int get count => transactions.length;

  /// Get total amount for current page transactions
  double get totalAmount {
    return transactions
        .where((txn) => txn.status == TransactionStatus.completed)
        .fold(0.0, (sum, txn) => sum + txn.amount);
  }

  /// Get formatted total amount
  String get formattedTotalAmount => '\$${totalAmount.toStringAsFixed(2)}';
}
