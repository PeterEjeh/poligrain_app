import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/inventory_reservation.dart';
import '../exceptions/cart_exceptions.dart';
import 'inventory_reservation_interface.dart';

/// Enhanced Cart Service with inventory reservations and quantity management
class CartService extends ChangeNotifier {
  static const String _cartKey = 'cart_items';

  final Map<String, CartItem> _items = {};
  final InventoryReservationInterface _reservationService;
  bool _isLoading = false;

  CartService({required InventoryReservationInterface reservationService})
    : _reservationService = reservationService;

  /// Get all cart items as a list
  List<CartItem> get items => _items.values.toList();

  /// Get cart items as a map for easier access
  Map<String, CartItem> get itemsMap => Map.unmodifiable(_items);

  /// Get total number of items in cart (sum of quantities)
  int get totalItems =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  /// Get total number of unique products in cart
  int get uniqueItemCount => _items.length;

  /// Get total price of all items in cart
  double get totalPrice =>
      _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Check if cart is empty
  bool get isEmpty => _items.isEmpty;

  /// Check if cart is not empty
  bool get isNotEmpty => _items.isNotEmpty;

  /// Check if currently loading
  bool get isLoading => _isLoading;

  /// Initialize cart service and load persisted data
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadCartFromStorage();
    } catch (e) {
      debugPrint('Error loading cart from storage: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a product to cart with specified quantity and create reservation
  Future<void> addToCart(Product product, {int quantity = 1}) async {
    try {
      if (quantity <= 0) {
        throw InvalidQuantityException('Quantity must be greater than 0');
      }

      // Check against available quantity (total - reserved)
      if (quantity > product.availableQuantity) {
        throw InsufficientStockException(
          'Requested quantity ($quantity) exceeds available stock (${product.availableQuantity})',
        );
      }

      final productId = product.id;

      if (_items.containsKey(productId)) {
        // Update existing item
        final existingItem = _items[productId]!;
        final newQuantity = existingItem.quantity + quantity;

        if (newQuantity > product.availableQuantity) {
          throw InsufficientStockException(
            'Total quantity ($newQuantity) would exceed available stock (${product.availableQuantity})',
          );
        }

        // Try to reserve additional quantity
        final reservationResult = await _reservationService.reserveInventory(
          productId: productId,
          quantity: quantity,
        );

        if (!reservationResult.success) {
          throw InsufficientStockException(
            reservationResult.error ?? 'Failed to reserve inventory',
          );
        }

        _items[productId] = existingItem.copyWith(quantity: newQuantity);
      } else {
        // Try to reserve inventory first
        final reservationResult = await _reservationService.reserveInventory(
          productId: productId,
          quantity: quantity,
        );

        if (!reservationResult.success) {
          throw InsufficientStockException(
            reservationResult.error ?? 'Failed to reserve inventory',
          );
        }

        // Add new item
        final cartItem = CartItem(
          product: product,
          quantity: quantity,
          addedAt: DateTime.now(),
        );
        _items[productId] = cartItem;
      }

      await _saveCartToStorage();
      notifyListeners();
    } catch (e) {
      if (e is CartException) {
        rethrow;
      }
      throw CartOperationException('Failed to add item to cart: $e');
    }
  }

  /// Update quantity of a specific product in cart
  Future<void> updateQuantity(String productId, int quantity) async {
    try {
      if (quantity < 0) {
        throw InvalidQuantityException('Quantity cannot be negative');
      }

      if (!_items.containsKey(productId)) {
        throw ProductNotInCartException('Product not found in cart');
      }

      final cartItem = _items[productId]!;

      if (quantity == 0) {
        // Remove item if quantity is 0
        await removeFromCart(productId);
        return;
      }

      if (quantity > cartItem.product.quantity) {
        throw InsufficientStockException(
          'Requested quantity ($quantity) exceeds available stock (${cartItem.product.quantity})',
        );
      }

      _items[productId] = cartItem.copyWith(quantity: quantity);

      await _saveCartToStorage();
      notifyListeners();
    } catch (e) {
      if (e is CartException) {
        rethrow;
      }
      throw CartOperationException('Failed to update quantity: $e');
    }
  }

  /// Remove a product from cart and release reservation
  Future<void> removeFromCart(String productId) async {
    try {
      if (!_items.containsKey(productId)) {
        throw ProductNotInCartException('Product not found in cart');
      }

      // Release any active reservations for this product
      final reservation = _reservationService.getReservationForProduct(
        productId,
      );
      if (reservation != null) {
        await _reservationService.releaseReservation(reservation.id);
      }

      _items.remove(productId);

      await _saveCartToStorage();
      notifyListeners();
    } catch (e) {
      if (e is CartException) {
        rethrow;
      }
      throw CartOperationException('Failed to remove item from cart: $e');
    }
  }

  /// Clear all items from cart and release all reservations
  Future<void> clearCart() async {
    try {
      // Release all active reservations
      await _reservationService.releaseAllReservations();

      _items.clear();
      await _saveCartToStorage();
      notifyListeners();
    } catch (e) {
      throw CartOperationException('Failed to clear cart: $e');
    }
  }

  /// Check if a product is in cart
  bool isInCart(String productId) {
    return _items.containsKey(productId);
  }

  /// Get quantity of a specific product in cart
  int getQuantityInCart(String productId) {
    return _items[productId]?.quantity ?? 0;
  }

  /// Get cart item for a specific product
  CartItem? getCartItem(String productId) {
    return _items[productId];
  }

  /// Increment quantity of a product by 1
  Future<void> incrementQuantity(String productId) async {
    final currentQuantity = getQuantityInCart(productId);
    await updateQuantity(productId, currentQuantity + 1);
  }

  /// Decrement quantity of a product by 1
  Future<void> decrementQuantity(String productId) async {
    final currentQuantity = getQuantityInCart(productId);
    if (currentQuantity > 1) {
      await updateQuantity(productId, currentQuantity - 1);
    } else {
      await removeFromCart(productId);
    }
  }

  /// Get cart summary
  CartSummary getCartSummary() {
    return CartSummary(
      totalItems: totalItems,
      uniqueItemCount: uniqueItemCount,
      totalPrice: totalPrice,
      items: items,
    );
  }

  /// Validate cart items against current product data
  Future<List<CartValidationIssue>> validateCart(
    List<Product> currentProducts,
  ) async {
    final issues = <CartValidationIssue>[];
    final productMap = {
      for (var product in currentProducts) product.id: product,
    };

    for (final cartItem in _items.values) {
      final currentProduct = productMap[cartItem.product.id];

      if (currentProduct == null) {
        issues.add(
          CartValidationIssue(
            productId: cartItem.product.id,
            type: CartValidationIssueType.productNotFound,
            message:
                'Product "${cartItem.product.name}" is no longer available',
          ),
        );
        continue;
      }

      if (!currentProduct.isActive) {
        issues.add(
          CartValidationIssue(
            productId: cartItem.product.id,
            type: CartValidationIssueType.productInactive,
            message: 'Product "${cartItem.product.name}" is no longer active',
          ),
        );
        continue;
      }

      if (cartItem.quantity > currentProduct.quantity) {
        issues.add(
          CartValidationIssue(
            productId: cartItem.product.id,
            type: CartValidationIssueType.insufficientStock,
            message:
                'Only ${currentProduct.quantity} units of "${cartItem.product.name}" are available (you have ${cartItem.quantity} in cart)',
          ),
        );
      }

      if (currentProduct.price != cartItem.product.price) {
        issues.add(
          CartValidationIssue(
            productId: cartItem.product.id,
            type: CartValidationIssueType.priceChanged,
            message:
                'Price of "${cartItem.product.name}" has changed from \$${cartItem.product.price} to \$${currentProduct.price}',
          ),
        );
      }
    }

    return issues;
  }

  /// Fix common cart validation issues
  Future<void> fixCartIssues(List<CartValidationIssue> issues) async {
    for (final issue in issues) {
      switch (issue.type) {
        case CartValidationIssueType.productNotFound:
        case CartValidationIssueType.productInactive:
          await removeFromCart(issue.productId);
          break;
        case CartValidationIssueType.insufficientStock:
          // This would need additional logic to determine the correct quantity
          // For now, we'll leave it to the user to decide
          break;
        case CartValidationIssueType.priceChanged:
          // Update the product data in the cart item
          // This would need the current product data
          break;
      }
    }
  }

  /// Load cart from persistent storage
  Future<void> _loadCartFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString(_cartKey);

      if (cartData != null) {
        final jsonData = json.decode(cartData) as Map<String, dynamic>;
        final items = jsonData['items'] as List<dynamic>;

        _items.clear();
        for (final itemData in items) {
          final cartItem = CartItem.fromJson(itemData as Map<String, dynamic>);
          _items[cartItem.product.id] = cartItem;
        }
      }
    } catch (e) {
      debugPrint('Error loading cart from storage: $e');
      // Don't throw error, just start with empty cart
    }
  }

  /// Save cart to persistent storage
  Future<void> _saveCartToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = {
        'items': _items.values.map((item) => item.toJson()).toList(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      await prefs.setString(_cartKey, json.encode(cartData));
    } catch (e) {
      debugPrint('Error saving cart to storage: $e');
      // Don't throw error, cart will still work in memory
    }
  }

  /// Prepare cart for checkout by confirming all reservations
  Future<Map<String, String>> prepareCheckout() async {
    final reservationIds = <String, String>{};

    try {
      for (final item in _items.values) {
        final reservation = _reservationService.getReservationForProduct(
          item.product.id,
        );
        if (reservation != null && reservation.isActive) {
          reservationIds[item.product.id] = reservation.id;
        } else {
          // If no active reservation, try to create one
          final result = await _reservationService.reserveInventory(
            productId: item.product.id,
            quantity: item.quantity,
          );

          if (result.success && result.reservationId != null) {
            reservationIds[item.product.id] = result.reservationId!;
          } else {
            throw CartOperationException(
              'Failed to reserve ${item.product.name}: ${result.error}',
            );
          }
        }
      }

      return reservationIds;
    } catch (e) {
      // If any reservation fails, release all successful ones
      for (final reservationId in reservationIds.values) {
        await _reservationService.releaseReservation(reservationId);
      }
      rethrow;
    }
  }

  /// Confirm checkout by converting reservations to order
  Future<void> confirmCheckout(
    String orderId,
    Map<String, String> reservationIds,
  ) async {
    try {
      for (final entry in reservationIds.entries) {
        await _reservationService.confirmReservation(entry.value, orderId);
      }

      // Clear cart after successful checkout
      await clearCart();
    } catch (e) {
      throw CartOperationException('Failed to confirm checkout: $e');
    }
  }

  /// Cancel checkout and release reservations
  Future<void> cancelCheckout(Map<String, String> reservationIds) async {
    for (final reservationId in reservationIds.values) {
      await _reservationService.releaseReservation(reservationId);
    }
  }
}

/// Cart summary information
class CartSummary {
  final int totalItems;
  final int uniqueItemCount;
  final double totalPrice;
  final List<CartItem> items;

  const CartSummary({
    required this.totalItems,
    required this.uniqueItemCount,
    required this.totalPrice,
    required this.items,
  });

  /// Check if cart is empty
  bool get isEmpty => totalItems == 0;

  /// Get formatted total price
  String get formattedTotalPrice => '\$${totalPrice.toStringAsFixed(2)}';
}
