import 'package:flutter/material.dart';

class PaymentGatewayScreen extends StatefulWidget {
  final double totalAmount;

  const PaymentGatewayScreen({super.key, required this.totalAmount});

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  String? _selectedPaymentMethod = 'Credit/Debit Card';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Payment Gateway',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Amount Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Amount to Pay',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₦${widget.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPaymentMethod,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: [
                    DropdownMenuItem(
                      value: 'Credit/Debit Card',
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/mastercard_logo.png',
                            width: 32,
                            height: 32,
                          ),
                          const SizedBox(width: 12),
                          const Text('Credit/Debit Card'),
                        ],
                      ),
                    ),
                    const DropdownMenuItem(
                      value: 'Bank Transfer',
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance,
                            size: 32,
                            color: Colors.black54,
                          ),
                          SizedBox(width: 12),
                          Text('Bank Transfer'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedPaymentMethod = newValue;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedPaymentMethod == 'Credit/Debit Card') ...[
              _buildTextField('Card Number'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildTextField('Expiry Date')),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField('CVC')),
                ],
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle proceed to payment logic
                  print('Proceeding to payment with $_selectedPaymentMethod');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Proceed to Payment',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hintText) {
    return TextField(
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
      ),
    );
  }
}
