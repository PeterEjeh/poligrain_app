/// Base exception class for all cart-related errors
abstract class CartException implements Exception {
  final String message;
  
  const CartException(this.message);
  
  @override
  String toString() => 'CartException: $message';
}

/// Exception thrown when an invalid quantity is provided
class InvalidQuantityException extends CartException {
  const InvalidQuantityException(super.message);
  
  @override
  String toString() => 'InvalidQuantityException: $message';
}

/// Exception thrown when there's insufficient stock for the requested quantity
class InsufficientStockException extends CartException {
  const InsufficientStockException(super.message);
  
  @override
  String toString() => 'InsufficientStockException: $message';
}

/// Exception thrown when trying to operate on a product not in cart
class ProductNotInCartException extends CartException {
  const ProductNotInCartException(super.message);
  
  @override
  String toString() => 'ProductNotInCartException: $message';
}

/// Exception thrown when a cart operation fails
class CartOperationException extends CartException {
  const CartOperationException(super.message);
  
  @override
  String toString() => 'CartOperationException: $message';
}

/// Exception thrown when cart data is corrupted or invalid
class CartDataException extends CartException {
  const CartDataException(super.message);
  
  @override
  String toString() => 'CartDataException: $message';
}

/// Represents a cart validation issue
class CartValidationIssue {
  final String productId;
  final CartValidationIssueType type;
  final String message;
  
  const CartValidationIssue({
    required this.productId,
    required this.type,
    required this.message,
  });
  
  @override
  String toString() => 'CartValidationIssue: $message';
}

/// Types of cart validation issues
enum CartValidationIssueType {
  productNotFound,
  productInactive,
  insufficientStock,
  priceChanged,
}
