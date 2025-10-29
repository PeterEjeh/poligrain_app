// INVENTORY RESERVATIONS USAGE EXAMPLES
// This file shows how to use the new inventory reservation system

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/inventory_reservation.dart';
import '../services/inventory_reservation_interface.dart';
import '../services/mock_inventory_reservation_service.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../exceptions/cart_exceptions.dart';

class InventoryReservationExamples {
  final InventoryReservationInterface _reservationService;
  final CartService _cartService;
  final OrderService _orderService;

  InventoryReservationExamples({
    required InventoryReservationInterface reservationService,
    required CartService cartService,
    required OrderService orderService,
  }) : _reservationService = reservationService,
       _cartService = cartService,
       _orderService = orderService;

  /// Example 1: Add product to cart with automatic reservation
  Future<void> addToCartExample(Product product, int quantity) async {
    try {
      // The cart service now automatically creates reservations
      await _cartService.addToCart(product, quantity: quantity);

      print('✅ Added ${product.name} to cart with reservation');
      print('Available quantity: ${product.availableQuantity}');
      print('Total quantity: ${product.quantity}');
      print('Reserved quantity: ${product.reservedQuantity}');
    } catch (e) {
      print('❌ Failed to add to cart: $e');
    }
  }

  /// Example 2: Check product availability before showing to user
  Future<bool> checkAvailabilityExample(String productId) async {
    try {
      final availableQuantity = await _reservationService
          .getProductAvailability(productId);

      if (availableQuantity > 0) {
        print('✅ Product available: $availableQuantity units');
        return true;
      } else {
        print('❌ Product out of stock');
        return false;
      }
    } catch (e) {
      print('❌ Error checking availability: $e');
      return false;
    }
  }

  /// Example 3: Manual reservation creation (advanced use case)
  Future<String?> createManualReservationExample(
    String productId,
    int quantity,
  ) async {
    try {
      final response = await _reservationService.reserveInventory(
        productId: productId,
        quantity: quantity,
        duration: Duration(minutes: 20), // Custom duration
        metadata: {
          'source': 'manual_reservation',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.success) {
        print('✅ Reservation created: ${response.reservationId}');
        return response.reservationId;
      } else {
        print('❌ Reservation failed: ${response.error}');
        return null;
      }
    } catch (e) {
      print('❌ Error creating reservation: $e');
      return null;
    }
  }

  /// Example 4: Complete checkout workflow with reservations
  Future<void> checkoutWorkflowExample() async {
    try {
      print('🛒 Starting checkout workflow...');

      // Step 1: Prepare checkout (confirms all cart reservations)
      final reservationIds = await _cartService.prepareCheckout();
      print('✅ Reservations confirmed: ${reservationIds.length} items');

      // Step 2: Create order with reservation IDs
      final order = await _orderService.createOrder(
        items:
            _cartService.items
                .map(
                  (item) => {
                    'productId': item.product.id,
                    'quantity': item.quantity,
                    'unitPrice': item.product.price,
                  },
                )
                .toList(),
        totalAmount: _cartService.totalPrice,
        deliveryAddress: 'Sample delivery address',
        reservationIds: reservationIds,
      );

      // Step 3: Confirm checkout (converts reservations to permanent inventory reduction)
      await _cartService.confirmCheckout(order.id, reservationIds);

      print('✅ Order created successfully: ${order.id}');
      print('✅ Cart cleared and reservations confirmed');
    } catch (e) {
      print('❌ Checkout failed: $e');

      // Cleanup: Cancel any created reservations
      await _cartService.cancelCheckout({});
    }
  }

  /// Example 5: Handle reservation expiry in UI
  Widget buildReservationTimerWidget(InventoryReservation reservation) {
    return StreamBuilder<DateTime>(
      stream: Stream.periodic(Duration(seconds: 1), (_) => DateTime.now()),
      builder: (context, snapshot) {
        final remaining = reservation.remainingTime;

        if (remaining == Duration.zero) {
          return Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '⚠️ Reservation Expired',
              style: TextStyle(color: Colors.red.shade800),
            ),
          );
        }

        final minutes = remaining.inMinutes;
        final seconds = remaining.inSeconds % 60;

        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: minutes < 2 ? Colors.orange.shade100 : Colors.green.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer,
                size: 16,
                color:
                    minutes < 2
                        ? Colors.orange.shade800
                        : Colors.green.shade800,
              ),
              SizedBox(width: 4),
              Text(
                'Reserved: ${minutes}:${seconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color:
                      minutes < 2
                          ? Colors.orange.shade800
                          : Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Example 6: Bulk operations for multiple products
  Future<void> bulkReservationExample(List<Product> products) async {
    try {
      final requests =
          products
              .map(
                (product) => ReservationRequest(
                  productId: product.id,
                  quantity: 1,
                  duration: Duration(minutes: 15),
                  metadata: {'bulk_operation': true},
                ),
              )
              .toList();

      final results = await _reservationService.reserveMultipleProducts(
        requests,
      );

      int successful = 0;
      int failed = 0;

      for (final entry in results.entries) {
        if (entry.value.success) {
          successful++;
          print('✅ Reserved ${entry.key}');
        } else {
          failed++;
          print('❌ Failed to reserve ${entry.key}: ${entry.value.error}');
        }
      }

      print(
        '📊 Bulk reservation result: $successful successful, $failed failed',
      );
    } catch (e) {
      print('❌ Bulk reservation error: $e');
    }
  }

  /// Example 7: Monitor active reservations
  Future<void> monitorReservationsExample() async {
    try {
      final reservations = await _reservationService.getUserReservations();

      print('📋 Active Reservations Summary:');
      print('Total reservations: ${reservations.length}');

      final activeReservations = reservations.where((r) => r.isActive).toList();
      print('Active reservations: ${activeReservations.length}');

      for (final reservation in activeReservations) {
        print(
          '  - ${reservation.productId}: ${reservation.quantity} units, expires in ${reservation.formattedRemainingTime}',
        );
      }

      final expiredCount = reservations.where((r) => r.isExpired).length;
      if (expiredCount > 0) {
        print(
          '⚠️ Expired reservations: $expiredCount (will be cleaned up automatically)',
        );
      }
    } catch (e) {
      print('❌ Error monitoring reservations: $e');
    }
  }

  /// Example 8: Error handling patterns
  Future<void> errorHandlingExample(Product product) async {
    try {
      await _cartService.addToCart(product, quantity: 999);
    } on InsufficientStockException catch (e) {
      // Handle specific inventory error
      print('📦 Not enough inventory: ${e.message}');

      // Show user available quantity
      final available = product.availableQuantity;
      print('💡 Available quantity: $available');

      if (available > 0) {
        // Offer to add available quantity instead
        await _cartService.addToCart(product, quantity: available);
        print('✅ Added available quantity instead');
      }
    } on CartOperationException catch (e) {
      // Handle general cart errors
      print('🛒 Cart operation failed: ${e.message}');
    } catch (e) {
      // Handle unexpected errors
      print('❌ Unexpected error: $e');
    }
  }

  /// Example 9: Real-time inventory updates
  void setupInventoryListener(String productId) {
    // Simulate real-time updates (in real app, use WebSocket or polling)
    Timer.periodic(Duration(seconds: 30), (timer) async {
      try {
        final availability = await _reservationService.getProductAvailability(
          productId,
        );
        print(
          '📊 Real-time update - Product $productId availability: $availability',
        );

        // Update UI or notify user if needed
        if (availability == 0) {
          print('⚠️ Product $productId is now out of stock');
          // Show notification to user
        }
      } catch (e) {
        print('❌ Error updating inventory: $e');
      }
    });
  }

  /// Example 10: Cleanup and maintenance
  Future<void> cleanupExample() async {
    try {
      // Clean up expired reservations locally
      _reservationService.cleanupExpiredReservations();

      // Release all user reservations (e.g., when user logs out)
      await _reservationService.releaseAllReservations();

      print('✅ Cleanup completed');
    } catch (e) {
      print('❌ Cleanup error: $e');
    }
  }
}

// Usage in your app:
/*
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MockInventoryReservationService()),
        ChangeNotifierProvider(
          create: (context) => CartService(
            reservationService: context.read<MockInventoryReservationService>(),
          ),
        ),
        Provider(create: (_) => OrderService()),
      ],
      child: MaterialApp(
        home: ShoppingScreen(),
      ),
    );
  }
}
*/
