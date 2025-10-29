import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../models/order.dart';
import '../exceptions/order_exceptions.dart';
import 'receipt_service.dart';
import 'email_service.dart';

/// Service for managing orders and order operations
class OrderService {
  static const String _apiName = 'PoligrainAPI';
  final ReceiptService _receiptService = ReceiptService();
  final EmailService _emailService = EmailService();

  /// Create a new order with optional reservation IDs
  Future<Order> createOrder({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String deliveryAddress,
    String? notes,
    Map<String, dynamic>? metadata,
    Map<String, String>? reservationIds, // Product ID -> Reservation ID mapping
  }) async {
    try {
      final requestBody = {
        'items': items,
        'totalAmount': totalAmount,
        'deliveryAddress': deliveryAddress,
        if (notes != null) 'notes': notes,
        if (metadata != null) 'metadata': metadata,
        if (reservationIds != null) 'reservationIds': reservationIds,
      };

      final response =
          await Amplify.API
              .post(
                '/orders',
                apiName: _apiName,
                body: HttpPayload.json(requestBody),
              )
              .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw OrderCreationException(
          'Failed to create order: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
          details: errorBody,
        );
      }

      final orderData = json.decode(responseBody) as Map<String, dynamic>;
      final order = Order.fromJson(orderData);

      // Generate receipt and send confirmation email after successful order creation
      try {
        await _sendOrderConfirmationWithReceipt(order);
      } catch (e) {
        // Log the error but don't fail the order creation
        print('Failed to send order confirmation email: $e');
      }

      return order;
    } catch (e) {
      if (e is OrderException) {
        rethrow;
      }
      throw OrderCreationException('Failed to create order: $e');
    }
  }

  /// Get user's order history with pagination and filters
  Future<OrderHistoryResult> getOrderHistory({
    int limit = 20,
    String? lastKey,
    OrderStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (lastKey != null) 'lastKey': lastKey,
        if (status != null) 'status': status.value,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      final response =
          await Amplify.API
              .get('/orders', apiName: _apiName, queryParameters: queryParams)
              .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw OrderFetchException(
          'Failed to fetch orders: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
        );
      }

      final responseData = json.decode(responseBody) as Map<String, dynamic>;
      final orders =
          (responseData['orders'] as List<dynamic>)
              .map(
                (orderData) =>
                    Order.fromJson(orderData as Map<String, dynamic>),
              )
              .toList();

      final pagination = responseData['pagination'] as Map<String, dynamic>;

      return OrderHistoryResult(
        orders: orders,
        hasMore: pagination['hasMore'] as bool,
        nextPageKey: pagination['lastKey'] as String?,
      );
    } catch (e) {
      if (e is OrderException) {
        rethrow;
      }
      throw OrderFetchException('Failed to fetch order history: $e');
    }
  }

  /// Get specific order details by ID
  Future<Order> getOrderDetails(String orderId) async {
    try {
      final response =
          await Amplify.API.get('/orders/$orderId', apiName: _apiName).response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode == 404) {
        throw OrderNotFoundException('Order not found: $orderId');
      }

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw OrderFetchException(
          'Failed to fetch order: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
        );
      }

      final orderData = json.decode(responseBody) as Map<String, dynamic>;
      return Order.fromJson(orderData);
    } catch (e) {
      if (e is OrderException) {
        rethrow;
      }
      throw OrderFetchException('Failed to fetch order details: $e');
    }
  }

  /// Update order status
  Future<Order> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
    String? notes,
  }) async {
    try {
      final requestBody = {
        'status': status.value,
        if (notes != null) 'notes': notes,
      };

      final response =
          await Amplify.API
              .put(
                '/orders/$orderId/status',
                apiName: _apiName,
                body: HttpPayload.json(requestBody),
              )
              .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode == 404) {
        throw OrderNotFoundException('Order not found: $orderId');
      }

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw OrderUpdateException(
          'Failed to update order status: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
        );
      }

      final orderData = json.decode(responseBody) as Map<String, dynamic>;
      return Order.fromJson(orderData);
    } catch (e) {
      if (e is OrderException) {
        rethrow;
      }
      throw OrderUpdateException('Failed to update order status: $e');
    }
  }

  /// Cancel an order
  Future<Order> cancelOrder(String orderId) async {
    try {
      final response =
          await Amplify.API
              .put('/orders/$orderId/cancel', apiName: _apiName)
              .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode == 404) {
        throw OrderNotFoundException('Order not found: $orderId');
      }

      if (statusCode == 403) {
        throw OrderUpdateException('Access denied: Cannot cancel this order');
      }

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw OrderUpdateException(
          'Failed to cancel order: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
        );
      }

      final orderData = json.decode(responseBody) as Map<String, dynamic>;
      return Order.fromJson(orderData);
    } catch (e) {
      if (e is OrderException) {
        rethrow;
      }
      throw OrderUpdateException('Failed to cancel order: $e');
    }
  }

  /// Get orders filtered by status
  Future<List<Order>> getOrdersByStatus(OrderStatus status) async {
    try {
      final result = await getOrderHistory(status: status, limit: 100);
      return result.orders;
    } catch (e) {
      throw OrderFetchException('Failed to fetch orders by status: $e');
    }
  }

  /// Get recent orders (last 10)
  Future<List<Order>> getRecentOrders() async {
    try {
      final result = await getOrderHistory(limit: 10);
      return result.orders;
    } catch (e) {
      throw OrderFetchException('Failed to fetch recent orders: $e');
    }
  }

  /// Check if order can be cancelled
  bool canCancelOrder(Order order) {
    return order.canBeCancelled;
  }

  /// Check if order can be tracked
  bool canTrackOrder(Order order) {
    return order.trackingNumber != null &&
        (order.status == OrderStatus.shipped ||
            order.status == OrderStatus.delivered);
  }

  /// Get order status color for UI
  String getOrderStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return '#FF9800'; // Orange
      case OrderStatus.confirmed:
        return '#2196F3'; // Blue
      case OrderStatus.processing:
        return '#9C27B0'; // Purple
      case OrderStatus.shipped:
        return '#607D8B'; // Blue Grey
      case OrderStatus.delivered:
        return '#4CAF50'; // Green
      case OrderStatus.cancelled:
        return '#F44336'; // Red
      case OrderStatus.refunded:
        return '#795548'; // Brown
    }
  }

  /// Generate and save receipt for an order
  Future<String> generateReceipt(String orderId) async {
    try {
      final order = await getOrderDetails(orderId);
      return await _receiptService.saveReceiptToFile(order);
    } catch (e) {
      throw OrderUpdateException('Failed to generate receipt: $e');
    }
  }

  /// Share receipt for an order
  Future<void> shareReceipt(String orderId) async {
    try {
      final order = await getOrderDetails(orderId);
      await _receiptService.shareReceipt(order);
    } catch (e) {
      throw OrderUpdateException('Failed to share receipt: $e');
    }
  }

  /// Send order confirmation email with receipt
  Future<bool> sendOrderConfirmationEmail(String orderId) async {
    try {
      final order = await getOrderDetails(orderId);
      return await _emailService.sendOrderConfirmationEmail(order);
    } catch (e) {
      throw OrderUpdateException('Failed to send order confirmation email: $e');
    }
  }

  /// Send receipt email only
  Future<bool> sendReceiptEmail(String orderId) async {
    try {
      final order = await getOrderDetails(orderId);
      return await _emailService.sendReceiptEmail(order);
    } catch (e) {
      throw OrderUpdateException('Failed to send receipt email: $e');
    }
  }

  /// Private method to send order confirmation with receipt
  Future<void> _sendOrderConfirmationWithReceipt(Order order) async {
    // Validate email address
    if (!_emailService.isValidEmail(order.customerEmail)) {
      throw OrderUpdateException(
        'Invalid customer email address: ${order.customerEmail}',
      );
    }

    // Send confirmation email with receipt
    await _emailService.sendOrderConfirmationEmail(order);

    print(
      'Order confirmation email sent successfully to ${order.customerEmail}',
    );
  }
}

/// Result object for order history pagination
class OrderHistoryResult {
  final List<Order> orders;
  final bool hasMore;
  final String? nextPageKey;

  const OrderHistoryResult({
    required this.orders,
    required this.hasMore,
    this.nextPageKey,
  });

  /// Check if there are more orders to load
  bool get canLoadMore => hasMore && nextPageKey != null;

  /// Get total number of orders in current page
  int get count => orders.length;
}
