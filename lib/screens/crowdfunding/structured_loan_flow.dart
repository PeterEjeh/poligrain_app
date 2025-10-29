import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';

import 'crowdfunding_screen.dart';

class StructuredLoanFlow extends StatefulWidget {
  const StructuredLoanFlow({super.key});

  @override
  State<StructuredLoanFlow> createState() => _StructuredLoanFlowState();
}

class _StructuredLoanFlowState extends State<StructuredLoanFlow> {
  final PageController _pageController = PageController();
  String? _selectedCategory;
  StructuredLoanCampaign? _selectedCampaign;
  String? _selectedTenure;
  final TextEditingController _quantityController = TextEditingController();
  double _calculatedTotalLoan = 0.0;
  bool _isSubmitting = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_recalculate);
    // Keep track of current page for progress indicator
    _pageController.addListener(() {
      final page =
          _pageController.hasClients ? (_pageController.page ?? 0).round() : 0;
      if (page != _currentPage) {
        setState(() => _currentPage = page);
      }
    });
  }

  void _recalculate() {
    if (_selectedCampaign != null) {
      final qty = double.tryParse(_quantityController.text) ?? 0;
      setState(() {
        _calculatedTotalLoan =
            qty * _selectedCampaign!.totalLoanIncludingFeePerUnit;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submitCampaign() async {
    if (_selectedCampaign == null || _selectedTenure == null) return;
    setState(() => _isSubmitting = true);
    final payload = {
      "title": "${_selectedCampaign!.campaignName} Campaign",
      "description":
          "Agricultural campaign for ${_selectedCampaign!.campaignName}.",
      "type": "structured",
      "targetAmount": _calculatedTotalLoan,
      "minimumInvestment": _calculatedTotalLoan * 0.1,
      "category": _selectedCampaign!.category,
      "unit": _selectedCampaign!.unitType,
      "quantity": double.tryParse(_quantityController.text) ?? 0,
      "gestationPeriod": _selectedCampaign!.gestationPeriod,
      "tenureOptions": [_selectedTenure!],
      "averageCostPerUnit": _selectedCampaign!.averageCostPerUnit,
      "totalLoanIncludingFeePerUnit":
          _selectedCampaign!.totalLoanIncludingFeePerUnit,
      "startDate": DateTime.now().toIso8601String(),
      "endDate": DateTime.now().add(Duration(days: 90)).toIso8601String(),
      "imageUrls": [],
      "documentUrls": [],
      "metadata": {
        "campaignType": _selectedCampaign!.campaignName,
        "unitType": _selectedCampaign!.unitType,
        "quantity": double.tryParse(_quantityController.text) ?? 0,
      },
    };
    try {
      final restOperation = Amplify.API.post(
        '/loan-requests',
        apiName: 'PoligrainAPI',
        body: HttpPayload.json(payload),
      );
      final response = await restOperation.response;
      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign created successfully')),
        );
        Navigator.of(context).pop(); // back to previous screen
      } else {
        final errorBody = response.decodeBody();
        throw Exception('Failed to create campaign: $errorBody');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('API Error: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildSelectCampaign() {
    // Page 1 UI: title, category selector cards, then campaign list (as rounded selectable cards), and Next button.
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Select Campaign',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            // Category selector cards
            _buildCategoryCard(
              label: 'Crop',
              isSelected: _selectedCategory == 'Crop',
              onTap: () {
                setState(() {
                  _selectedCategory = 'Crop';
                  _selectedCampaign = null;
                  _selectedTenure = null;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildCategoryCard(
              label: 'Livestock',
              isSelected: _selectedCategory == 'Livestock',
              onTap: () {
                setState(() {
                  _selectedCategory = 'Livestock';
                  _selectedCampaign = null;
                  _selectedTenure = null;
                });
              },
            ),
            const SizedBox(
              height: 24,
            ), // Increased spacing for better separation
            if (_selectedCategory != null) ...[
              const Divider(
                height: 1,
                thickness: 1,
                indent: 0,
                endIndent: 0,
              ), // Add a divider
              const SizedBox(height: 18), // Spacing after divider
              Text(
                'Available Campaigns', // Sub-heading for the list
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12), // Spacing after sub-heading
              Column(
                children:
                    allStructuredLoanCampaigns
                        .where((c) => c.category == _selectedCategory)
                        .map(
                          (campaign) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildCampaignSelectionCard(campaign),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 6),
            ],

            // Full-width Next button
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    _selectedCampaign == null
                        ? null
                        : () {
                          // ensure tenure is set when moving forward
                          if (_selectedCampaign != null &&
                              _selectedTenure == null) {
                            _selectedTenure =
                                _selectedCampaign!.tenureOptions.isNotEmpty
                                    ? _selectedCampaign!.tenureOptions.first
                                    : null;
                          }
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
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

  Widget _buildCategoryCard({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green.shade200 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 16, color: Colors.grey[900]),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected ? Colors.green.shade700 : Colors.grey.shade400,
                  width: isSelected ? 3 : 2,
                ),
                color: isSelected ? Colors.white : Colors.transparent,
              ),
              child:
                  isSelected
                      ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                      : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignSelectionCard(StructuredLoanCampaign campaign) {
    final isSelected = _selectedCampaign == campaign;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCampaign = campaign;
          _selectedTenure =
              campaign.tenureOptions.isNotEmpty
                  ? campaign.tenureOptions.first
                  : null;
          _recalculate();
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green.shade100 : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Left icon box
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  campaign.category == 'Livestock' ? Icons.pets : Icons.eco,
                  color: Colors.grey[700],
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Text block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    campaign.campaignName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${campaign.gestationPeriod} • ${campaign.unitType}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            // Right selection indicator
            Container(
              width: 24, // Reduced size
              height: 24, // Reduced size
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected ? Colors.green.shade700 : Colors.grey.shade300,
                  width: isSelected ? 2 : 1, // Adjusted border width
                ),
                color: isSelected ? Colors.white : Colors.transparent,
              ),
              child:
                  isSelected
                      ? const Center(
                        child: Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.black,
                        ), // Reduced icon size
                      )
                      : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTerms() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details & Terms',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100], // Light grey background
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  hintText: 'Enter quantity (e.g., hectares or units)',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: InputBorder.none, // No border
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center, // Center hint text
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select Tenure',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10, // Increased spacing between chips
              runSpacing: 10,
              children:
                  (_selectedCampaign?.tenureOptions ?? [])
                      .map(
                        (t) => ChoiceChip(
                          label: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(t),
                          ),
                          selected: _selectedTenure == t,
                          onSelected:
                              (_) => setState(() => _selectedTenure = t),
                          selectedColor:
                              Colors.white, // Selected chip background
                          backgroundColor:
                              Colors.white, // Unselected chip background
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              10,
                            ), // Rounded corners
                            side: BorderSide(
                              color:
                                  _selectedTenure == t
                                      ? Colors.green.shade500
                                      : Colors.grey.shade300, // Border color
                              width:
                                  _selectedTenure == t ? 2 : 1, // Border width
                            ),
                          ),
                          labelStyle: TextStyle(
                            color:
                                _selectedTenure == t
                                    ? Colors.green.shade700
                                    : Colors.grey[800], // Label text color
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 24),
            _infoRowWithSubtitle(
              'Transaction Fee',
              '2.5%',
              formatNaira(_calculatedTotalLoan * 0.025),
            ),
            const SizedBox(height: 16),
            _infoRowWithSubtitle(
              'Total Loan Amount',
              'Total amount to be disbursed',
              formatNaira(_calculatedTotalLoan),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    (_calculatedTotalLoan <= 0 || _selectedTenure == null)
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

  Widget _buildConfirmation() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirmation',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              children: [
                _buildConfirmationRow(
                  leftLabel: 'Campaign',
                  leftValue: _selectedCampaign?.campaignName ?? '',
                  rightLabel: 'Quantity',
                  rightValue:
                      '${_quantityController.text} ${_selectedCampaign?.unitType ?? ''}',
                ),
                const Divider(height: 24, thickness: 1, color: Colors.grey),
                _buildConfirmationRow(
                  leftLabel: 'Tenure',
                  leftValue: _selectedTenure ?? '',
                  rightLabel: 'Loan Amount',
                  rightValue: formatNaira(
                    _calculatedTotalLoan * 0.975,
                  ), // Loan amount before fee
                ),
                const Divider(height: 24, thickness: 1, color: Colors.grey),
                _buildConfirmationRow(
                  leftLabel: 'Transaction Fee',
                  leftValue: formatNaira(_calculatedTotalLoan * 0.025),
                  rightLabel: 'Total Amount',
                  rightValue: formatNaira(_calculatedTotalLoan),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitCampaign,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[500],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Submit Application',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _infoRowWithSubtitle(String label, String subtitle, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
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
              Text(leftLabel, style: TextStyle(color: Colors.grey[700])),
              Text(leftValue, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rightLabel, style: TextStyle(color: Colors.grey[700])),
              if (rightSubtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  rightSubtitle,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
              Text(rightValue, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
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
                    splashRadius: 20,
                    color: Colors.black87,
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        'Structured Campaign',
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
              children: List.generate(3, (index) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildTopHeader(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics:
                  const NeverScrollableScrollPhysics(), // Disable swiping; use Next buttons to navigate
              children: [
                _buildSelectCampaign(),
                _buildDetailsTerms(),
                _buildConfirmation(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
