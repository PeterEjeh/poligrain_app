import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'crowdfunding_screen.dart'; // For formatNaira and other shared definitions

class FlexibleLoanFlow extends StatefulWidget {
  const FlexibleLoanFlow({super.key});

  @override
  State<FlexibleLoanFlow> createState() => _FlexibleLoanFlowState();
}

class _FlexibleLoanFlowState extends State<FlexibleLoanFlow> {
  final PageController _pageController = PageController();
  final _flexibleLoanFormKey = GlobalKey<FormState>();
  final TextEditingController _flexibleAmountController =
      TextEditingController();
  final TextEditingController _flexibleTenureController =
      TextEditingController();
  final TextEditingController _flexiblePurposeController =
      TextEditingController();
  String? _selectedFlexibleTenure;
  final List<String> _flexibleTenureOptions = [
    "3 months",
    "6 months",
    "9 months",
    "1 year",
    "2 years",
  ];
  bool _isSubmitting = false;
  bool _agreed = false;
  int _currentPage = 0;

  // Whether swiping between pages is allowed (true when current page is valid)
  bool _swipeEnabled = false;

  bool _canProceedFromPage(int page) {
    switch (page) {
      case 0:
        // Loan Details: require amount > 0 and a tenure (either free-text or a selected option)
        final amount = double.tryParse(_flexibleAmountController.text) ?? 0;
        final tenureProvided =
            _flexibleTenureController.text.trim().isNotEmpty ||
            (_selectedFlexibleTenure != null &&
                _selectedFlexibleTenure!.isNotEmpty);
        return amount > 0 && tenureProvided;
      case 1:
        // Project Description: require at least 20 chars
        return (_flexiblePurposeController.text.trim().length) >= 20;
      case 2:
        // Review & Agreement: require user agreement
        return _agreed == true;
      default:
        return true;
    }
  }

  void _updateSwipeState() {
    final can = _canProceedFromPage(_currentPage);
    if (can != _swipeEnabled) {
      setState(() => _swipeEnabled = can);
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final page =
          _pageController.hasClients ? (_pageController.page ?? 0).round() : 0;
      if (page != _currentPage) {
        setState(() {
          _currentPage = page;
          _updateSwipeState();
        });
      }
    });

    // Keep swipe-enabled state in sync with field changes
    _flexibleAmountController.addListener(_updateSwipeState);
    _flexibleTenureController.addListener(_updateSwipeState);
    _flexiblePurposeController.addListener(_updateSwipeState);

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateSwipeState());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _flexibleAmountController.dispose();
    _flexibleTenureController.dispose();
    _flexiblePurposeController.dispose();
    super.dispose();
  }

  Future<bool> _submitFlexibleLoan() async {
    // Returns true on success, false otherwise.
    if (!_flexibleLoanFormKey.currentState!.validate()) return false;
    setState(() => _isSubmitting = true);

    final amount = double.tryParse(_flexibleAmountController.text) ?? 0;
    final tenureValue =
        (_flexibleTenureController.text.isNotEmpty)
            ? _flexibleTenureController.text
            : (_selectedFlexibleTenure ?? '');

    final campaignPayload = {
      "title": "Flexible Agricultural Campaign",
      "description": _flexiblePurposeController.text,
      "type": "flexible",
      "targetAmount": amount,
      "minimumInvestment": amount * 0.05, // 5% minimum for flexible
      "category": "Flexible",
      "startDate": DateTime.now().toIso8601String(),
      // Default short window for flexible loans; adjust as needed
      "endDate": DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      "tenureOptions": [tenureValue],
      "imageUrls": [],
      "documentUrls": [],
      "metadata": {
        "purpose": _flexiblePurposeController.text,
        "tenure": tenureValue,
      },
    };

    try {
      final restOperation = Amplify.API.post(
        '/loan-requests',
        apiName: 'PoligrainAPI',
        body: HttpPayload.json(campaignPayload),
      );
      final response = await restOperation.response;
      if (response.statusCode == 201) {
        return true;
      } else {
        final errorBody = response.decodeBody();
        throw Exception('Failed to create flexible campaign: $errorBody');
      }
    } on ApiException catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('API Error: ${e.message}')));
      return false;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      return false;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildLoanDetails() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Loan Details',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            Text(
              'Loan Amount',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _flexibleAmountController,
              decoration: InputDecoration(
                hintText: 'Enter loan amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null ||
                    value.isEmpty ||
                    (double.tryParse(value) ?? 0) <= 0) {
                  return 'Please enter a valid positive amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Loan Tenure (Months)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _flexibleTenureController,
              decoration: InputDecoration(
                hintText: 'Enter loan tenure',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null ||
                    value.isEmpty ||
                    (int.tryParse(value) ?? 0) <= 0) {
                  return 'Please enter a valid tenure in months';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (_flexibleLoanFormKey.currentState!.validate()) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[500],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectTenure() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Select Tenure',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children:
                  _flexibleTenureOptions
                      .map(
                        (t) => ChoiceChip(
                          label: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(t),
                          ),
                          selected: _selectedFlexibleTenure == t,
                          onSelected:
                              (_) =>
                                  setState(() => _selectedFlexibleTenure = t),
                          selectedColor: Colors.white,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color:
                                  _selectedFlexibleTenure == t
                                      ? Colors.black87
                                      : Colors.grey.shade300,
                              width: _selectedFlexibleTenure == t ? 2 : 1,
                            ),
                          ),
                          labelStyle: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    _selectedFlexibleTenure == null
                        ? null
                        : () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[500],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectDescription() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Project Description',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            Text(
              'Project Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _flexiblePurposeController,
              decoration: InputDecoration(
                hintText: 'Describe your project or financing need',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 6,
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty ||
                    value.length < 20) {
                  return 'Please provide a brief but descriptive project description (min 20 chars).';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (_flexibleLoanFormKey.currentState!.validate()) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[500],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmation() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review and Agreement',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Loan Amount and Tenure (top section with white background)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label
                      Text(
                        'Loan Amount',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      // Amount
                      Text(
                        formatNaira(
                          double.tryParse(_flexibleAmountController.text) ?? 0,
                        ),
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Loan Tenure
                      Text(
                        'Loan Tenure',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _flexibleTenureController.text.isNotEmpty
                            ? '${_flexibleTenureController.text} Months'
                            : (_selectedFlexibleTenure ?? 'N/A'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                // Details Section (with light grey background)
                Container(
                  color: const Color(0xFFF8F9FA),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Project Description
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project Description',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _flexiblePurposeController.text,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Est. Transaction Fee
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Est. Transaction Fee',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                formatNaira(
                                  (double.tryParse(
                                            _flexibleAmountController.text,
                                          ) ??
                                          0) *
                                      0.05,
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Subject to review',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v ?? false),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'I agree to the terms and conditions.',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed:
                  (!_agreed || _isSubmitting)
                      ? null
                      : () async {
                        final success = await _submitFlexibleLoan();
                        if (success && mounted) {
                          // Move to submission/thank-you page
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[500],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isSubmitting
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text(
                        'Submit',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmission() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Submission',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Thank you, your application has been submitted. We will review it and get back to you within 3-5 business days.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[500],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
        child: Column(
          children: [
            Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: IconButton(
                    onPressed: () {
                      if (_currentPage > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                    icon: const Icon(Icons.arrow_back_ios),
                    padding: const EdgeInsets.all(8),
                    splashRadius: 18,
                    color: Colors.black87,
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        'Flexible Loan',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 8),
            // progress dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final selected = index == _currentPage;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: selected ? 10 : 8,
                  height: selected ? 10 : 8,
                  decoration: BoxDecoration(
                    color: selected ? Colors.black87 : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationRow({
    required String leftLabel,
    required String leftValue,
    required String rightLabel,
    required String rightValue,
    String? rightSubtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(leftLabel, style: TextStyle(color: Colors.black87)),
              Text(leftValue, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rightLabel, style: TextStyle(color: Colors.black87)),
              if (rightSubtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  rightSubtitle,
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
              Text(rightValue, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildTopHeader(),
          Expanded(
            child: Form(
              key: _flexibleLoanFormKey,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildLoanDetails(),
                  _buildProjectDescription(),
                  _buildConfirmation(),
                  _buildSubmission(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
