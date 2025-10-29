import 'package:flutter/material.dart';
import 'package:poligrain_app/services/campaign_service.dart';
import 'package:poligrain_app/models/campaign.dart';
import 'package:poligrain_app/models/campaign_enum.dart';
import 'package:poligrain_app/exceptions/campaign_exceptions.dart';

/// Example widget demonstrating how to use the CampaignService
class CampaignServiceExampleWidget extends StatefulWidget {
  const CampaignServiceExampleWidget({Key? key}) : super(key: key);

  @override
  State<CampaignServiceExampleWidget> createState() => _CampaignServiceExampleWidgetState();
}

class _CampaignServiceExampleWidgetState extends State<CampaignServiceExampleWidget> {
  final CampaignService _campaignService = CampaignService();
  List<Campaign> _campaigns = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    // Initialize the campaign service
    await _campaignService.initialize();
    // Load initial data
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get campaigns with optional filtering
      final campaigns = await _campaignService.getCampaigns(
        status: CampaignStatus.active,
        limit: 10,
      );

      setState(() {
        _campaigns = campaigns;
        _isLoading = false;
      });
    } on CampaignException catch (e) {
      setState(() {
        _errorMessage = e.userFriendlyMessage;
        _isLoading = false;
      });

      // Show error dialog
      _showErrorDialog(e);
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred';
        _isLoading = false;
      });
    }
  }

  Future<void> _createSampleCampaign() async {
    try {
      final newCampaign = Campaign.createDraft(
        title: 'Sample Maize Farm Campaign',
        description: 'This is a sample campaign created for demonstration purposes. '
            'It represents a typical agricultural investment opportunity in Nigeria.',
        type: 'investment',
        targetAmount: 1000000.0,
        minimumInvestment: 50000.0,
        category: 'Crop',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 90)),
        tenureOptions: ['6 months', '1 year'],
      );

      final createdCampaign = await _campaignService.createCampaign(newCampaign);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Campaign created: ${createdCampaign.title}')),
      );

      // Refresh the list
      _loadCampaigns();
    } on CampaignException catch (e) {
      _showErrorDialog(e);
    }
  }

  Future<void> _loadTrendingCampaigns() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final campaigns = await _campaignService.getTrendingCampaigns(limit: 5);
      
      setState(() {
        _campaigns = campaigns;
        _isLoading = false;
      });
    } on CampaignException catch (e) {
      setState(() {
        _errorMessage = e.userFriendlyMessage;
        _isLoading = false;
      });
      _showErrorDialog(e);
    }
  }

  Future<void> _searchCampaigns(String query) async {
    if (query.isEmpty) {
      _loadCampaigns();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final campaigns = await _campaignService.searchCampaigns(
        query: query,
        limit: 20,
      );
      
      setState(() {
        _campaigns = campaigns;
        _isLoading = false;
      });
    } on CampaignException catch (e) {
      setState(() {
        _errorMessage = e.userFriendlyMessage;
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(CampaignException exception) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(exception.isAuthError ? 'Authentication Required' : 'Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exception.userFriendlyMessage),
            if (exception.suggestedActions.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Suggested actions:', 
                style: TextStyle(fontWeight: FontWeight.bold)),
              ...exception.suggestedActions.map(
                (action) => Text('• $action'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (exception.isNetworkError || exception.isServerError)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadCampaigns();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  Future<void> _showCacheStats() async {
    final stats = await _campaignService.getCacheStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Entries: ${stats['totalEntries']}'),
            Text('Active Entries: ${stats['activeEntries']}'),
            Text('Expired Entries: ${stats['expiredEntries']}'),
            Text('Cache Size: ${stats['totalSizeKB']} KB'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () async {
              await _campaignService.clearCache();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaign Service Example'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'trending':
                  _loadTrendingCampaigns();
                  break;
                case 'refresh':
                  _loadCampaigns();
                  break;
                case 'cache_stats':
                  _showCacheStats();
                  break;
                case 'create':
                  _createSampleCampaign();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'trending',
                child: Text('Load Trending'),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Text('Refresh'),
              ),
              const PopupMenuItem(
                value: 'cache_stats',
                child: Text('Cache Stats'),
              ),
              const PopupMenuItem(
                value: 'create',
                child: Text('Create Sample'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search campaigns...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: _searchCampaigns,
            ),
          ),
          
          // Error message
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),

          // Loading indicator or campaigns list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _campaigns.isEmpty
                    ? const Center(
                        child: Text('No campaigns found'),
                      )
                    : ListView.builder(
                        itemCount: _campaigns.length,
                        itemBuilder: (context, index) {
                          final campaign = _campaigns[index];
                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: ListTile(
                              title: Text(campaign.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    campaign.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(campaign.status),
                                        backgroundColor: _getStatusColor(campaign.status),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '₦${campaign.targetAmount.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Text(
                                '${campaign.fundingProgress.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () => _showCampaignDetails(campaign),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green.shade100;
      case 'draft':
        return Colors.orange.shade100;
      case 'completed':
        return Colors.blue.shade100;
      case 'cancelled':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  void _showCampaignDetails(Campaign campaign) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(campaign.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type: ${campaign.type}'),
              Text('Category: ${campaign.category}'),
              Text('Status: ${campaign.status}'),
              Text('Target: ₦${campaign.targetAmount.toStringAsFixed(0)}'),
              Text('Raised: ₦${campaign.totalRaised.toStringAsFixed(0)}'),
              Text('Progress: ${campaign.fundingProgress.toStringAsFixed(1)}%'),
              Text('Investors: ${campaign.investorCount}'),
              Text('Days remaining: ${campaign.daysRemaining}'),
              const SizedBox(height: 16),
              Text('Description:', style: Theme.of(context).textTheme.titleSmall),
              Text(campaign.description),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
