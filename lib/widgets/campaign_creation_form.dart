import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:poligrain_app/models/campaign.dart';
import 'package:poligrain_app/models/campaign_enum.dart';
import 'package:poligrain_app/services/campaign_service.dart';
import 'package:poligrain_app/exceptions/campaign_exceptions.dart';

/// Multi-step campaign creation form with validation and progress tracking
class CampaignCreationForm extends StatefulWidget {
  final Function(Campaign)? onCampaignCreated;
  final Function(String)? onError;

  const CampaignCreationForm({Key? key, this.onCampaignCreated, this.onError})
    : super(key: key);

  @override
  State<CampaignCreationForm> createState() => _CampaignCreationFormState();
}

class _CampaignCreationFormState extends State<CampaignCreationForm>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  final CampaignService _campaignService = CampaignService();

  // Form keys for each step
  final _basicInfoFormKey = GlobalKey<FormState>();
  final _detailsFormKey = GlobalKey<FormState>();
  final _financialFormKey = GlobalKey<FormState>();
  final _documentsFormKey = GlobalKey<FormState>();

  // Current step tracking
  int _currentStep = 0;
  static const int _totalSteps =
      5; // Basic Info, Details, Financial, Documents, Review
  bool _isLoading = false;

  // Form data controllers and variables
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  CampaignType _campaignType = CampaignType.loan;
  String? _selectedCategory;

  final _unitController = TextEditingController();
  final _quantityController = TextEditingController();
  final _gestationPeriodController = TextEditingController();
  final List<String> _selectedTenureOptions = [];

  final _targetAmountController = TextEditingController();
  final _minimumInvestmentController = TextEditingController();
  final _averageCostController = TextEditingController();
  final _totalLoanFeeController = TextEditingController();

  // Live calculation state for fee/total display
  static const double _platformFeePercent = 0.025;
  double _transactionFeeAmount = 0.0;
  double _computedTotalLoanAmount = 0.0;

  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _imageUrls = [];
  final List<String> _documentUrls = [];

  // Step validation status
  final List<bool> _stepValidation = [false, false, false, false, false];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _updateProgress();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _unitController.dispose();
    _quantityController.dispose();
    _gestationPeriodController.dispose();
    _targetAmountController.dispose();
    _minimumInvestmentController.dispose();
    _averageCostController.dispose();
    _totalLoanFeeController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    final progress = (_currentStep) / (_totalSteps - 1);
    _progressController.animateTo(progress);
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < _totalSteps - 1) {
        setState(() {
          _currentStep++;
          _stepValidation[_currentStep - 1] = true;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _updateProgress();
      }
    } else {
      _showValidationError();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _updateProgress();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _basicInfoFormKey.currentState?.validate() ?? false;
      case 1:
        final isFormValid = _detailsFormKey.currentState?.validate() ?? false;
        final hasTenureOptions = _selectedTenureOptions.isNotEmpty;
        final hasValidDates =
            _startDate != null &&
            _endDate != null &&
            _endDate!.isAfter(_startDate!);
        return isFormValid && hasTenureOptions && hasValidDates;
      case 2:
        final isFormValid = _financialFormKey.currentState?.validate() ?? false;
        final hasValidAmounts = _validateFinancialAmounts();
        return isFormValid && hasValidAmounts;
      case 3:
        return _documentsFormKey.currentState?.validate() ?? false;
      case 4:
        return _validateAllSteps();
      default:
        return false;
    }
  }

  bool _validateFinancialAmounts() {
    final targetAmount = double.tryParse(
      _targetAmountController.text.replaceAll(',', ''),
    );
    final minimumInvestment = double.tryParse(
      _minimumInvestmentController.text.replaceAll(',', ''),
    );
    final averageCost = double.tryParse(
      _averageCostController.text.replaceAll(',', ''),
    );

    if (targetAmount == null ||
        minimumInvestment == null ||
        averageCost == null) {
      return false;
    }

    return targetAmount > 0 &&
        minimumInvestment > 0 &&
        averageCost > 0 &&
        minimumInvestment <= targetAmount;
  }

  bool _validateAllSteps() {
    return _stepValidation.take(4).every((isValid) => isValid);
  }

  void _showValidationError() {
    String message = '';
    switch (_currentStep) {
      case 0:
        message = 'Please fill in all required basic information fields';
        break;
      case 1:
        if (_selectedTenureOptions.isEmpty) {
          message = 'Please select at least one tenure option';
        } else if (_startDate == null || _endDate == null) {
          message = 'Please select both start and end dates';
        } else if (_endDate!.isBefore(_startDate!)) {
          message = 'End date must be after start date';
        } else {
          message = 'Please complete all campaign details';
        }
        break;
      case 2:
        message = 'Please verify all financial information is correct';
        break;
      case 3:
        message = 'Please complete document uploads';
        break;
      default:
        message = 'Please check all form fields';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Wrap scaffold in a Theme so inputs and placeholders match the simplified design
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green[200]!),
          ),
          hintStyle: TextStyle(color: Colors.green[200]),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Column(
          children: [
            _buildHeader(),
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildBasicInfoStep(),
                  _buildDetailsStep(),
                  _buildFinancialStep(),
                  _buildDocumentsStep(),
                  _buildReviewStep(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _showExitDialog(),
            icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(backgroundColor: Colors.grey[100]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Campaign',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                Text(
                  _getStepTitle(_currentStep),
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              final isActive = index <= _currentStep;
              final isCompleted =
                  index < _currentStep || _stepValidation[index];
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                              isCompleted
                                  ? Colors.green[600]
                                  : isActive
                                  ? Colors.green[300]
                                  : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (index < _totalSteps - 1) const SizedBox(width: 4),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of $_totalSteps',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
              Text(
                '${((_currentStep + 1) / _totalSteps * 100).toInt()}% Complete',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _previousStep,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed:
                    _isLoading
                        ? null
                        : (_currentStep == _totalSteps - 1
                            ? _submitCampaign
                            : _nextStep),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _currentStep == _totalSteps - 1 ? 4 : 2,
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentStep == _totalSteps - 1
                                  ? 'Submit Campaign'
                                  : 'Next',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentStep == _totalSteps - 1
                                  ? Icons.send
                                  : Icons.arrow_forward,
                              size: 20,
                            ),
                          ],
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Exit Campaign Creation'),
            content: const Text(
              'Are you sure you want to exit? Your progress will be lost.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text('Exit', style: TextStyle(color: Colors.red[600])),
              ),
            ],
          ),
    );
  }

  Future<void> _submitCampaign() async {
    if (!_validateCurrentStep()) {
      _showValidationError();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final user = await Amplify.Auth.getCurrentUser();

      // Create campaign object
      final newCampaign = Campaign(
        id: '', // Will be generated by the backend
        ownerId: user.userId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _campaignType.toString().split('.').last,
        status: 'Draft',
        targetAmount: double.parse(
          _targetAmountController.text.replaceAll(',', ''),
        ),
        minimumInvestment: double.parse(
          _minimumInvestmentController.text.replaceAll(',', ''),
        ),
        category: _selectedCategory!,
        unit: _unitController.text.trim(),
        quantity: int.parse(_quantityController.text),
        gestationPeriod: _gestationPeriodController.text.trim(),
        tenureOptions: _selectedTenureOptions,
        averageCostPerUnit: double.parse(
          _averageCostController.text.replaceAll(',', ''),
        ),
        totalLoanIncludingFeePerUnit: double.parse(
          _totalLoanFeeController.text.replaceAll(',', ''),
        ),
        startDate: _startDate!,
        endDate: _endDate!,
        imageUrls: _imageUrls,
        documentUrls: _documentUrls,
        metadata: {'createdFrom': 'mobile_app', 'version': '1.0.0'},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        totalRaised: 0.0,
        investorCount: 0,
        totalInvestments: 0,
        fundingPercentage: 0,
      );

      final campaign = await _campaignService.createCampaign(newCampaign);

      // Success callback
      widget.onCampaignCreated?.call(campaign);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Campaign "${campaign.title}" created successfully!'),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(campaign);
      }
    } on CampaignException catch (e) {
      widget.onError?.call(e.message);
      _showErrorDialog('Campaign Error', e.message);
    } on AmplifyException catch (e) {
      final errorMessage = 'Authentication error: ${e.message}';
      widget.onError?.call(errorMessage);
      _showErrorDialog('Authentication Error', errorMessage);
    } catch (e) {
      final errorMessage = 'Failed to create campaign: ${e.toString()}';
      widget.onError?.call(errorMessage);
      _showErrorDialog('Error', errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  // Build step methods would continue here with the same logic as before
  // but with improved validation and error handling...

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Basic Information';
      case 1:
        return 'Campaign Details';
      case 2:
        return 'Financial Information';
      case 3:
        return 'Documents & Media';
      case 4:
        return 'Review & Submit';
      default:
        return '';
    }
  }

  Widget _buildBasicInfoStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _basicInfoFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Campaign Basic Information',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Campaign Title',
                hintText: 'Enter a compelling title for your campaign',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a campaign title';
                }
                if (value.trim().length < 5) {
                  return 'Title must be at least 5 characters long';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Describe your campaign in detail',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                if (value.trim().length < 20) {
                  return 'Description must be at least 20 characters long';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CampaignType>(
              value: _campaignType,
              decoration: InputDecoration(
                labelText: 'Campaign Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.category),
              ),
              items:
                  CampaignType.values.map((type) {
                    return DropdownMenuItem<CampaignType>(
                      value: type,
                      child: Text(type.toString().split('.').last),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _campaignType = value!;
                });
              },
              validator:
                  (value) =>
                      value == null ? 'Please select a campaign type' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.folder),
              ),
              items:
                  [
                    'Agriculture',
                    'Education',
                    'Healthcare',
                    'Technology',
                    'Real Estate',
                    'Small Business',
                    'Other',
                  ].map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              validator:
                  (value) => value == null ? 'Please select a category' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _detailsFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Campaign Details',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _unitController,
              decoration: InputDecoration(
                labelText: 'Unit Name',
                hintText: 'e.g., plot, bag, share',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.inventory_2),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a unit name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Total Quantity',
                hintText: 'Total number of units available',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.calculate),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter total quantity';
                }
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return 'Please enter a valid positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gestationPeriodController,
              decoration: InputDecoration(
                labelText: 'Gestation Period',
                hintText: 'e.g., 6 months, 1 year',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.schedule),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter gestation period';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Tenure Options',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  [
                    '3 months',
                    '6 months',
                    '9 months',
                    '12 months',
                    '18 months',
                    '24 months',
                  ].map((tenure) {
                    final isSelected = _selectedTenureOptions.contains(tenure);
                    return FilterChip(
                      label: Text(tenure),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTenureOptions.add(tenure);
                          } else {
                            _selectedTenureOptions.remove(tenure);
                          }
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: Colors.green[100],
                      checkmarkColor: Colors.green[600],
                    );
                  }).toList(),
            ),
            if (_selectedTenureOptions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Please select at least one tenure option',
                  style: TextStyle(color: Colors.red[600], fontSize: 12),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'Campaign Dates',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          _startDate = picked;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              _startDate == null
                                  ? Colors.grey[300]!
                                  : Colors.green[300]!,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[50],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.grey[600]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _startDate == null
                                  ? 'Select Start Date'
                                  : _formatDate(_startDate),
                              style: TextStyle(
                                color:
                                    _startDate == null
                                        ? Colors.grey[500]
                                        : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate:
                            _startDate ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: _startDate ?? DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          _endDate = picked;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              _endDate == null
                                  ? Colors.grey[300]!
                                  : Colors.green[300]!,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[50],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.grey[600]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _endDate == null
                                  ? 'Select End Date'
                                  : _formatDate(_endDate),
                              style: TextStyle(
                                color:
                                    _endDate == null
                                        ? Colors.grey[500]
                                        : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_startDate != null &&
                _endDate != null &&
                _endDate!.isBefore(_startDate!))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'End date must be after start date',
                  style: TextStyle(color: Colors.red[600], fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _financialFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Information',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _targetAmountController,
              decoration: InputDecoration(
                labelText: 'Target Amount',
                hintText: 'Total amount you want to raise',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.attach_money),
                prefixText: '₦ ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                _formatCurrency(_targetAmountController);
                _updateFeeAndTotal();
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter target amount';
                }
                final amount = double.tryParse(value.replaceAll(',', ''));
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minimumInvestmentController,
              decoration: InputDecoration(
                labelText: 'Minimum Investment',
                hintText: 'Minimum amount per investment',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.money_off),
                prefixText: '₦ ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                _formatCurrency(_minimumInvestmentController);
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter minimum investment';
                }
                final amount = double.tryParse(value.replaceAll(',', ''));
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _averageCostController,
              decoration: InputDecoration(
                labelText: 'Average Cost per Unit',
                hintText: 'Cost per unit before fees',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.calculate),
                prefixText: '₦ ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                _formatCurrency(_averageCostController);
                _calculateTotalLoanWithFee();
                _updateFeeAndTotal();
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter average cost per unit';
                }
                final amount = double.tryParse(value.replaceAll(',', ''));
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalLoanFeeController,
              decoration: InputDecoration(
                labelText: 'Total Cost per Unit with Fee',
                hintText: 'Includes 2.5% platform fee',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.payment),
                prefixText: '₦ ',
              ),
              enabled: false,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Fee Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Poligrain charges a 2.5% platform fee on all successful campaigns. This fee is automatically calculated and included in the total amount investors pay.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Live fee and total display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transaction Fee',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(_platformFeePercent * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatCurrencyDisplay(
                          _transactionFeeAmount.toStringAsFixed(0),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Loan Amount',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total amount to be disbursed',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatCurrencyDisplay(
                          _computedTotalLoanAmount.toStringAsFixed(0),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _documentsFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Documents & Media',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Campaign Images',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey[300]!,
                  style: BorderStyle.solid,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child:
                  _imageUrls.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to add images',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imageUrls.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 100,
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(_imageUrls[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 24),
            Text(
              'Supporting Documents',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey[300]!,
                  style: BorderStyle.solid,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child:
                  _documentUrls.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to add documents',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _documentUrls.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 100,
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[200],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.picture_as_pdf,
                                size: 40,
                                color: Colors.red[600],
                              ),
                            ),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Document Requirements',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please upload relevant documents such as business registration, financial statements, project plans, or any other supporting materials that will help build trust with potential investors.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Submit',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReviewSection('Basic Information', [
                    Text('Title: ${_titleController.text}'),
                    Text('Description: ${_descriptionController.text}'),
                    Text('Type: ${_campaignType.toString().split('.').last}'),
                    Text('Category: $_selectedCategory'),
                  ]),
                  const SizedBox(height: 24),
                  _buildReviewSection('Campaign Details', [
                    Text('Unit: ${_unitController.text}'),
                    Text('Quantity: ${_quantityController.text}'),
                    Text(
                      'Gestation Period: ${_gestationPeriodController.text}',
                    ),
                    Text(
                      'Tenure Options: ${_selectedTenureOptions.join(', ')}',
                    ),
                    Text('Start Date: ${_formatDate(_startDate)}'),
                    Text('End Date: ${_formatDate(_endDate)}'),
                  ]),
                  const SizedBox(height: 24),
                  _buildReviewSection('Financial Information', [
                    Text(
                      'Target Amount: ${_formatCurrencyDisplay(_targetAmountController.text)}',
                    ),
                    Text(
                      'Minimum Investment: ${_formatCurrencyDisplay(_minimumInvestmentController.text)}',
                    ),
                    Text(
                      'Average Cost per Unit: ${_formatCurrencyDisplay(_averageCostController.text)}',
                    ),
                    Text(
                      'Total with Fee: ${_formatCurrencyDisplay(_totalLoanFeeController.text)}',
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildReviewSection('Documents & Media', [
                    Text('Images: ${_imageUrls.length} uploaded'),
                    Text('Documents: ${_documentUrls.length} uploaded'),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 12),
          ...children.map(
            (child) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  void _calculateTotalLoanWithFee() {
    final averageCostText = _averageCostController.text.replaceAll(',', '');
    if (averageCostText.isNotEmpty) {
      final averageCost = double.tryParse(averageCostText);
      if (averageCost != null) {
        final totalWithFee = averageCost * 1.025; // 2.5% fee
        _totalLoanFeeController.text = totalWithFee
            .toStringAsFixed(0)
            .replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},',
            );
      }
    }
    // Also update transaction fee and total based on target amount
    _updateFeeAndTotal();
  }

  void _formatCurrency(TextEditingController controller) {
    final text = controller.text.replaceAll(',', '');
    if (text.isNotEmpty) {
      final number = double.tryParse(text);
      if (number != null) {
        final formatted = number
            .toStringAsFixed(0)
            .replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},',
            );
        if (controller.text != formatted) {
          controller.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      }
    }
  }

  // Returns a display string with the Naira symbol prefix and comma grouping.
  // If the input is empty or invalid, returns an empty string.
  String _formatCurrencyDisplay(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    final numeric = double.tryParse(trimmed.replaceAll(',', ''));
    if (numeric == null) return '₦$trimmed';
    final formatted = numeric
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '₦$formatted';
  }

  // Update transaction fee and computed total based on the current target amount
  void _updateFeeAndTotal() {
    final text = _targetAmountController.text.replaceAll(',', '');
    final target = double.tryParse(text) ?? 0.0;
    final fee = target * _platformFeePercent;
    final total = target + fee;
    setState(() {
      _transactionFeeAmount = fee;
      _computedTotalLoanAmount = total;
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  // Additional helper methods would be implemented here...
}
