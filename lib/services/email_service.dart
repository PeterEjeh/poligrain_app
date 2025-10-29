import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../models/order.dart';
import 'receipt_service.dart';

/// Service for sending emails related to orders and receipts
class EmailService {
  static const String _apiName = 'PoligrainAPI';
  final ReceiptService _receiptService = ReceiptService();

  /// Send order confirmation email with receipt
  Future<bool> sendOrderConfirmationEmail(Order order) async {
    try {
      // Generate receipt data
      final receiptData = await _receiptService.generateReceiptData(order);
      
      // Prepare email data
      final emailData = {
        'type': 'order_confirmation',
        'to': order.customerEmail,
        'customerName': order.customerName,
        'orderId': order.id,
        'orderNumber': order.id.substring(0, 8).toUpperCase(),
        'totalAmount': order.formattedTotalAmount,
        'orderDate': _formatDate(order.createdAt),
        'items': order.items.map((item) => {
          'name': item.productName,
          'quantity': item.quantity,
          'unit': item.unit,
          'unitPrice': item.formattedUnitPrice,
          'totalPrice': item.formattedTotalPrice,
        }).toList(),
        'shippingAddress': {
          'fullName': order.shippingAddress.fullName,
          'addressLine1': order.shippingAddress.addressLine1,
          'addressLine2': order.shippingAddress.addressLine2,
          'city': order.shippingAddress.city,
          'state': order.shippingAddress.state,
          'postalCode': order.shippingAddress.postalCode,
          'country': order.shippingAddress.country,
        },
        'paymentMethod': order.paymentMethod,
        'receiptAttachment': {
          'filename': receiptData['fileName'],
          'content': receiptData['pdfData'],
        },
      };

      // Send email via API
      final response = await Amplify.API
          .post(
            '/emails/send',
            apiName: _apiName,
            body: HttpPayload.json(emailData),
          )
          .response;

      final statusCode = response.statusCode;
      final responseBody = response.decodeBody();

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw EmailSendException(
          'Failed to send confirmation email: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
        );
      }

      return true;
    } catch (e) {
      if (e is EmailSendException) {
        rethrow;
      }
      throw EmailSendException('Failed to send order confirmation email: $e');
    }
  }

  /// Send order status update email
  Future<bool> sendOrderStatusUpdateEmail(Order order, String previousStatus) async {
    try {
      final emailData = {
        'type': 'order_status_update',
        'to': order.customerEmail,
        'customerName': order.customerName,
        'orderId': order.id,
        'orderNumber': order.id.substring(0, 8).toUpperCase(),
        'previousStatus': previousStatus,
        'newStatus': order.status.displayName,
        'statusMessage': _getStatusMessage(order.status),
        'trackingNumber': order.trackingNumber,
        'estimatedDelivery': order.estimatedDeliveryDate?.toIso8601String(),
      };

      final response = await Amplify.API
          .post(
            '/emails/send',
            apiName: _apiName,
            body: HttpPayload.json(emailData),
          )
          .response;

      final statusCode = response.statusCode;

      if (statusCode >= 400) {
        final responseBody = response.decodeBody();
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw EmailSendException(
          'Failed to send status update email: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
        );
      }

      return true;
    } catch (e) {
      if (e is EmailSendException) {
        rethrow;
      }
      throw EmailSendException('Failed to send order status update email: $e');
    }
  }

  /// Send receipt email only (without full order confirmation)
  Future<bool> sendReceiptEmail(Order order) async {
    try {
      final receiptData = await _receiptService.generateReceiptData(order);
      
      final emailData = {
        'type': 'receipt_only',
        'to': order.customerEmail,
        'customerName': order.customerName,
        'orderId': order.id,
        'orderNumber': order.id.substring(0, 8).toUpperCase(),
        'receiptAttachment': {
          'filename': receiptData['fileName'],
          'content': receiptData['pdfData'],
        },
      };

      final response = await Amplify.API
          .post(
            '/emails/send',
            apiName: _apiName,
            body: HttpPayload.json(emailData),
          )
          .response;

      final statusCode = response.statusCode;

      if (statusCode >= 400) {
        final responseBody = response.decodeBody();
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw EmailSendException(
          'Failed to send receipt email: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
        );
      }

      return true;
    } catch (e) {
      if (e is EmailSendException) {
        rethrow;
      }
      throw EmailSendException('Failed to send receipt email: $e');
    }
  }

  /// Send shipping notification email
  Future<bool> sendShippingNotificationEmail(Order order) async {
    try {
      final emailData = {
        'type': 'shipping_notification',
        'to': order.customerEmail,
        'customerName': order.customerName,
        'orderId': order.id,
        'orderNumber': order.id.substring(0, 8).toUpperCase(),
        'trackingNumber': order.trackingNumber,
        'carrierName': order.carrierName,
        'estimatedDelivery': order.estimatedDeliveryDate?.toIso8601String(),
        'shippingAddress': {
          'fullName': order.shippingAddress.fullName,
          'addressLine1': order.shippingAddress.addressLine1,
          'addressLine2': order.shippingAddress.addressLine2,
          'city': order.shippingAddress.city,
          'state': order.shippingAddress.state,
          'postalCode': order.shippingAddress.postalCode,
          'country': order.shippingAddress.country,
        },
      };

      final response = await Amplify.API
          .post(
            '/emails/send',
            apiName: _apiName,
            body: HttpPayload.json(emailData),
          )
          .response;

      final statusCode = response.statusCode;

      if (statusCode >= 400) {
        final responseBody = response.decodeBody();
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw EmailSendException(
          'Failed to send shipping notification email: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
        );
      }

      return true;
    } catch (e) {
      if (e is EmailSendException) {
        rethrow;
      }
      throw EmailSendException('Failed to send shipping notification email: $e');
    }
  }

  /// Send delivery confirmation email
  Future<bool> sendDeliveryConfirmationEmail(Order order) async {
    try {
      final emailData = {
        'type': 'delivery_confirmation',
        'to': order.customerEmail,
        'customerName': order.customerName,
        'orderId': order.id,
        'orderNumber': order.id.substring(0, 8).toUpperCase(),
        'deliveryDate': order.deliveredAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'feedbackUrl': 'https://poligrain.com/feedback/${order.id}',
      };

      final response = await Amplify.API
          .post(
            '/emails/send',
            apiName: _apiName,
            body: HttpPayload.json(emailData),
          )
          .response;

      final statusCode = response.statusCode;

      if (statusCode >= 400) {
        final responseBody = response.decodeBody();
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw EmailSendException(
          'Failed to send delivery confirmation email: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
        );
      }

      return true;
    } catch (e) {
      if (e is EmailSendException) {
        rethrow;
      }
      throw EmailSendException('Failed to send delivery confirmation email: $e');
    }
  }

  /// Validate email address format
  bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  /// Get status message for order status
  String _getStatusMessage(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Your order has been received and is being processed.';
      case OrderStatus.confirmed:
        return 'Your order has been confirmed and is being prepared.';
      case OrderStatus.processing:
        return 'Your order is currently being processed and will be shipped soon.';
      case OrderStatus.shipped:
        return 'Your order has been shipped and is on its way to you.';
      case OrderStatus.delivered:
        return 'Your order has been successfully delivered. Thank you for your business!';
      case OrderStatus.cancelled:
        return 'Your order has been cancelled. Any charges will be refunded within 3-5 business days.';
      case OrderStatus.refunded:
        return 'Your order has been refunded. The amount will appear in your account within 3-5 business days.';
    }
  }

  /// Format date for email display
  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Generate email template HTML
  String _generateEmailTemplate({
    required String customerName,
    required String subject,
    required String mainContent,
    String? ctaText,
    String? ctaUrl,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$subject</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
        }
        .header {
            background-color: #4CAF50;
            color: white;
            padding: 20px;
            text-align: center;
            border-radius: 8px 8px 0 0;
        }
        .content {
            background-color: #f9f9f9;
            padding: 30px;
            border-radius: 0 0 8px 8px;
        }
        .cta-button {
            display: inline-block;
            background-color: #4CAF50;
            color: white;
            padding: 12px 24px;
            text-decoration: none;
            border-radius: 5px;
            margin: 20px 0;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            color: #666;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>Poligrain</h1>
        <p>$subject</p>
    </div>
    <div class="content">
        <p>Hello $customerName,</p>
        $mainContent
        ${ctaText != null && ctaUrl != null ? '<a href="$ctaUrl" class="cta-button">$ctaText</a>' : ''}
        <p>Thank you for choosing Poligrain!</p>
        <p>Best regards,<br>The Poligrain Team</p>
    </div>
    <div class="footer">
        <p>Poligrain - Your trusted agricultural marketplace</p>
        <p>123 Agriculture Street, Lagos, Nigeria</p>
        <p>If you have any questions, please contact us at support@poligrain.com</p>
    </div>
</body>
</html>
    ''';
  }
}

/// Exception thrown when email sending fails
class EmailSendException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const EmailSendException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() => 'EmailSendException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}
