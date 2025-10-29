import 'package:meta/meta.dart';

/// Inventory reservation status enumeration
enum ReservationStatus {
  active('active'),
  expired('expired'),
  confirmed('confirmed'),
  cancelled('cancelled');

  const ReservationStatus(this.value);
  final String value;

  static ReservationStatus fromString(String value) {
    return ReservationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ReservationStatus.active,
    );
  }
}

/// Represents an inventory reservation for products
@immutable
class InventoryReservation {
  final String id;
  final String productId;
  final String userId;
  final String? sessionId;
  final int quantity;
  final ReservationStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final String? orderId; // Set when reservation is confirmed with order
  final Map<String, dynamic>? metadata;

  const InventoryReservation({
    required this.id,
    required this.productId,
    required this.userId,
    this.sessionId,
    required this.quantity,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.confirmedAt,
    this.cancelledAt,
    this.orderId,
    this.metadata,
  });

  /// Create InventoryReservation from JSON
  factory InventoryReservation.fromJson(Map<String, dynamic> json) {
    return InventoryReservation(
      id: json['id'] as String,
      productId: json['productId'] as String,
      userId: json['userId'] as String,
      sessionId: json['sessionId'] as String?,
      quantity: json['quantity'] as int,
      status: ReservationStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'] as String)
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      orderId: json['orderId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert InventoryReservation to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'userId': userId,
      'sessionId': sessionId,
      'quantity': quantity,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'confirmedAt': confirmedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'orderId': orderId,
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  InventoryReservation copyWith({
    String? id,
    String? productId,
    String? userId,
    String? sessionId,
    int? quantity,
    ReservationStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? confirmedAt,
    DateTime? cancelledAt,
    String? orderId,
    Map<String, dynamic>? metadata,
  }) {
    return InventoryReservation(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      orderId: orderId ?? this.orderId,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if reservation is still active and not expired
  bool get isActive => status == ReservationStatus.active && !isExpired;

  /// Check if reservation has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if reservation is confirmed
  bool get isConfirmed => status == ReservationStatus.confirmed;

  /// Check if reservation is cancelled
  bool get isCancelled => status == ReservationStatus.cancelled;

  /// Get remaining time before expiration
  Duration get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) {
      return Duration.zero;
    }
    return expiresAt.difference(now);
  }

  /// Get formatted remaining time
  String get formattedRemainingTime {
    final remaining = remainingTime;
    if (remaining == Duration.zero) return 'Expired';
    
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryReservation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'InventoryReservation{id: $id, productId: $productId, quantity: $quantity, status: ${status.value}}';
  }
}

/// Reservation request for creating new reservations
@immutable
class ReservationRequest {
  final String productId;
  final int quantity;
  final String? sessionId;
  final Duration? duration; // How long to hold the reservation
  final Map<String, dynamic>? metadata;

  const ReservationRequest({
    required this.productId,
    required this.quantity,
    this.sessionId,
    this.duration,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'sessionId': sessionId,
      'durationMinutes': duration?.inMinutes,
      'metadata': metadata,
    };
  }
}

/// Response for reservation operations
@immutable
class ReservationResponse {
  final bool success;
  final String? reservationId;
  final String? error;
  final Map<String, dynamic>? details;

  const ReservationResponse({
    required this.success,
    this.reservationId,
    this.error,
    this.details,
  });

  factory ReservationResponse.fromJson(Map<String, dynamic> json) {
    return ReservationResponse(
      success: json['success'] as bool,
      reservationId: json['reservationId'] as String?,
      error: json['error'] as String?,
      details: json['details'] as Map<String, dynamic>?,
    );
  }
}
