import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/order.dart';

/// Service for generating and managing receipts
class ReceiptService {
  static const String _companyName = 'Poligrain';
  static const String _companyAddress = '''
123 Agriculture Street
Lagos, Nigeria
Phone: +234-123-456-7890
Email: support@poligrain.com
''';

  /// Generate a PDF receipt for an order
  Future<Uint8List> generateReceiptPdf(Order order) async {
    final pdf = pw.Document();

    // Load company logo if available
    pw.ImageProvider? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      // Logo not available, continue without it
      print('Logo not found: $e');
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(logoImage, order),
              pw.SizedBox(height: 20),
              _buildOrderInfo(order),
              pw.SizedBox(height: 20),
              _buildCustomerInfo(order),
              pw.SizedBox(height: 20),
              _buildItemsList(order),
              pw.SizedBox(height: 20),
              _buildTotals(order),
              pw.Spacer(),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Build receipt header with company info
  pw.Widget _buildHeader(pw.ImageProvider? logoImage, Order order) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoImage != null)
              pw.Image(logoImage, width: 80, height: 80)
            else
              pw.Container(
                width: 80,
                height: 80,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                ),
                child: pw.Center(
                  child: pw.Text(
                    _companyName,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            pw.SizedBox(height: 10),
            pw.Text(_companyAddress, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'RECEIPT',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Receipt #${order.id.substring(0, 8).toUpperCase()}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Date: ${_formatDate(order.createdAt)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  /// Build order information section
  pw.Widget _buildOrderInfo(Order order) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Order Information',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Order ID: ${order.id}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Status: ${order.status.displayName}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Payment Status: ${order.paymentStatus.displayName}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Payment Method',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                order.paymentMethod ?? 'N/A',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build customer information section
  pw.Widget _buildCustomerInfo(Order order) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Customer Information',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Name: ${order.customerName}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Email: ${order.customerEmail}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Shipping Address:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  pw.Text(
                    order.shippingAddress.fullName,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    order.shippingAddress.addressLine1,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  if (order.shippingAddress.addressLine2?.isNotEmpty == true)
                    pw.Text(
                      order.shippingAddress.addressLine2!,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  pw.Text(
                    '${order.shippingAddress.city}, ${order.shippingAddress.state}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '${order.shippingAddress.postalCode}, ${order.shippingAddress.country}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build items list section
  pw.Widget _buildItemsList(Order order) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Order Items',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Item', isHeader: true),
                _buildTableCell('Qty', isHeader: true),
                _buildTableCell('Unit Price', isHeader: true),
                _buildTableCell('Total', isHeader: true),
              ],
            ),
            // Item rows
            ...order.items.map(
              (item) => pw.TableRow(
                children: [
                  _buildTableCell(item.productName),
                  _buildTableCell(
                    '${item.quantity}${item.unit != null ? ' ${item.unit}' : ''}',
                  ),
                  _buildTableCell(item.formattedUnitPrice),
                  _buildTableCell(item.formattedTotalPrice),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build table cell
  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Build totals section
  pw.Widget _buildTotals(Order order) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 200,
          child: pw.Column(
            children: [
              _buildTotalRow('Subtotal:', order.formattedSubtotal),
              if (order.tax > 0) _buildTotalRow('Tax:', order.formattedTax),
              if (order.shippingCost > 0)
                _buildTotalRow('Shipping:', order.formattedShippingCost),
              pw.Divider(color: PdfColors.grey),
              _buildTotalRow(
                'Total:',
                order.formattedTotalAmount,
                isTotal: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build total row
  pw.Widget _buildTotalRow(String label, String value, {bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 12 : 10,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isTotal ? 12 : 10,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// Build footer section
  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey),
        pw.SizedBox(height: 10),
        pw.Text(
          'Thank you for your business!',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'For questions about this receipt, please contact us at support@poligrain.com',
          style: const pw.TextStyle(fontSize: 8),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  /// Save receipt to device storage
  Future<String> saveReceiptToFile(Order order) async {
    try {
      final pdfData = await generateReceiptPdf(order);
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String fileName =
          'receipt_${order.id.substring(0, 8)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final String filePath = '${appDocDir.path}/$fileName';

      final File file = File(filePath);
      await file.writeAsBytes(pdfData);

      return filePath;
    } catch (e) {
      throw ReceiptGenerationException('Failed to save receipt to file: $e');
    }
  }

  /// Share receipt via platform sharing
  Future<void> shareReceipt(Order order) async {
    try {
      final String filePath = await saveReceiptToFile(order);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Receipt for Order #${order.id.substring(0, 8)}',
        subject: 'Poligrain Order Receipt',
      );
    } catch (e) {
      throw ReceiptGenerationException('Failed to share receipt: $e');
    }
  }

  /// Generate receipt data for email
  Future<Map<String, dynamic>> generateReceiptData(Order order) async {
    try {
      final pdfData = await generateReceiptPdf(order);

      return {
        'orderId': order.id,
        'receiptNumber': order.id.substring(0, 8).toUpperCase(),
        'customerName': order.customerName,
        'customerEmail': order.customerEmail,
        'totalAmount': order.formattedTotalAmount,
        'orderDate': _formatDate(order.createdAt),
        'pdfData': base64Encode(pdfData),
        'fileName': 'receipt_${order.id.substring(0, 8)}.pdf',
      };
    } catch (e) {
      throw ReceiptGenerationException('Failed to generate receipt data: $e');
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Generate receipt in HTML format for web display
  String generateReceiptHtml(Order order) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Receipt - Order #${order.id.substring(0, 8)}</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            color: #333;
        }
        .header {
            display: flex;
            justify-content: space-between;
            align-items: start;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid #4CAF50;
        }
        .company-info h1 {
            color: #4CAF50;
            margin: 0;
        }
        .receipt-info {
            text-align: right;
        }
        .receipt-info h2 {
            color: #4CAF50;
            margin: 0;
        }
        .info-section {
            background: #f9f9f9;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .customer-info {
            display: flex;
            justify-content: space-between;
            margin-bottom: 20px;
        }
        .items-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        .items-table th,
        .items-table td {
            border: 1px solid #ddd;
            padding: 12px;
            text-align: left;
        }
        .items-table th {
            background-color: #f2f2f2;
            font-weight: bold;
        }
        .totals {
            float: right;
            width: 300px;
        }
        .total-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 5px;
        }
        .total-final {
            font-weight: bold;
            font-size: 1.2em;
            border-top: 2px solid #4CAF50;
            padding-top: 10px;
        }
        .footer {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
        }
        .footer h3 {
            color: #4CAF50;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="company-info">
            <h1>${_companyName}</h1>
            <p>${_companyAddress.replaceAll('\n', '<br>')}</p>
        </div>
        <div class="receipt-info">
            <h2>RECEIPT</h2>
            <p><strong>Receipt #${order.id.substring(0, 8).toUpperCase()}</strong></p>
            <p>Date: ${_formatDate(order.createdAt)}</p>
        </div>
    </div>

    <div class="info-section">
        <h3>Order Information</h3>
        <p><strong>Order ID:</strong> ${order.id}</p>
        <p><strong>Status:</strong> ${order.status.displayName}</p>
        <p><strong>Payment Status:</strong> ${order.paymentStatus.displayName}</p>
        <p><strong>Payment Method:</strong> ${order.paymentMethod ?? 'N/A'}</p>
    </div>

    <div class="customer-info">
        <div>
            <h3>Customer Information</h3>
            <p><strong>Name:</strong> ${order.customerName}</p>
            <p><strong>Email:</strong> ${order.customerEmail}</p>
        </div>
        <div>
            <h3>Shipping Address</h3>
            <p>${order.shippingAddress.fullName}</p>
            <p>${order.shippingAddress.addressLine1}</p>
            ${order.shippingAddress.addressLine2?.isNotEmpty == true ? '<p>${order.shippingAddress.addressLine2}</p>' : ''}
            <p>${order.shippingAddress.city}, ${order.shippingAddress.state}</p>
            <p>${order.shippingAddress.postalCode}, ${order.shippingAddress.country}</p>
        </div>
    </div>

    <h3>Order Items</h3>
    <table class="items-table">
        <thead>
            <tr>
                <th>Item</th>
                <th>Quantity</th>
                <th>Unit Price</th>
                <th>Total</th>
            </tr>
        </thead>
        <tbody>
            ${order.items.map((item) => '''
            <tr>
                <td>${item.productName}</td>
                <td>${item.quantity}${item.unit != null ? ' ${item.unit}' : ''}</td>
                <td>${item.formattedUnitPrice}</td>
                <td>${item.formattedTotalPrice}</td>
            </tr>
            ''').join('')}
        </tbody>
    </table>

    <div class="totals">
        <div class="total-row">
            <span>Subtotal:</span>
            <span>${order.formattedSubtotal}</span>
        </div>
        ${order.tax > 0 ? '''
        <div class="total-row">
            <span>Tax:</span>
            <span>${order.formattedTax}</span>
        </div>
        ''' : ''}
        ${order.shippingCost > 0 ? '''
        <div class="total-row">
            <span>Shipping:</span>
            <span>${order.formattedShippingCost}</span>
        </div>
        ''' : ''}
        <div class="total-row total-final">
            <span>Total:</span>
            <span>${order.formattedTotalAmount}</span>
        </div>
    </div>

    <div style="clear: both;"></div>

    <div class="footer">
        <h3>Thank you for your business!</h3>
        <p>For questions about this receipt, please contact us at support@poligrain.com</p>
    </div>
</body>
</html>
    ''';
  }
}

/// Exception thrown when receipt generation fails
class ReceiptGenerationException implements Exception {
  final String message;
  final dynamic originalError;

  const ReceiptGenerationException(this.message, {this.originalError});

  @override
  String toString() => 'ReceiptGenerationException: $message';
}
