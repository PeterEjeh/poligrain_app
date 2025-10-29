import 'package:meta/meta.dart';
import 'product.dart';

/// Represents an item in the shopping cart with quantity and metadata
@immutable
class CartItem {
  final Product product;
  final int quantity;
  final DateTime addedAt;
  final DateTime? updatedAt;

  const CartItem({
    required this.product,
    required this.quantity,
    required this.addedAt,
    this.updatedAt,
  });

  /// Create CartItem from JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int? ?? 1,
      addedAt: DateTime.parse(json['addedAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Convert CartItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'addedAt': addedAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  CartItem copyWith({
    Product? product,
    int? quantity,
    DateTime? addedAt,
    DateTime? updatedAt,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Get total price for this cart item (price * quantity)
  double get totalPrice => product.price * quantity;

  /// Get formatted total price
  String get formattedTotalPrice => '\$${totalPrice.toStringAsFixed(2)}';

  /// Get individual item price
  String get formattedUnitPrice => product.formattedPrice;

  /// Check if item is in stock
  bool get isInStock => product.isInStock && quantity <= product.quantity;

  /// Check if requested quantity exceeds available stock
  bool get exceedsStock => quantity > product.quantity;

  /// Get maximum available quantity
  int get maxAvailableQuantity => product.quantity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          product.id == other.product.id;

  @override
  int get hashCode => product.id.hashCode;

  @override
  String toString() {
    return 'CartItem{product: ${product.name}, quantity: $quantity, totalPrice: $totalPrice}';
  }
}
