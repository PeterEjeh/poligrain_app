import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final Order order;
  final OrderService _orderService = OrderService();

  OrderConfirmationScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmed'),
        automaticallyImplyLeading: false, // No back button
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 24),
              Text(
                'Thank You For Your Order!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your order #${order.id.substring(0, 8)} has been placed successfully.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildOrderSummaryCard(context),
              const SizedBox(height: 24),
              _buildReceiptActions(context),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    // Navigate back to the root, clearing the cart/checkout stack
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Continue Shopping'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              context,
              'Total Amount:',
              order.formattedTotalAmount,
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              context,
              'Payment Method:',
              order.paymentMethod ?? 'N/A',
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              context,
              'Shipping To:',
              order.shippingAddress.fullName,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                order.shippingAddress.formattedAddress,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildReceiptActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.download_rounded),
          label: const Text('Download'),
          onPressed: () async {
            try {
              final filePath = await _orderService.generateReceipt(order.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Receipt saved to $filePath')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error downloading receipt: $e')),
              );
            }
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.share_rounded),
          label: const Text('Share'),
          onPressed: () async {
            try {
              await _orderService.shareReceipt(order.id);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error sharing receipt: $e')),
              );
            }
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.email_rounded),
          label: const Text('Email'),
          onPressed: () async {
            try {
              await _orderService.sendReceiptEmail(order.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Receipt sent to your email')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error emailing receipt: $e')),
              );
            }
          },
        ),
      ],
    );
  }
}
