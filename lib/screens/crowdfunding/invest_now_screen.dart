import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for TextInputFormatter
import 'package:intl/intl.dart';
import 'package:poligrain_app/models/campaign.dart';
import 'package:poligrain_app/screens/crowdfunding/crowdfunding_screen.dart';
import 'package:poligrain_app/screens/payment_gateway_screen.dart';

String formatNaira(num amount) {
  final formatter = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 2,
  );
  return formatter.format(amount);
}

class InvestNowScreen extends StatefulWidget {
  final LoanRequest campaign;

  const InvestNowScreen({super.key, required this.campaign});

  @override
  State<InvestNowScreen> createState() => _InvestNowScreenState();
}

class _InvestNowScreenState extends State<InvestNowScreen> {
  final TextEditingController _amountController = TextEditingController();

  // Investment limits (can be set from campaign data)
  late final double _minimumInvestment;
  late final double _maximumInvestment;

  @override
  void initState() {
    super.initState();

    // Initialize investment limits from campaign data or use defaults
    _minimumInvestment =
        widget.campaign.minimumInvestment ?? 5000.0; // Default minimum: ₦5,000
    _maximumInvestment =
        widget.campaign.maximumInvestment ??
        (widget.campaign.amount > 0
            ? widget.campaign.amount
            : 1000000.0); // Default max: campaign amount or ₦1M
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Placeholder values for demonstration, replace with actual calculations
    final String cleanAmountText = _amountController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final double investmentAmount = double.tryParse(cleanAmountText) ?? 0.0;
    final double estimatedReturn =
        investmentAmount * 1.2; // Example: 20% return

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Invest Now',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campaign Details Section
            const Text(
              '',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.campaign.campaignName ?? 'Campaign Details',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Target: ${formatNaira(widget.campaign.amount)}'),
                      Text(
                        'Duration: ${widget.campaign.tenure}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/market.jpg', // Placeholder as LoanRequest doesn't have imageUrls
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Amount Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                decoration: InputDecoration(
                  hintText: '',
                  border: InputBorder.none,
                  hintStyle: const TextStyle(color: Colors.green),
                  prefixText: '₦', // Naira symbol
                  prefixStyle: TextStyle(
                    color: Colors.green,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  helperText:
                      'Investment range: ${formatNaira(_minimumInvestment)} - ${formatNaira(_maximumInvestment)}',
                  helperStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  // Show error if amount is outside valid range
                  errorText: _getAmountValidationError(),
                ),
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                onChanged: (value) {
                  setState(() {
                    // Trigger rebuild to update investment summary
                  });
                },
              ),
            ),
            const SizedBox(height: 24),

            // Estimated Return Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estimated Return',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatNaira(estimatedReturn),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Investment Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Investment Summary',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow(
                    'Investment Amount',
                    formatNaira(investmentAmount),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    'Service Charge (5%)',
                    formatNaira(investmentAmount * 0.05),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  _buildSummaryRow(
                    'Total Amount',
                    formatNaira(investmentAmount + (investmentAmount * 0.05)),
                    isBold: true,
                    color: Colors.green[700],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Confirm Investment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_amountController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter an investment amount'),
                      ),
                    );
                    return;
                  }

                  // Parse the investment amount
                  final String cleanAmount = _amountController.text.replaceAll(
                    RegExp(r'[^0-9]'),
                    '',
                  );
                  final double investmentAmount =
                      double.tryParse(cleanAmount) ?? 0.0;

                  // Validate amount is greater than 0
                  if (investmentAmount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid investment amount'),
                      ),
                    );
                    return;
                  }

                  // Check minimum investment
                  if (investmentAmount < _minimumInvestment) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Minimum investment amount is ${formatNaira(_minimumInvestment)}',
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    return;
                  }

                  // Check maximum investment
                  if (investmentAmount > _maximumInvestment) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Maximum investment amount is ${formatNaira(_maximumInvestment)}',
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    return;
                  }

                  final double totalAmount =
                      investmentAmount + (investmentAmount * 0.05);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              PaymentGatewayScreen(totalAmount: totalAmount),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Confirm Investment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _getAmountValidationError() {
    if (_amountController.text.isEmpty) return null;

    final String cleanAmount = _amountController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final double amount = double.tryParse(cleanAmount) ?? 0.0;

    if (amount <= 0) return null;
    if (amount < _minimumInvestment) {
      return 'Amount is below minimum investment';
    }
    if (amount > _maximumInvestment) {
      return 'Amount exceeds maximum investment';
    }
    return null;
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.2),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 17 : 15,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            color: color ?? Colors.black87,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    if (newValue.text.compareTo(oldValue.text) != 0) {
      final int selectionIndexFromTheRight =
          newValue.text.length - newValue.selection.end;
      final formatter = NumberFormat.currency(
        locale: 'en_NG',
        symbol: '', // No symbol here, as it's added as a prefix
        decimalDigits: 0, // Handle decimals separately if needed
      );
      String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (newText.isEmpty) {
        return newValue.copyWith(text: '');
      }
      double value = double.parse(newText);
      String newString = formatter.format(value);
      return TextEditingValue(
        text: newString,
        selection: TextSelection.collapsed(
          offset: newString.length - selectionIndexFromTheRight,
        ),
      );
    }
    return newValue;
  }
}
