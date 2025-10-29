import 'package:flutter/material.dart';
import 'package:poligrain_app/models/campaign.dart';

class PortfolioDashboardWidget extends StatefulWidget {
  final List<Map<String, dynamic>> investments;
  final Function(String)? onCampaignTap;
  final Map<String, dynamic>? portfolioAnalytics;
  final List<dynamic>? projections;

  const PortfolioDashboardWidget({
    Key? key,
    required this.investments,
    this.onCampaignTap,
    this.portfolioAnalytics,
    this.projections,
  }) : super(key: key);

  @override
  _PortfolioDashboardWidgetState createState() =>
      _PortfolioDashboardWidgetState();
}

class _PortfolioDashboardWidgetState extends State<PortfolioDashboardWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2E7D32),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2E7D32),
          tabs: const [Tab(text: 'Overview'), Tab(text: 'Breakdown')],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildOverviewTab(), _buildBreakdownTab()],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    if (widget.investments.isEmpty) {
      return const Center(child: Text('No investments found'));
    }

    final totalInvested = widget.investments.fold(
      0.0,
      (sum, investment) => sum + (investment['amount'] as double? ?? 0.0),
    );

    final totalValue =
        widget.projections?.isNotEmpty == true
            ? widget.projections!.last['totalValue'] as double? ?? 0.0
            : totalInvested;

    final totalGrowth = totalValue - totalInvested;
    final growthPercentage =
        totalInvested > 0 ? (totalGrowth / totalInvested * 100) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Portfolio Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE8F5E9).withOpacity(0.1),
                  const Color(0xFFE8F5E9).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF2E7D32).withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Portfolio Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Invested',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₦${_formatNumber(totalInvested)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Value',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₦${_formatNumber(totalValue)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Growth',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${growthPercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color:
                                  growthPercentage >= 0
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFD32F2F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Diversification Score
          if (widget.portfolioAnalytics?['diversificationScore'] != null)
            _buildDiversificationCard(
              widget.portfolioAnalytics!['diversificationScore'] as double,
            ),
          const SizedBox(height: 20),

          // Performance Chart
          Text(
            'Performance Projection',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildPerformanceChart(widget.projections ?? []),
          ),

          const SizedBox(height: 16),

          // Performance Metrics
          _buildPerformanceMetrics(widget.projections ?? []),
        ],
      ),
    );
  }

  Widget _buildBreakdownTab() {
    if (widget.portfolioAnalytics == null) return const SizedBox.shrink();

    final analytics = widget.portfolioAnalytics!;

    return Column(
      children: [
        _buildCategoryBreakdown(analytics['categoryDistribution']),
        const SizedBox(height: 16),
        _buildTenureBreakdown(analytics['tenureDistribution']),
        const SizedBox(height: 16),
        _buildRiskBreakdown(analytics['riskDistribution']),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiversificationCard(double diversificationScore) {
    Color scoreColor;
    String scoreLabel;
    IconData scoreIcon;

    if (diversificationScore >= 70) {
      scoreColor = const Color(0xFF2E7D32);
      scoreLabel = 'Well Diversified';
      scoreIcon = Icons.verified;
    } else if (diversificationScore >= 40) {
      scoreColor = const Color(0xFFF57C00);
      scoreLabel = 'Moderately Diversified';
      scoreIcon = Icons.warning_amber;
    } else {
      scoreColor = const Color(0xFFD32F2F);
      scoreLabel = 'Concentrated';
      scoreIcon = Icons.error_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor.withOpacity(0.1), scoreColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(scoreIcon, color: scoreColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diversification Score',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${diversificationScore.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      scoreLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              value: diversificationScore / 100,
              strokeWidth: 6,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentInvestments() {
    final recentInvestments = widget.investments.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Investments',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {}, // Navigate to all investments
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...recentInvestments.map(
          (investment) => _buildInvestmentTile(investment),
        ),
      ],
    );
  }

  Widget _buildInvestmentTile(Map<String, dynamic> investment) {
    final campaign = investment['campaign'] as Campaign?;
    final amount = investment['amount'] as double? ?? 0.0;
    final calculation =
        investment['calculation'] as Map<String, dynamic>? ?? {};

    if (campaign == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => widget.onCampaignTap?.call(campaign.id),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCampaignIcon(campaign.category),
                color: const Color(0xFF2E7D32),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₦${_formatNumber(amount)} • ${calculation['roi']?.toStringAsFixed(1) ?? '0'}% ROI',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart(List<dynamic> projections) {
    if (projections.isEmpty) {
      return const Center(child: Text('No projection data available'));
    }

    // Simple bar chart representation
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children:
          projections.take(12).map((projection) {
            final month = projection['month'] as int;
            final value = projection['totalValue'] as double;
            final maxValue = projections
                .map((p) => p['totalValue'] as double)
                .reduce((a, b) => a > b ? a : b);
            final heightFactor = maxValue > 0 ? value / maxValue : 0.0;

            return Expanded(
              child: GestureDetector(
                onTap: () => _showProjectionDetails(projection),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: 120 * heightFactor,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF64B5F6),
                              const Color(0xFF1976D2),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'M$month',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildPerformanceMetrics(List<dynamic> projections) {
    if (projections.isEmpty) return const SizedBox.shrink();

    final firstMonth = projections.first;
    final lastMonth = projections.last;
    final firstValue = firstMonth['totalValue'] as double;
    final lastValue = lastMonth['totalValue'] as double;
    final growth = lastValue - firstValue;
    final growthPercentage = firstValue > 0 ? (growth / firstValue * 100) : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Total Growth',
            '₦${_formatNumber(growth)}',
            Icons.trending_up,
            const Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Growth Rate',
            '${growthPercentage.toStringAsFixed(1)}%',
            Icons.show_chart,
            const Color(0xFF1976D2),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(Map<String, double> categoryDistribution) {
    return _buildBreakdownCard(
      'Category Distribution',
      categoryDistribution,
      Icons.category,
      [
        const Color(0xFF2E7D32),
        const Color(0xFF1976D2),
        const Color(0xFFF57C00),
        const Color(0xFF7B1FA2),
      ],
    );
  }

  Widget _buildTenureBreakdown(Map<String, double> tenureDistribution) {
    return _buildBreakdownCard(
      'Tenure Distribution',
      tenureDistribution,
      Icons.schedule,
      [
        const Color(0xFF303F9F),
        const Color(0xFF009688),
        const Color(0xFF00BCD4),
        const Color(0xFFFFA000),
      ],
    );
  }

  Widget _buildRiskBreakdown(Map<String, int> riskDistribution) {
    final Map<String, double> doubleRiskDist = riskDistribution.map(
      (key, value) => MapEntry(key, value.toDouble()),
    );

    return _buildBreakdownCard(
      'Risk Distribution',
      doubleRiskDist,
      Icons.security,
      [
        const Color(0xFF2E7D32),
        const Color(0xFFF57C00),
        const Color(0xFFD32F2F),
      ],
    );
  }

  Widget _buildBreakdownCard(
    String title,
    Map<String, double> distribution,
    IconData icon,
    List<Color> colors,
  ) {
    if (distribution.isEmpty) return const SizedBox.shrink();

    final total = distribution.values.reduce((a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final entries = distribution.entries.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey[700], size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...entries.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final percentage = (item.value / total * 100);
            final color = colors[index % colors.length];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.key,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showProjectionDetails(Map<String, dynamic> projection) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Month ${projection['month']} Projection'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  'Total Value',
                  '₦${_formatNumber(projection['totalValue'])}',
                ),
                _buildDetailRow(
                  'Total Interest',
                  '₦${_formatNumber(projection['totalInterest'])}',
                ),
                _buildDetailRow(
                  'ROI',
                  '${projection['roi'].toStringAsFixed(1)}%',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  IconData _getCampaignIcon(String category) {
    switch (category.toLowerCase()) {
      case 'crop':
        return Icons.agriculture;
      case 'livestock':
        return Icons.pets;
      case 'fishery':
        return Icons.water;
      default:
        return Icons.business;
    }
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
