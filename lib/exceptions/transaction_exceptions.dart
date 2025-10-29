/// Custom exceptions for transaction operations
abstract class TransactionException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? details;

  const TransactionException(
    this.message, {
    this.statusCode,
    this.details,
  });

  @override
  String toString() => 'TransactionException: $message';
}

/// Exception thrown when transaction creation fails
class TransactionCreationException extends TransactionException {
  const TransactionCreationException(
    String message, {
    int? statusCode,
    Map<String, dynamic>? details,
  }) : super(message, statusCode: statusCode, details: details);

  @override
  String toString() => 'TransactionCreationException: $message';
}

/// Exception thrown when transaction fetching fails
class TransactionFetchException extends TransactionException {
  const TransactionFetchException(
    String message, {
    int? statusCode,
  }) : super(message, statusCode: statusCode);

  @override
  String toString() => 'TransactionFetchException: $message';
}

/// Exception thrown when transaction is not found
class TransactionNotFoundException extends TransactionException {
  const TransactionNotFoundException(String message) 
      : super(message, statusCode: 404);

  @override
  String toString() => 'TransactionNotFoundException: $message';
}

/// Exception thrown when transaction update fails
class TransactionUpdateException extends TransactionException {
  const TransactionUpdateException(
    String message, {
    int? statusCode,
  }) : super(message, statusCode: statusCode);

  @override
  String toString() => 'TransactionUpdateException: $message';
}

/// Exception thrown when payment processing fails
class PaymentFailedException extends TransactionException {
  final dynamic transaction;

  const PaymentFailedException(
    String message, {
    this.transaction,
  }) : super(message, statusCode: 402);

  @override
  String toString() => 'PaymentFailedException: $message';
}

/// Exception thrown when refund processing fails
class RefundException extends TransactionException {
  const RefundException(
    String message, {
    int? statusCode,
  }) : super(message, statusCode: statusCode);

  @override
  String toString() => 'RefundException: $message';
}

/// Exception thrown when unsupported currency is used
class UnsupportedCurrencyException extends TransactionException {
  final String currency;

  const UnsupportedCurrencyException(
    String message, {
    required this.currency,
  }) : super(message, statusCode: 400);

  @override
  String toString() => 
      'UnsupportedCurrencyException: $message (Currency: $currency)';
}

/// Exception thrown when transaction processing timeout occurs
class TransactionTimeoutException extends TransactionException {
  final Duration timeout;

  const TransactionTimeoutException(
    String message, {
    required this.timeout,
  }) : super(message, statusCode: 408);

  @override
  String toString() => 
      'TransactionTimeoutException: $message (Timeout: ${timeout.inSeconds}s)';
}