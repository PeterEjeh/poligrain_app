import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inventory_reservation.dart';
import '../services/auth_service.dart';
import 'inventory_reservation_interface.dart';

/// Mock service for managing inventory reservations (local simulation)
/// This replaces the API-based InventoryReservationService until backend is implemented
class MockInventoryReservationService extends ChangeNotifier
    implements InventoryReservationInterface {
  static const String _reservationsKey = 'mock_reservations';
  static const Duration _defaultReservationDuration = Duration(minutes: 15);

  final Map<String, InventoryReservation> _activeReservations = {};
  final AuthService _authService;

  MockInventoryReservationService({required AuthService authService})
    : _authService = authService;

  /// Get all active reservations
  List<InventoryReservation> get activeReservations =>
      _activeReservations.values.where((r) => r.isActive).toList();

  /// Initialize the service and load persisted reservations
  Future<void> initialize() async {
    await _loadReservationsFromStorage();
  }

  /// Reserve inventory for a product (mock implementation)
  Future<ReservationResponse> reserveInventory({
    required String productId,
    required int quantity,
    String? sessionId,
    Duration? duration,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        return const ReservationResponse(
          success: false,
          error: 'User not authenticated',
        );
      }

      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Create mock reservation
      final reservationId = _generateReservationId();
      final reservation = InventoryReservation(
        id: reservationId,
        productId: productId,
        userId: user.userId,
        quantity: quantity,
        sessionId: sessionId ?? _generateSessionId(),
        status: ReservationStatus.active,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(duration ?? _defaultReservationDuration),
        metadata: metadata,
      );

      _activeReservations[reservationId] = reservation;
      await _saveReservationsToStorage();

      // Schedule automatic cleanup
      _scheduleCleanup(reservation);

      notifyListeners();
      return ReservationResponse(success: true, reservationId: reservationId);
    } catch (e) {
      debugPrint('Error reserving inventory: $e');
      return ReservationResponse(success: false, error: 'Mock error: $e');
    }
  }

  /// Reserve multiple products in a single transaction (mock implementation)
  Future<Map<String, ReservationResponse>> reserveMultipleProducts(
    List<ReservationRequest> requests,
  ) async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        return {
          for (final request in requests)
            request.productId: const ReservationResponse(
              success: false,
              error: 'User not authenticated',
            ),
        };
      }

      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 800));

      final results = <String, ReservationResponse>{};

      for (final request in requests) {
        final reservationId = _generateReservationId();
        final reservation = InventoryReservation(
          id: reservationId,
          productId: request.productId,
          userId: user.userId,
          quantity: request.quantity,
          sessionId: request.sessionId,
          status: ReservationStatus.active,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(
            request.duration ?? _defaultReservationDuration,
          ),
          metadata: request.metadata,
        );

        _activeReservations[reservationId] = reservation;
        _scheduleCleanup(reservation);

        results[request.productId] = ReservationResponse(
          success: true,
          reservationId: reservationId,
        );
      }

      await _saveReservationsToStorage();
      notifyListeners();
      return results;
    } catch (e) {
      debugPrint('Error reserving multiple products: $e');
      return {
        for (final request in requests)
          request.productId: ReservationResponse(
            success: false,
            error: 'Mock error: $e',
          ),
      };
    }
  }

  /// Release a specific reservation (mock implementation)
  Future<bool> releaseReservation(String reservationId) async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 300));

      final removed = _activeReservations.remove(reservationId);
      if (removed != null) {
        await _saveReservationsToStorage();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error releasing reservation: $e');
      return false;
    }
  }

  /// Release all active reservations for the current user (mock implementation)
  Future<void> releaseAllReservations() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) return;

      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 400));

      _activeReservations.removeWhere(
        (key, reservation) => reservation.userId == user.userId,
      );

      await _saveReservationsToStorage();
      notifyListeners();
    } catch (e) {
      debugPrint('Error releasing all reservations: $e');
    }
  }

  /// Confirm a reservation by converting it to an order (mock implementation)
  Future<bool> confirmReservation(String reservationId, String orderId) async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 400));

      final reservation = _activeReservations[reservationId];
      if (reservation != null) {
        _activeReservations[reservationId] = reservation.copyWith(
          status: ReservationStatus.confirmed,
          orderId: orderId,
          confirmedAt: DateTime.now(),
        );
        await _saveReservationsToStorage();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error confirming reservation: $e');
      return false;
    }
  }

  /// Extend a reservation's expiry time (mock implementation)
  Future<bool> extendReservation(
    String reservationId,
    Duration extension,
  ) async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 300));

      final reservation = _activeReservations[reservationId];
      if (reservation != null) {
        _activeReservations[reservationId] = reservation.copyWith(
          expiresAt: reservation.expiresAt.add(extension),
        );
        await _saveReservationsToStorage();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error extending reservation: $e');
      return false;
    }
  }

  /// Get product availability considering reservations (mock implementation)
  Future<int> getProductAvailability(String productId) async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 200));

      // Mock: Return a random availability between 0-100
      final random = Random();
      return random.nextInt(101);
    } catch (e) {
      debugPrint('Error getting product availability: $e');
      return 0;
    }
  }

  /// Get all reservations for current user (mock implementation)
  Future<List<InventoryReservation>> getUserReservations() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) return [];

      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 300));

      final userReservations =
          _activeReservations.values
              .where((r) => r.userId == user.userId)
              .toList();

      return userReservations;
    } catch (e) {
      debugPrint('Error getting user reservations: $e');
      return [];
    }
  }

  /// Generate a unique reservation ID
  String _generateReservationId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = random.nextInt(999999).toString().padLeft(6, '0');
    return 'res_${timestamp}_$randomSuffix';
  }

  /// Generate a unique session ID
  String _generateSessionId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = random.nextInt(999999).toString().padLeft(6, '0');
    return 'session_${timestamp}_$randomSuffix';
  }

  /// Schedule automatic cleanup when reservation expires
  void _scheduleCleanup(InventoryReservation reservation) {
    if (!reservation.isActive) return;

    final remaining = reservation.remainingTime;
    if (remaining > Duration.zero) {
      Future.delayed(remaining, () {
        _activeReservations.remove(reservation.id);
        notifyListeners();
      });
    }
  }

  /// Get reservation for a specific product by current user
  InventoryReservation? getReservationForProduct(String productId) {
    return _activeReservations.values.cast<InventoryReservation?>().firstWhere(
      (r) => r != null && r.productId == productId && r.isActive,
      orElse: () => null,
    );
  }

  /// Get total reserved quantity for a product by current user
  int getReservedQuantityForProduct(String productId) {
    return _activeReservations.values
        .where((r) => r.productId == productId && r.isActive)
        .fold(0, (sum, r) => sum + r.quantity);
  }

  /// Check if user has active reservations
  bool get hasActiveReservations =>
      _activeReservations.values.any((r) => r.isActive);

  /// Get count of active reservations
  int get activeReservationCount =>
      _activeReservations.values.where((r) => r.isActive).length;

  /// Clean up expired reservations from the local cache
  void cleanupExpiredReservations() {
    _activeReservations.removeWhere(
      (key, reservation) => reservation.isExpired,
    );
    notifyListeners();
  }

  /// Load reservations from persistent storage
  Future<void> _loadReservationsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reservationsData = prefs.getString(_reservationsKey);

      if (reservationsData != null) {
        final jsonData = json.decode(reservationsData) as Map<String, dynamic>;
        final reservations = jsonData['reservations'] as List<dynamic>;

        _activeReservations.clear();
        for (final reservationData in reservations) {
          final reservation = InventoryReservation.fromJson(
            reservationData as Map<String, dynamic>,
          );

          // Only load active, non-expired reservations
          if (reservation.isActive && !reservation.isExpired) {
            _activeReservations[reservation.id] = reservation;
            _scheduleCleanup(reservation);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading reservations from storage: $e');
      // Don't throw error, just start with empty reservations
    }
  }

  /// Save reservations to persistent storage
  Future<void> _saveReservationsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reservationsData = {
        'reservations':
            _activeReservations.values
                .map((reservation) => reservation.toJson())
                .toList(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      await prefs.setString(_reservationsKey, json.encode(reservationsData));
    } catch (e) {
      debugPrint('Error saving reservations to storage: $e');
      // Don't throw error, reservations will still work in memory
    }
  }

  @override
  void dispose() {
    _activeReservations.clear();
    super.dispose();
  }
}
