import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/inventory_reservation.dart';
import '../services/auth_service.dart';

/// Service for managing inventory reservations
class InventoryReservationService extends ChangeNotifier {
  static const String _baseUrl =
      'https://22913m3uxj.execute-api.us-east-1.amazonaws.com/dev';
  static const Duration _defaultReservationDuration = Duration(minutes: 15);

  final Map<String, InventoryReservation> _activeReservations = {};
  final AuthService _authService;

  InventoryReservationService({required AuthService authService})
    : _authService = authService;

  /// Get all active reservations
  List<InventoryReservation> get activeReservations =>
      _activeReservations.values.where((r) => r.isActive).toList();

  /// Reserve inventory for a product
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

      final request = ReservationRequest(
        productId: productId,
        quantity: quantity,
        sessionId: sessionId ?? _generateSessionId(),
        duration: duration ?? _defaultReservationDuration,
        metadata: metadata,
      );

      final response = await _makeApiCall(
        'POST',
        '/inventory/reserve',
        body: request.toJson(),
      );

      if (response['success'] == true) {
        final reservation = InventoryReservation.fromJson(
          response['reservation'],
        );
        _activeReservations[reservation.id] = reservation;

        // Schedule automatic cleanup
        _scheduleCleanup(reservation);

        notifyListeners();
        return ReservationResponse(
          success: true,
          reservationId: reservation.id,
        );
      } else {
        return ReservationResponse(
          success: false,
          error: response['error'] ?? 'Failed to reserve inventory',
        );
      }
    } catch (e) {
      debugPrint('Error reserving inventory: $e');
      return ReservationResponse(success: false, error: 'Network error: $e');
    }
  }

  /// Reserve multiple products in a single transaction
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

      final response = await _makeApiCall(
        'POST',
        '/inventory/reserve/bulk',
        body: {'reservations': requests.map((r) => r.toJson()).toList()},
      );

      final results = <String, ReservationResponse>{};

      if (response['success'] == true) {
        final reservations = response['reservations'] as Map<String, dynamic>;

        for (final entry in reservations.entries) {
          final productId = entry.key;
          final reservationData = entry.value as Map<String, dynamic>;

          if (reservationData['success'] == true) {
            final reservation = InventoryReservation.fromJson(
              reservationData['reservation'],
            );
            _activeReservations[reservation.id] = reservation;
            _scheduleCleanup(reservation);

            results[productId] = ReservationResponse(
              success: true,
              reservationId: reservation.id,
            );
          } else {
            results[productId] = ReservationResponse(
              success: false,
              error: reservationData['error'] ?? 'Failed to reserve inventory',
            );
          }
        }
      } else {
        // If bulk operation fails, return error for all
        for (final request in requests) {
          results[request.productId] = ReservationResponse(
            success: false,
            error: response['error'] ?? 'Bulk reservation failed',
          );
        }
      }

      // If some reservations failed, release the successful ones
      if (results.values.any((r) => !r.success)) {
        await _releaseSuccessfulReservations(results);
      }

      notifyListeners();
      return results;
    } catch (e) {
      debugPrint('Error reserving multiple products: $e');
      return {
        for (final request in requests)
          request.productId: ReservationResponse(
            success: false,
            error: 'Network error: $e',
          ),
      };
    }
  }

  /// Release a specific reservation
  Future<bool> releaseReservation(String reservationId) async {
    try {
      final response = await _makeApiCall(
        'DELETE',
        '/inventory/reserve/$reservationId',
      );

      if (response['success'] == true) {
        _activeReservations.remove(reservationId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error releasing reservation: $e');
      return false;
    }
  }

  /// Release all active reservations for the current user
  Future<void> releaseAllReservations() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) return;

      final response = await _makeApiCall(
        'DELETE',
        '/inventory/reserve/user/${user.userId}',
      );

      if (response['success'] == true) {
        _activeReservations.clear();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error releasing all reservations: $e');
    }
  }

  /// Confirm a reservation by converting it to an order
  Future<bool> confirmReservation(String reservationId, String orderId) async {
    try {
      final response = await _makeApiCall(
        'POST',
        '/inventory/reserve/$reservationId/confirm',
        body: {'orderId': orderId},
      );

      if (response['success'] == true) {
        final reservation = _activeReservations[reservationId];
        if (reservation != null) {
          _activeReservations[reservationId] = reservation.copyWith(
            status: ReservationStatus.confirmed,
            orderId: orderId,
            confirmedAt: DateTime.now(),
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error confirming reservation: $e');
      return false;
    }
  }

  /// Extend a reservation's expiry time
  Future<bool> extendReservation(
    String reservationId,
    Duration extension,
  ) async {
    try {
      final response = await _makeApiCall(
        'POST',
        '/inventory/reserve/$reservationId/extend',
        body: {'extensionMinutes': extension.inMinutes},
      );

      if (response['success'] == true) {
        final reservation = _activeReservations[reservationId];
        if (reservation != null) {
          _activeReservations[reservationId] = reservation.copyWith(
            expiresAt: reservation.expiresAt.add(extension),
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error extending reservation: $e');
      return false;
    }
  }

  /// Get product availability considering reservations
  Future<int> getProductAvailability(String productId) async {
    try {
      final response = await _makeApiCall(
        'GET',
        '/inventory/availability/$productId',
      );

      if (response['success'] == true) {
        return response['availableQuantity'] as int;
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting product availability: $e');
      return 0;
    }
  }

  /// Get all reservations for current user
  Future<List<InventoryReservation>> getUserReservations() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) return [];

      final response = await _makeApiCall(
        'GET',
        '/inventory/reserve/user/${user.userId}',
      );

      if (response['success'] == true) {
        final reservations =
            (response['reservations'] as List)
                .map((data) => InventoryReservation.fromJson(data))
                .toList();

        // Update local cache
        for (final reservation in reservations) {
          if (reservation.isActive) {
            _activeReservations[reservation.id] = reservation;
            _scheduleCleanup(reservation);
          }
        }

        notifyListeners();
        return reservations;
      }
      return [];
    } catch (e) {
      debugPrint('Error getting user reservations: $e');
      return [];
    }
  }

  /// Make HTTP API call to backend
  Future<Map<String, dynamic>> _makeApiCall(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      // Get the ID token properly and validate it
      final token = await _authService.getIdToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'error': 'Failed to retrieve authentication token',
        };
      }

      // Debug: Log token format (first/last few characters only for security)
      debugPrint(
        'Token format check - starts with: ${token.substring(0, 10)}..., ends with: ...${token.substring(token.length - 10)}',
      );

      // Ensure the token doesn't contain any invalid characters that could cause parsing issues
      final cleanToken = token.trim();

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $cleanToken',
      };

      // Debug: Log headers (without exposing the full token)
      debugPrint('Request headers: ${headers.keys.join(', ')}');
      debugPrint(
        'Authorization header format: Bearer [TOKEN_LENGTH:${cleanToken.length}]',
      );

      final uri = Uri.parse('$_baseUrl$endpoint');
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }

      // Debug: Log response details
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response headers: ${response.headers}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        // Enhanced error logging
        debugPrint(
          'API call failed - Status: ${response.statusCode}, Body: ${response.body}',
        );
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      debugPrint('Network error in _makeApiCall: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
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

  /// Release successful reservations when bulk operation fails
  Future<void> _releaseSuccessfulReservations(
    Map<String, ReservationResponse> results,
  ) async {
    for (final entry in results.entries) {
      if (entry.value.success && entry.value.reservationId != null) {
        await releaseReservation(entry.value.reservationId!);
      }
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

  @override
  void dispose() {
    _activeReservations.clear();
    super.dispose();
  }
}
