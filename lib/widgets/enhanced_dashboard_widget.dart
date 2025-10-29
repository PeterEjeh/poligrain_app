import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Added import for NumberFormat
import '../models/campaign_milestone.dart';
import '../services/campaign_service.dart';
import '../services/milestone_tracking_service.dart';
import '../widgets/milestone_tracking_widget.dart';

/// Enhanced dashboard widget with milestone tracking
class EnhancedDashboardWidget extends StatefulWidget {
  const EnhancedDashboardWidget({super.key});

  @override
  State<EnhancedDashboardWidget> createState() =>
      _EnhancedDashboardWidgetState();
}

class _EnhancedDashboardWidgetState extends State<EnhancedDashboardWidget> {
  final CampaignService _campaignService = CampaignService();
  final MilestoneTrackingService _milestoneService = MilestoneTrackingService();

  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final dashboardData = await _campaignService.getUserDashboardData();

      setState(() {
        _dashboardData = dashboardData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatNaira(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_dashboardData == null) {
      return const Center(child: Text('No dashboard data available'));
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 20),
            _buildSummaryCards(),
            const SizedBox(height: 20),
            _buildUpcomingMilestones(),
            const SizedBox(height: 20),
            _buildOverdueMilestones(),
            const SizedBox(height: 20),
            _buildRecentCampaigns(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Failed to load dashboard',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.red[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Here\'s an overview of your investments and campaign progress',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final data = _dashboardData!;
    final totalInvested = data['totalInvested'] as double;
    final activeInvestments = data['activeInvestments'] as int;
    final completedCampaigns = data['completedCampaigns'] as int;
    final campaigns = data['campaigns'] as List;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Invested',
            '\$${totalInvested.toStringAsFixed(0)}',
            Icons.account_balance_wallet,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Active',
            activeInvestments.toString(),
            Icons.trending_up,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Completed',
            completedCampaigns.toString(),
            Icons.check_circle,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Total Campaigns',
            campaigns.length.toString(),
            Icons.campaign,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingMilestones() {
    final upcomingMilestones = _dashboardData!['upcomingMilestones'] as List;

    if (upcomingMilestones.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Milestones',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => _showAllMilestones('upcoming'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: upcomingMilestones.take(5).length,
            itemBuilder: (context, index) {
              final milestoneData =
                  upcomingMilestones[index] as Map<String, dynamic>;
              final milestone = CampaignMilestone.fromJson(milestoneData);
              return _buildMilestoneCard(milestone, false);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOverdueMilestones() {
    final overdueMilestones = _dashboardData!['overdueMilestones'] as List;

    if (overdueMilestones.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Overdue Milestones',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => _showAllMilestones('overdue'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: overdueMilestones.take(5).length,
            itemBuilder: (context, index) {
              final milestoneData =
                  overdueMilestones[index] as Map<String, dynamic>;
              final milestone = CampaignMilestone.fromJson(milestoneData);
              return _buildMilestoneCard(milestone, true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneCard(CampaignMilestone milestone, bool isOverdue) {
    final color = isOverdue ? Colors.red : Colors.orange;
    final daysText =
        isOverdue
            ? '${milestone.daysOverdue} days overdue'
            : 'Due in ${milestone.daysUntilTarget} days';

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOverdue ? Icons.warning : Icons.schedule,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  milestone.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            milestone.description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  daysText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCampaigns() {
    final campaigns = _dashboardData!['campaigns'] as List;

    if (campaigns.isEmpty) {
      return _buildNoCampaignsWidget();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Campaigns',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => _showAllCampaigns(),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: campaigns.take(3).length,
          itemBuilder: (context, index) {
            final campaignData = campaigns[index] as Map<String, dynamic>;
            return _buildCampaignCard(campaignData);
          },
        ),
      ],
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> campaignData) {
    final campaign = campaignData['campaign'] as Map<String, dynamic>;
    final analytics = campaignData['analytics'] as Map<String, dynamic>?;

    final title = campaign['title'] as String? ?? 'Untitled Campaign';
    final category = campaign['category'] as String? ?? '';
    final targetAmount = (campaign['targetAmount'] as num?)?.toDouble() ?? 0.0;
    final currentAmount =
        (campaign['currentAmount'] as num?)?.toDouble() ?? 0.0;
    final progress =
        targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0.0;

    final completionRate = analytics?['completionRate'] as double? ?? 0.0;
    final totalMilestones = analytics?['total'] as int? ?? 0;
    final completedMilestones = analytics?['completed'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showCampaignDetails(campaign['id'] as String),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(campaign['estimatedReturn'] as double? ?? 0.0).toStringAsFixed(1)}% Est. Return',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Target: ${_formatNaira(targetAmount)} \u2022 ${(campaign['duration'] as String? ?? 'N/A')}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              () => _showCampaignDetails(
                                campaign['id'] as String,
                              ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('View Details'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[400],
                      size: 40,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoCampaignsWidget() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.campaign, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No campaigns yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Start investing in agricultural campaigns to see them here',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _navigateToMarketplace(),
            child: const Text('Browse Campaigns'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'funded':
        return Colors.blue;
      case 'completed':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showAllMilestones(String type) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${type == 'upcoming' ? 'Upcoming' : 'Overdue'} Milestones',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount:
                          ((type == 'upcoming'
                                          ? _dashboardData!['upcomingMilestones']
                                          : _dashboardData!['overdueMilestones'])
                                      as List? ??
                                  [])
                              .length,
                      itemBuilder: (context, index) {
                        final milestones =
                            (type == 'upcoming'
                                    ? _dashboardData!['upcomingMilestones']
                                    : _dashboardData!['overdueMilestones'])
                                as List;
                        final milestoneData =
                            milestones[index] as Map<String, dynamic>;
                        final milestone = CampaignMilestone.fromJson(
                          milestoneData,
                        );

                        return ListTile(
                          leading: Icon(
                            type == 'upcoming' ? Icons.schedule : Icons.warning,
                            color:
                                type == 'upcoming' ? Colors.orange : Colors.red,
                          ),
                          title: Text(milestone.title),
                          subtitle: Text(milestone.description),
                          trailing: Text(
                            type == 'upcoming'
                                ? 'Due in ${milestone.daysUntilTarget} days'
                                : '${milestone.daysOverdue} days overdue',
                            style: TextStyle(
                              color:
                                  type == 'upcoming'
                                      ? Colors.orange
                                      : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap:
                              () => _showCampaignDetails(milestone.campaignId),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showAllCampaigns() {
    // Navigate to campaigns list screen
    // Implementation depends on your navigation setup
  }

  void _showCampaignDetails(String campaignId) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              child: MilestoneTrackingWidget(
                campaignId: campaignId,
                onMilestoneUpdated: _loadDashboardData,
              ),
            ),
          ),
    );
  }

  void _navigateToMarketplace() {
    // Navigate to marketplace screen
    // Implementation depends on your navigation setup
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$label ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey[800], fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
