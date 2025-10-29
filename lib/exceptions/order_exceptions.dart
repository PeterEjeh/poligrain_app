/// Base class for all order-related exceptions
abstract class OrderException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? details;

  const OrderException(this.message, {this.statusCode, this.details});

  @override
  String toString() => 'OrderException: $message';
}

/// Exception thrown when order creation fails
class OrderCreationException extends OrderException {
  const OrderCreationException(
    String message, {
    int? statusCode,
    Map<String, dynamic>? details,
  }) : super(message, statusCode: statusCode, details: details);

  @override
  String toString() => 'OrderCreationException: $message';
}

/// Exception thrown when order fetching fails
class OrderFetchException extends OrderException {
  const OrderFetchException(
    String message, {
    int? statusCode,
    Map<String, dynamic>? details,
  }) : super(message, statusCode: statusCode, details: details);

  @override
  String toString() => 'OrderFetchException: $message';
}

/// Exception thrown when order update fails
class OrderUpdateException extends OrderException {
  const OrderUpdateException(
    String message, {
    int? statusCode,
    Map<String, dynamic>? details,
  }) : super(message, statusCode: statusCode, details: details);

  @override
  String toString() => 'OrderUpdateException: $message';
}

/// Exception thrown when order is not found
class OrderNotFoundException extends OrderException {
  const OrderNotFoundException(String message) : super(message, statusCode: 404);

  @override
  String toString() => 'OrderNotFoundException: $message';
}

/// Exception thrown when order validation fails
class OrderValidationException extends OrderException {
  final List<String> validationErrors;

  const OrderValidationException(
    String message,
    this.validationErrors, {
    Map<String, dynamic>? details,
  }) : super(message, statusCode: 400, details: details);

  @override
  String toString() => 'OrderValidationException: $message\nErrors: ${validationErrors.join(', ')}';
}

/// Exception thrown when insufficient stock for order items
class InsufficientStockException extends OrderException {
  final String productId;
  final int requestedQuantity;
  final int availableQuantity;

  const InsufficientStockException(
    String message, {
    required this.productId,
    required this.requestedQuantity,
    required this.availableQuantity,
  }) : super(message, statusCode: 400);

  @override
  String toString() => 
      'InsufficientStockException: $message (Product: $productId, Requested: $requestedQuantity, Available: $availableQuantity)';
}

/// Exception thrown when order operation is not allowed in current state
class OrderStateException extends OrderException {
  final String currentStatus;
  final String attemptedOperation;

  const OrderStateException(
    String message, {
    required this.currentStatus,
    required this.attemptedOperation,
  }) : super(message, statusCode: 400);

  @override
  String toString() => 
      'OrderStateException: $message (Current Status: $currentStatus, Operation: $attemptedOperation)';
}

/// Exception thrown when order access is denied
class OrderAccessDeniedException extends OrderException {
  const OrderAccessDeniedException(String message) : super(message, statusCode: 403);

  @override
  String toString() => 'OrderAccessDeniedException: $message';
}

/// Exception thrown when order has expired or is no longer valid
class OrderExpiredException extends OrderException {
  final DateTime expiredAt;

  const OrderExpiredException(
    String message, {
    required this.expiredAt,
  }) : super(message, statusCode: 410);

  @override
  String toString() => 'OrderExpiredException: $message (Expired at: $expiredAt)';
}

/// Exception thrown when order cancellation fails
class OrderCancellationException extends OrderException {
  const OrderCancellationException(
    String message, {
    int? statusCode,
    Map<String, dynamic>? details,
  }) : super(message, statusCode: statusCode, details: details);

  @override
  String toString() => 'OrderCancellationException: $message';
}

/// Exception thrown when order payment fails
class OrderPaymentException extends OrderException {
  final String? transactionId;
  final String? paymentGatewayError;

  const OrderPaymentException(
    String message, {
    this.transactionId,
    this.paymentGatewayError,
    int? statusCode,
    Map<String, dynamic>? details,
  }) : super(message, statusCode: statusCode, details: details);

  @override
  String toString() => 
      'OrderPaymentException: $message${transactionId != null ? ' (Transaction ID: $transactionId)' : ''}';
}

/// Exception thrown when order shipping fails
class OrderShippingException extends OrderException {
  final String? trackingNumber;

  const OrderShippingException(
    String message, {
    this.trackingNumber,
    int? statusCode,
    Map<String, dynamic>? details,
  }) : super(message, statusCode: statusCode, details: details);

  @override
  String toString() => 
      'OrderShippingException: $message${trackingNumber != null ? ' (Tracking: $trackingNumber)' : ''}';
}

/// Exception thrown when order network operation fails
class OrderNetworkException extends OrderException {
  const OrderNetworkException(String message) : super(message, statusCode: 500);

  @override
  String toString() => 'OrderNetworkException: $message';
}
