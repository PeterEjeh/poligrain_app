import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:poligrain_app/models/inventory_reservation.dart';
import 'package:poligrain_app/services/inventory_reservation_service.dart';

/// Handler for inventory reservation operations
class InventoryReservationHandler {
  final InventoryReservationService _reservationService;

  InventoryReservationHandler({
    required InventoryReservationService reservationService,
  }) : _reservationService = reservationService;

  /// Handle reservation creation
  Future<Map<String, dynamic>> handleReservation({
    required String productId,
    required int quantity,
    String? sessionId,
    Duration? duration,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final result = await _reservationService.reserveInventory(
        productId: productId,
        quantity: quantity,
        sessionId: sessionId,
        duration: duration,
        metadata: metadata,
      );

      return {
        'success': result.success,
        'reservationId': result.reservationId,
        'error': result.error,
        'details': result.details,
      };
    } catch (e) {
      debugPrint('Error in reservation handler: $e');
      return {'success': false, 'error': 'Handler error: $e'};
    }
  }

  /// Handle bulk reservations
  Future<Map<String, dynamic>> handleBulkReservations({
    required List<ReservationRequest> requests,
  }) async {
    try {
      final results = await _reservationService.reserveMultipleProducts(
        requests,
      );

      return {
        'success': true,
        'reservations': results.map(
          (key, value) => MapEntry(key, {
            'success': value.success,
            'reservationId': value.reservationId,
            'error': value.error,
            'details': value.details,
          }),
        ),
      };
    } catch (e) {
      debugPrint('Error in bulk reservation handler: $e');
      return {'success': false, 'error': 'Handler error: $e'};
    }
  }

  /// Handle reservation release
  Future<Map<String, dynamic>> handleReservationRelease({
    required String reservationId,
  }) async {
    try {
      final success = await _reservationService.releaseReservation(
        reservationId,
      );

      return {
        'success': success,
        'message':
            success
                ? 'Reservation released successfully'
                : 'Failed to release reservation',
      };
    } catch (e) {
      debugPrint('Error in reservation release handler: $e');
      return {'success': false, 'error': 'Handler error: $e'};
    }
  }

  /// Handle reservation confirmation
  Future<Map<String, dynamic>> handleReservationConfirmation({
    required String reservationId,
    required String orderId,
  }) async {
    try {
      final success = await _reservationService.confirmReservation(
        reservationId,
        orderId,
      );

      return {
        'success': success,
        'message':
            success
                ? 'Reservation confirmed successfully'
                : 'Failed to confirm reservation',
      };
    } catch (e) {
      debugPrint('Error in reservation confirmation handler: $e');
      return {'success': false, 'error': 'Handler error: $e'};
    }
  }

  /// Handle getting product availability
  Future<Map<String, dynamic>> handleProductAvailability({
    required String productId,
  }) async {
    try {
      final availability = await _reservationService.getProductAvailability(
        productId,
      );

      return {
        'success': true,
        'productId': productId,
        'availableQuantity': availability,
      };
    } catch (e) {
      debugPrint('Error in product availability handler: $e');
      return {
        'success': false,
        'error': 'Handler error: $e',
        'availableQuantity': 0,
      };
    }
  }

  /// Handle getting user reservations
  Future<Map<String, dynamic>> handleUserReservations() async {
    try {
      final reservations = await _reservationService.getUserReservations();

      return {
        'success': true,
        'reservations': reservations.map((r) => r.toJson()).toList(),
      };
    } catch (e) {
      debugPrint('Error in user reservations handler: $e');
      return {
        'success': false,
        'error': 'Handler error: $e',
        'reservations': [],
      };
    }
  }

  /// Handle releasing all user reservations
  Future<Map<String, dynamic>> handleReleaseAllReservations() async {
    try {
      await _reservationService.releaseAllReservations();

      return {
        'success': true,
        'message': 'All reservations released successfully',
      };
    } catch (e) {
      debugPrint('Error in release all reservations handler: $e');
      return {'success': false, 'error': 'Handler error: $e'};
    }
  }
}
