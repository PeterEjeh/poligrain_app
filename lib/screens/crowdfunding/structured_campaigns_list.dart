import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:async';

import 'package:poligrain_app/models/campaign.dart';
import 'package:poligrain_app/screens/crowdfunding/campaign_detail_screen.dart';

String formatNaira(num amount) {
  final formatter = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 2,
  );
  return formatter.format(amount);
}

class StructuredCampaignsList extends StatefulWidget {
  const StructuredCampaignsList({super.key});

  @override
  State<StructuredCampaignsList> createState() =>
      _StructuredCampaignsListState();
}

class _StructuredCampaignsListState extends State<StructuredCampaignsList> {
  late Future<List<Campaign>> _campaignsFuture;

  @override
  void initState() {
    super.initState();
    _campaignsFuture = _fetchStructuredCampaigns();
  }

  Future<List<Campaign>> _fetchStructuredCampaigns() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        throw Exception('You must be signed in to view campaigns.');
      }

      safePrint('Making API call to fetch all structured campaigns');
      final restOperation = Amplify.API.get(
        '/loan-requests',
        apiName: 'PoligrainAPI',
        queryParameters: {'type': 'structured'},
      );
      final response = await restOperation.response;

      safePrint('API status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = response.decodeBody();
        safePrint('API body: $body');

        if (body.trim().isNotEmpty) {
          try {
            final dynamic decoded = jsonDecode(body);
            List<dynamic> campaigns;
            if (decoded is List) {
              campaigns = decoded;
            } else if (decoded is Map && decoded.containsKey('campaigns')) {
              campaigns = List<dynamic>.from(decoded['campaigns'] ?? []);
            } else {
              campaigns = [];
            }

            return campaigns.map((json) => Campaign.fromJson(json)).toList();
          } catch (jsonError) {
            safePrint('JSON parsing error: $jsonError');
          }
        }
      }
      return [];
    } on ApiException catch (e) {
      safePrint('API Error: ${e.toString()}');
      throw Exception('Failed to load campaigns: ${e.message}');
    } catch (e) {
      safePrint('Error: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Structured Campaigns',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Campaign>>(
        future: _campaignsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[400], size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Unable to load campaigns',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _campaignsFuture = _fetchStructuredCampaigns();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.agriculture_outlined,
                      color: Colors.grey[400],
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Structured Campaigns Available',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for new agricultural investment opportunities',
                      style: TextStyle(color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final campaigns = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: campaigns.length,
              itemBuilder: (context, index) {
                final campaign = campaigns[index];
                return _buildCampaignCard(campaign);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCampaignCard(Campaign campaign) {
    final estimatedReturn =
        campaign.returnRate.isNotEmpty
            ? campaign.returnRate.values.first
            : 18.0; // Default if no specific return rate
    final displayTenure = campaign.gestationPeriod ?? 'N/A';
    final imagePath =
        campaign.imageUrls.isNotEmpty
            ? campaign.imageUrls.first
            : 'assets/images/default_campaign.jpg'; // Default image

    return Card(
      elevation: 0, // Remove elevation for a flatter look
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Clip image to card shape
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!), // Add a subtle border
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${estimatedReturn.toStringAsFixed(1)}% Est. Return',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 0, 0, 0),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildDetailRow(
                      icon: Icons.monetization_on_outlined,
                      label: 'Target Amount:',
                      value: formatNaira(campaign.targetAmount),
                    ),
                    const SizedBox(height: 4),
                    _buildDetailRow(
                      icon: Icons.timelapse_outlined,
                      label: 'Tenure:',
                      value: displayTenure,
                    ),
                    const SizedBox(height: 4),
                    _buildDetailRow(
                      icon: Icons.info_outline,
                      label: 'Status:',
                      value: campaign.status,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      CampaignDetailScreen(campaign: campaign),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0, // Remove button elevation
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imagePath,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[400],
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  void _showInvestmentDialog(BuildContext context, Campaign campaign) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Invest in ${campaign.title}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Target Amount: ${formatNaira(campaign.targetAmount)}'),
                const SizedBox(height: 8),
                if (campaign.gestationPeriod != null &&
                    campaign.gestationPeriod!.isNotEmpty) ...[
                  Text('Tenure: ${campaign.gestationPeriod}'),
                  const SizedBox(height: 8),
                ],
                Text('Status: ${campaign.status}'),
                const SizedBox(height: 16),
                const Text('Enter investment amount:'),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '₦0.00',
                    prefixText: '₦',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final amount =
                      double.tryParse(
                        amountController.text.replaceAll('₦', ''),
                      ) ??
                      0;
                  if (amount > 0) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Investment of ₦${amount.toStringAsFixed(2)} submitted!',
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid amount'),
                      ),
                    );
                  }
                },
                child: const Text('Invest'),
              ),
            ],
          ),
    );
  }
}
