import 'package:flutter/material.dart';
import '../models/inventory_reservation.dart';

/// Interface for inventory reservation services
/// This allows switching between mock and real implementations
abstract class InventoryReservationInterface extends ChangeNotifier {
  /// Get all active reservations
  List<InventoryReservation> get activeReservations;

  /// Reserve inventory for a product
  Future<ReservationResponse> reserveInventory({
    required String productId,
    required int quantity,
    String? sessionId,
    Duration? duration,
    Map<String, dynamic>? metadata,
  });

  /// Reserve multiple products in a single transaction
  Future<Map<String, ReservationResponse>> reserveMultipleProducts(
    List<ReservationRequest> requests,
  );

  /// Release a specific reservation
  Future<bool> releaseReservation(String reservationId);

  /// Release all active reservations for the current user
  Future<void> releaseAllReservations();

  /// Confirm a reservation by converting it to an order
  Future<bool> confirmReservation(String reservationId, String orderId);

  /// Extend a reservation's expiry time
  Future<bool> extendReservation(String reservationId, Duration extension);

  /// Get product availability considering reservations
  Future<int> getProductAvailability(String productId);

  /// Get all reservations for current user
  Future<List<InventoryReservation>> getUserReservations();

  /// Get reservation for a specific product by current user
  InventoryReservation? getReservationForProduct(String productId);

  /// Get total reserved quantity for a product by current user
  int getReservedQuantityForProduct(String productId);

  /// Check if user has active reservations
  bool get hasActiveReservations;

  /// Get count of active reservations
  int get activeReservationCount;

  /// Clean up expired reservations from the local cache
  void cleanupExpiredReservations();
}
