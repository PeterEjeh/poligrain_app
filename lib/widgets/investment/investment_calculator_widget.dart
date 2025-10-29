import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poligrain_app/models/campaign.dart';
import 'package:poligrain_app/services/investment_calculator.dart';

/// Enhanced investment calculator widget with progress tracking and error handling
class InvestmentCalculatorWidget extends StatefulWidget {
  final Campaign campaign;
  final double? initialAmount;
  final Function(Map<String, dynamic>)? onCalculationChanged;
  final Function(String)? onError;

  const InvestmentCalculatorWidget({
    Key? key,
    required this.campaign,
    this.initialAmount,
    this.onCalculationChanged,
    this.onError,
  }) : super(key: key);

  @override
  State<InvestmentCalculatorWidget> createState() =>
      _InvestmentCalculatorWidgetState();
}

class _InvestmentCalculatorWidgetState extends State<InvestmentCalculatorWidget>
    with TickerProviderStateMixin {
  late TextEditingController _amountController;
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  String? _selectedTenure;
  Map<String, dynamic>? _calculation;
  Map<String, dynamic>? _fundingAnalytics;
  Map<String, dynamic>? _investmentScore;
  bool _isCalculating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeData();
    _performInitialCalculation();
  }

  void _initializeControllers() {
    _amountController = TextEditingController(
      text: widget.initialAmount?.toStringAsFixed(0) ?? '',
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _initializeData() {
    // Set default tenure if available
    if (widget.campaign.tenureOptions?.isNotEmpty == true) {
      _selectedTenure = widget.campaign.tenureOptions!.first;
    } else {
      _selectedTenure = '1 year';
    }

    // Initialize analytics
    _updateFundingAnalytics();
    _updateInvestmentScore();
  }

  void _performInitialCalculation() {
    if (_amountController.text.isNotEmpty) {
      _updateCalculation();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _updateCalculation() async {
    final amountText = _amountController.text.replaceAll(',', '');
    if (amountText.isEmpty || _selectedTenure == null) {
      setState(() {
        _calculation = null;
        _errorMessage = null;
      });
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() {
        _calculation = null;
        _errorMessage = 'Please enter a valid amount';
      });
      return;
    }

    // Check minimum investment
    if (amount < widget.campaign.minimumInvestment) {
      setState(() {
        _calculation = null;
        _errorMessage =
            'Minimum investment is ₦${_formatNumber(widget.campaign.minimumInvestment)}';
      });
      return;
    }

    setState(() {
      _isCalculating = true;
      _errorMessage = null;
    });

    try {
      await Future.delayed(
        const Duration(milliseconds: 300),
      ); // Simulate processing

      final calculation = InvestmentCalculator.calculatePotentialReturn(
        amount,
        widget.campaign,
        _selectedTenure!,
      );

      if (mounted) {
        setState(() {
          _calculation = calculation;
          _isCalculating = false;
        });

        // Trigger animations
        _progressController.forward(from: 0.0);
        _pulseController.repeat(reverse: true);

        // Notify parent widget
        widget.onCalculationChanged?.call(calculation);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _calculation = null;
          _isCalculating = false;
          _errorMessage = 'Calculation error: ${e.toString()}';
        });

        widget.onError?.call(e.toString());
      }
    }
  }

  void _updateFundingAnalytics() {
    try {
      _fundingAnalytics = InvestmentCalculator.calculateFundingAnalytics(
        widget.campaign,
      );
    } catch (e) {
      _fundingAnalytics = null;
    }
    if (mounted) setState(() {});
  }

  void _updateInvestmentScore() {
    try {
      _investmentScore = InvestmentCalculator.calculateInvestmentScore(
        widget.campaign,
      );
    } catch (e) {
      _investmentScore = null;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.green.shade50],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildInputSection(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _buildErrorMessage(),
              ],
              if (_isCalculating) ...[
                const SizedBox(height: 20),
                _buildLoadingIndicator(),
              ] else if (_calculation != null) ...[
                const SizedBox(height: 20),
                _buildCalculationResults(),
                const SizedBox(height: 20),
                _buildProgressTracking(),
              ],
              const SizedBox(height: 20),
              _buildInvestmentScore(),
              const SizedBox(height: 20),
              _buildFundingProgress(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade600],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.calculate, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Investment Calculator',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              Text(
                'Calculate your potential returns',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        if (widget.campaign.riskLevel != 'Low')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
                  widget.campaign.riskLevel == 'High'
                      ? Colors.red.shade100
                      : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    widget.campaign.riskLevel == 'High'
                        ? Colors.red.shade300
                        : Colors.orange.shade300,
              ),
            ),
            child: Text(
              '${widget.campaign.riskLevel} Risk',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    widget.campaign.riskLevel == 'High'
                        ? Colors.red.shade700
                        : Colors.orange.shade700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAmountInput(),
          const SizedBox(height: 16),
          _buildTenureSelector(),
          const SizedBox(height: 12),
          _buildInvestmentLimits(),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Investment Amount',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          decoration: InputDecoration(
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '₦',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
            hintText: 'Enter amount to invest',
            suffixIcon:
                _amountController.text.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _amountController.clear();
                        setState(() {
                          _calculation = null;
                          _errorMessage = null;
                        });
                      },
                    )
                    : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade600, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CurrencyInputFormatter(),
          ],
          onChanged: (value) {
            _updateCalculation();
          },
        ),
      ],
    );
  }

  Widget _buildTenureSelector() {
    final availableTenures = widget.campaign.tenureOptions ?? ['1 year'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Investment Tenure',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTenure,
              isExpanded: true,
              icon: Icon(Icons.expand_more, color: Colors.green.shade600),
              items:
                  availableTenures.map((tenure) {
                    final rate = widget.campaign.returnRate[tenure] ?? 0.0;
                    return DropdownMenuItem(
                      value: tenure,
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(tenure),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${rate.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTenure = value;
                });
                _updateCalculation();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvestmentLimits() {
    return Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              children: [
                const TextSpan(text: 'Min: '),
                TextSpan(
                  text: '₦${_formatNumber(widget.campaign.minimumInvestment)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (widget.campaign.targetAmount >
                    widget.campaign.totalRaised) ...[
                  const TextSpan(text: ' • Available: '),
                  TextSpan(
                    text:
                        '₦${_formatNumber(widget.campaign.targetAmount - widget.campaign.totalRaised)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
          ),
          const SizedBox(height: 12),
          Text(
            'Calculating returns...',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationResults() {
    if (_calculation == null) return const SizedBox.shrink();

    final calculation = _calculation!;
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    final roi = calculation['projectedROI'] as double? ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                'Investment Projection',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildResultCard(
                'Total Return',
                '₦${_formatNumber(calculation['totalReturn'])}',
                Icons.account_balance_wallet,
                Colors.blue,
              ),
              _buildResultCard(
                'Profit',
                '₦${_formatNumber(calculation['expectedProfit'])}',
                Icons.monetization_on,
                Colors.green,
              ),
              _buildResultCard(
                'ROI',
                '${roi.toStringAsFixed(1)}%',
                Icons.percent,
                Colors.orange,
              ),
              _buildResultCard(
                'Duration',
                _selectedTenure ?? '1 year',
                Icons.schedule,
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _progressAnimation.value),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressTracking() {
    if (_calculation == null) return const SizedBox.shrink();

    final monthlyReturns =
        _calculation!['monthlyReturns'] as List<Map<String, dynamic>>? ?? [];
    if (monthlyReturns.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: Colors.indigo.shade600),
              const SizedBox(width: 8),
              Text(
                'Monthly Growth Projection',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: monthlyReturns.length,
              itemBuilder: (context, index) {
                final monthData = monthlyReturns[index];
                final month = monthData['month'] as int;
                final amount = monthData['amount'] as double;
                final maxAmount = monthlyReturns.last['amount'] as double;
                final percentage = amount / maxAmount;

                return Container(
                  width: 40,
                  margin: const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: 20,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey.shade200,
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.bottomCenter,
                            heightFactor: percentage,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.green.shade400,
                                    Colors.green.shade600,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'M$month',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentScore() {
    if (_investmentScore == null) return const SizedBox.shrink();

    final score = _investmentScore!;
    final overallScore = score['overallScore'] as double? ?? 0.0;
    final recommendation = score['recommendation'] as String? ?? 'Consider';
    final riskLevel = score['riskLevel'] as String? ?? 'Medium';

    Color scoreColor;
    if (overallScore >= 80) {
      scoreColor = Colors.green;
    } else if (overallScore >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scoreColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rate, color: scoreColor),
              const SizedBox(width: 8),
              Text(
                'Investment Score',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scoreColor.withOpacity(0.3)),
                ),
                child: Text(
                  '${overallScore.toInt()}/100',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: overallScore / 100,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                recommendation,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scoreColor,
                ),
              ),
              Text(
                '$riskLevel Risk',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFundingProgress() {
    if (_fundingAnalytics == null) return const SizedBox.shrink();

    final analytics = _fundingAnalytics!;
    final progress = analytics['currentProgress'] as double? ?? 0.0;
    final momentum = analytics['momentum'] as String? ?? 'Stable';
    final daysRemaining = analytics['daysRemaining'] as int? ?? 0;
    final isOnTrack = analytics['isOnTrack'] as bool? ?? false;

    Color momentumColor;
    IconData momentumIcon;
    switch (momentum) {
      case 'Accelerating':
        momentumColor = Colors.green;
        momentumIcon = Icons.trending_up;
        break;
      case 'Strong':
        momentumColor = Colors.blue;
        momentumIcon = Icons.trending_up;
        break;
      case 'Slowing':
        momentumColor = Colors.orange;
        momentumIcon = Icons.trending_down;
        break;
      case 'Critical':
        momentumColor = Colors.red;
        momentumIcon = Icons.trending_down;
        break;
      default:
        momentumColor = Colors.grey;
        momentumIcon = Icons.trending_flat;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.indigo.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.track_changes, color: Colors.indigo.shade700),
              const SizedBox(width: 8),
              Text(
                'Campaign Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: momentumColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: momentumColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(momentumIcon, color: momentumColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      momentum,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: momentumColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Funding Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo.shade800,
                ),
              ),
              Text(
                '${progress.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressAnimation.value * (progress / 100),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOnTrack ? Colors.green.shade600 : Colors.indigo.shade600,
                ),
                minHeight: 8,
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Raised',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    '₦${_formatNumber(widget.campaign.totalRaised)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Days Left',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    daysRemaining.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: daysRemaining < 30 ? Colors.red : Colors.grey[800],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Target',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    '₦${_formatNumber(widget.campaign.targetAmount)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!isOnTrack && daysRemaining > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.orange.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Campaign may not reach target at current pace',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toStringAsFixed(0);
  }
}

/// Custom formatter for currency input
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove existing commas
    String newText = newValue.text.replaceAll(',', '');

    // Parse the number
    final number = int.tryParse(newText);
    if (number == null) {
      return oldValue;
    }

    // Format with commas
    String formatted = _addCommas(number.toString());

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _addCommas(String value) {
    return value.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
  }
}
