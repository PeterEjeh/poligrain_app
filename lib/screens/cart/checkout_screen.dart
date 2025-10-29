import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController(
    text: 'Nigeria',
  ); // Default country

  String _paymentMethod = 'Paystack'; // Default payment method

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressLine1Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(cartService),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(context, 'Shipping Address'),
                      _buildShippingForm(),
                      const SizedBox(height: 24),
                      _buildSectionTitle(context, 'Payment Method'),
                      _buildPaymentMethodSelector(),
                      const SizedBox(height: 24),
                      _buildSectionTitle(context, 'Order Summary'),
                      _buildOrderSummary(cartService),
                      const SizedBox(height: 16),
                      _buildPlaceOrderButton(cartService),
                      const SizedBox(height: 16),
                      _buildTotalRow(cartService),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: null,
    );
  }

  Widget _buildModernHeader(CartService cartService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Checkout',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          if (!cartService.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${cartService.totalItems} items',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildShippingForm() {
    return Column(
      children: [
        TextFormField(
          controller: _fullNameController,
          decoration: _inputDecoration('Full Name'),
          validator:
              (value) =>
                  (value?.isEmpty ?? true)
                      ? 'Please enter your full name'
                      : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _addressLine1Controller,
          decoration: _inputDecoration(
            'Address Line 1',
            hint: 'Enter your address',
          ),
          validator:
              (value) =>
                  (value?.isEmpty ?? true) ? 'Please enter your address' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cityController,
          decoration: _inputDecoration('City', hint: 'Enter your city'),
          validator:
              (value) =>
                  (value?.isEmpty ?? true) ? 'Please enter your city' : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _stateController,
                decoration: _inputDecoration(
                  'State/Province',
                  hint: 'Enter state',
                ),
                validator:
                    (value) =>
                        (value?.isEmpty ?? true)
                            ? 'Please enter your state'
                            : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _postalCodeController,
                decoration: _inputDecoration('Postal Code', hint: 'Enter code'),
                validator:
                    (value) =>
                        (value?.isEmpty ?? true)
                            ? 'Please enter your postal code'
                            : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _countryController,
          decoration: _inputDecoration('Country'),
          readOnly: true,
          validator:
              (value) =>
                  (value?.isEmpty ?? true) ? 'Please enter your country' : null,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelector() {
    return DropdownButtonFormField<String>(
      value: _paymentMethod,
      decoration: _inputDecoration('Payment Method'),
      items:
          ['Paystack', 'Flutterwave', 'Bank Transfer']
              .map(
                (method) =>
                    DropdownMenuItem(value: method, child: Text(method)),
              )
              .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _paymentMethod = value;
          });
        }
      },
    );
  }

  Widget _buildOrderSummary(CartService cartService) {
    final summary = cartService.getCartSummary();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSummaryRow('Subtotal', _formatAmount(summary.totalPrice)),
            const SizedBox(height: 8),
            _buildSummaryRow('Shipping', 'Free'),
            const SizedBox(height: 8),
            _buildSummaryRow('Tax', _formatAmount(0)),
            const Divider(height: 24),
            _buildSummaryRow(
              'Total',
              _formatAmount(summary.totalPrice),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    final style =
        isTotal
            ? Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
            : Theme.of(context).textTheme.bodyLarge;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
  }

  Widget _buildPlaceOrderButton(CartService cartService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed: () => _placeOrder(cartService),
          child: const Text('Place Order'),
        ),
      ),
    );
  }

  Widget _buildTotalRow(CartService cartService) {
    final summary = cartService.getCartSummary();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween),
    );
  }

  void _placeOrder(CartService cartService) async {
    if (_formKey.currentState!.validate()) {
      // Show a loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final orderService = OrderService();
        final summary = cartService.getCartSummary();
        final reservationIds = await cartService.prepareCheckout();

        final order = await orderService.createOrder(
          items:
              summary.items
                  .map((item) => OrderItem.fromCartItem(item).toJson())
                  .toList(),
          totalAmount: summary.totalPrice,
          deliveryAddress: _addressLine1Controller.text,
          notes: 'Payment via $_paymentMethod',
          reservationIds: reservationIds,
        );

        await cartService.confirmCheckout(order.id, reservationIds);

        Navigator.of(context).pop(); // Dismiss the loading indicator
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(order: order),
          ),
        );
      } catch (e) {
        Navigator.of(context).pop(); // Dismiss the loading indicator
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error placing order: $e')));
      }
    }
  }

  Order _createMockOrder(CartService cartService) {
    final summary = cartService.getCartSummary();
    return Order(
      id: 'mock-order-${DateTime.now().millisecondsSinceEpoch}',
      customerId: 'mock-customer-id',
      customerName: _fullNameController.text,
      customerEmail: 'customer@example.com', // Placeholder
      items: summary.items.map((item) => OrderItem.fromCartItem(item)).toList(),
      subtotal: summary.totalPrice,
      tax: 0.0,
      shippingCost: 0.0,
      totalAmount: summary.totalPrice,
      status: OrderStatus.confirmed,
      paymentStatus: PaymentStatus.paid,
      paymentMethod: _paymentMethod,
      shippingAddress: ShippingAddress(
        fullName: _fullNameController.text,
        addressLine1: _addressLine1Controller.text,
        city: _cityController.text,
        state: _stateController.text,
        postalCode: _postalCodeController.text,
        country: _countryController.text,
      ),
      createdAt: DateTime.now(),
    );
  }

  String _formatAmount(double amount) {
    final format = intl.NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 2,
    );
    return format.format(amount);
  }
}
