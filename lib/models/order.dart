import 'package:meta/meta.dart';
import 'cart_item.dart';
import 'product.dart';

/// Order status enumeration
enum OrderStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  processing('Processing'),
  shipped('Shipped'),
  delivered('Delivered'),
  cancelled('Cancelled'),
  refunded('Refunded');

  const OrderStatus(this.value);
  final String value;

  String get displayName => value;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

/// Payment status enumeration
enum PaymentStatus {
  pending('Pending'),
  paid('Paid'),
  failed('Failed'),
  refunded('Refunded'),
  cancelled('Cancelled');

  const PaymentStatus(this.value);
  final String value;

  String get displayName => value;

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}

/// Represents a customer order with items and status tracking
@immutable
class Order {
  final String id;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double shippingCost;
  final double totalAmount;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final String? paymentMethod;
  final String? transactionId;
  final ShippingAddress shippingAddress;
  final BillingAddress? billingAddress;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? confirmedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final String? trackingNumber;
  final String? carrierName;
  final DateTime? estimatedDeliveryDate;
  final List<OrderStatusHistory> statusHistory;

  const Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.shippingCost,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod,
    this.transactionId,
    required this.shippingAddress,
    this.billingAddress,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.confirmedAt,
    this.shippedAt,
    this.deliveredAt,
    this.trackingNumber,
    this.carrierName,
    this.estimatedDeliveryDate,
    this.statusHistory = const [],
  });

  /// Create Order from JSON
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      customerEmail: json['customerEmail'] as String,
      items:
          (json['items'] as List<dynamic>)
              .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
              .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      shippingCost: (json['shippingCost'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: OrderStatus.fromString(json['status'] as String),
      paymentStatus: PaymentStatus.fromString(json['paymentStatus'] as String),
      paymentMethod: json['paymentMethod'] as String?,
      transactionId: json['transactionId'] as String?,
      shippingAddress: ShippingAddress.fromJson(
        json['shippingAddress'] as Map<String, dynamic>,
      ),
      billingAddress:
          json['billingAddress'] != null
              ? BillingAddress.fromJson(
                json['billingAddress'] as Map<String, dynamic>,
              )
              : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : null,
      confirmedAt:
          json['confirmedAt'] != null
              ? DateTime.parse(json['confirmedAt'] as String)
              : null,
      shippedAt:
          json['shippedAt'] != null
              ? DateTime.parse(json['shippedAt'] as String)
              : null,
      deliveredAt:
          json['deliveredAt'] != null
              ? DateTime.parse(json['deliveredAt'] as String)
              : null,
      trackingNumber: json['trackingNumber'] as String?,
      carrierName: json['carrierName'] as String?,
      estimatedDeliveryDate:
          json['estimatedDeliveryDate'] != null
              ? DateTime.parse(json['estimatedDeliveryDate'] as String)
              : null,
      statusHistory:
          json['statusHistory'] != null
              ? (json['statusHistory'] as List<dynamic>)
                  .map(
                    (history) => OrderStatusHistory.fromJson(
                      history as Map<String, dynamic>,
                    ),
                  )
                  .toList()
              : [],
    );
  }

  /// Convert Order to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'shippingCost': shippingCost,
      'totalAmount': totalAmount,
      'status': status.value,
      'paymentStatus': paymentStatus.value,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'shippingAddress': shippingAddress.toJson(),
      'billingAddress': billingAddress?.toJson(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'confirmedAt': confirmedAt?.toIso8601String(),
      'shippedAt': shippedAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'trackingNumber': trackingNumber,
      'carrierName': carrierName,
      'estimatedDeliveryDate': estimatedDeliveryDate?.toIso8601String(),
      'statusHistory':
          statusHistory.map((history) => history.toJson()).toList(),
    };
  }

  /// Create a copy with updated fields
  Order copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerEmail,
    List<OrderItem>? items,
    double? subtotal,
    double? tax,
    double? shippingCost,
    double? totalAmount,
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    String? paymentMethod,
    String? transactionId,
    ShippingAddress? shippingAddress,
    BillingAddress? billingAddress,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? confirmedAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    String? trackingNumber,
    String? carrierName,
    DateTime? estimatedDeliveryDate,
    List<OrderStatusHistory>? statusHistory,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      shippingCost: shippingCost ?? this.shippingCost,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      billingAddress: billingAddress ?? this.billingAddress,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      confirmedAt: confirmedAt ?? this.confirmedAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      carrierName: carrierName ?? this.carrierName,
      estimatedDeliveryDate:
          estimatedDeliveryDate ?? this.estimatedDeliveryDate,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }

  /// Get formatted total amount
  String get formattedTotalAmount => '\$${totalAmount.toStringAsFixed(2)}';

  /// Get formatted subtotal
  String get formattedSubtotal => '\$${subtotal.toStringAsFixed(2)}';

  /// Get formatted tax amount
  String get formattedTax => '\$${tax.toStringAsFixed(2)}';

  /// Get formatted shipping cost
  String get formattedShippingCost => '\$${shippingCost.toStringAsFixed(2)}';

  /// Get total number of items
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  /// Check if order can be cancelled
  bool get canBeCancelled =>
      status == OrderStatus.pending || status == OrderStatus.confirmed;

  /// Check if order is completed
  bool get isCompleted => status == OrderStatus.delivered;

  /// Check if order is cancelled
  bool get isCancelled => status == OrderStatus.cancelled;

  /// Check if payment is completed
  bool get isPaymentCompleted => paymentStatus == PaymentStatus.paid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Order && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Order{id: $id, status: ${status.value}, total: $totalAmount}';
  }
}

/// Represents an item within an order
@immutable
class OrderItem {
  final String productId;
  final String productName;
  final String productImageUrl;
  final String category;
  final double unitPrice;
  final int quantity;
  final String? unit;
  final String sellerId;
  final String sellerName;
  final double totalPrice;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.category,
    required this.unitPrice,
    required this.quantity,
    this.unit,
    required this.sellerId,
    required this.sellerName,
    required this.totalPrice,
  });

  /// Create OrderItem from CartItem
  factory OrderItem.fromCartItem(CartItem cartItem) {
    return OrderItem(
      productId: cartItem.product.id,
      productName: cartItem.product.name,
      productImageUrl: cartItem.product.imageUrl,
      category: cartItem.product.category,
      unitPrice: cartItem.product.price,
      quantity: cartItem.quantity,
      unit: cartItem.product.unit,
      sellerId: cartItem.product.owner ?? '',
      sellerName: cartItem.product.sellerName ?? 'Unknown Seller',
      totalPrice: cartItem.totalPrice,
    );
  }

  /// Create OrderItem from JSON
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      productImageUrl: json['productImageUrl'] as String,
      category: json['category'] as String,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: json['quantity'] as int,
      unit: json['unit'] as String?,
      sellerId: json['sellerId'] as String,
      sellerName: json['sellerName'] as String,
      totalPrice: (json['totalPrice'] as num).toDouble(),
    );
  }

  /// Convert OrderItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'category': category,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'unit': unit,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'totalPrice': totalPrice,
    };
  }

  /// Get formatted unit price
  String get formattedUnitPrice => '\$${unitPrice.toStringAsFixed(2)}';

  /// Get formatted total price
  String get formattedTotalPrice => '\$${totalPrice.toStringAsFixed(2)}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderItem &&
          runtimeType == other.runtimeType &&
          productId == other.productId;

  @override
  int get hashCode => productId.hashCode;
}

/// Represents shipping address information
@immutable
class ShippingAddress {
  final String fullName;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String? phoneNumber;

  const ShippingAddress({
    required this.fullName,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.phoneNumber,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      fullName: json['fullName'] as String,
      addressLine1: json['addressLine1'] as String,
      addressLine2: json['addressLine2'] as String?,
      city: json['city'] as String,
      state: json['state'] as String,
      postalCode: json['postalCode'] as String,
      country: json['country'] as String,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'phoneNumber': phoneNumber,
    };
  }

  /// Get formatted address string
  String get formattedAddress {
    final buffer = StringBuffer();
    buffer.writeln(fullName);
    buffer.writeln(addressLine1);
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      buffer.writeln(addressLine2);
    }
    buffer.write('$city, $state $postalCode');
    return buffer.toString();
  }
}

/// Represents billing address information
@immutable
class BillingAddress {
  final String fullName;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  const BillingAddress({
    required this.fullName,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
  });

  factory BillingAddress.fromJson(Map<String, dynamic> json) {
    return BillingAddress(
      fullName: json['fullName'] as String,
      addressLine1: json['addressLine1'] as String,
      addressLine2: json['addressLine2'] as String?,
      city: json['city'] as String,
      state: json['state'] as String,
      postalCode: json['postalCode'] as String,
      country: json['country'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
    };
  }
}

/// Represents order status change history
@immutable
class OrderStatusHistory {
  final OrderStatus status;
  final DateTime timestamp;
  final String? notes;
  final String? updatedBy;

  const OrderStatusHistory({
    required this.status,
    required this.timestamp,
    this.notes,
    this.updatedBy,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      status: OrderStatus.fromString(json['status'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      notes: json['notes'] as String?,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.value,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'updatedBy': updatedBy,
    };
  }
}
