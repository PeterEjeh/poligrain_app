import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:poligrain_app/models/campaign.dart';
import 'package:poligrain_app/screens/crowdfunding/invest_now_screen.dart';
import 'package:poligrain_app/screens/crowdfunding/crowdfunding_screen.dart';

String formatNaira(num amount) {
  final formatter = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 2,
  );
  return formatter.format(amount);
}

class CampaignDetailScreen extends StatefulWidget {
  final Campaign campaign;

  const CampaignDetailScreen({super.key, required this.campaign});

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final isStructured = widget.campaign.type == 'structured';
    // Assuming a default return rate or taking the first available if tenureOptions exist
    final estimatedReturn =
        widget.campaign.returnRate.isNotEmpty
            ? widget.campaign.returnRate.values.first
            : (isStructured ? 18.5 : 12.0);
    final String? mainImage =
        widget.campaign.imageUrls.isNotEmpty
            ? widget.campaign.imageUrls.first
            : null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(
          kToolbarHeight + 20,
        ), // Adjust height as needed
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 56, 12, 12),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.black87,
                    size: 18,
                  ),
                  padding: const EdgeInsets.all(8),
                  splashRadius: 20,
                ),
              ),
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Text(
                      'Campaign Details',
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
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image with fallback to assets/images/market.jpg
            SizedBox(
              height: 220,
              width: double.infinity,
              child:
                  mainImage != null
                      ? Image.network(
                        mainImage,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Image.asset(
                              'assets/images/market.jpg',
                              fit: BoxFit.cover,
                            ),
                      )
                      : Image.asset(
                        'assets/images/market.jpg',
                        fit: BoxFit.cover,
                      ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.campaign.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.campaign.description,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),

                  // Horizontal thumbnail gallery
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          widget.campaign.imageUrls.isNotEmpty
                              ? widget.campaign.imageUrls.asMap().entries.map((
                                entry,
                              ) {
                                int index = entry.key;
                                String url = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        // Removed ClipRRect
                                        width: 96,
                                        height: 72,
                                        child: Image.network(
                                          url,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Image.asset(
                                                    'assets/images/market.jpg',
                                                    fit: BoxFit.cover,
                                                  ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Farm ${index + 1}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList()
                              : [
                                Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        // Removed ClipRRect
                                        width: 96,
                                        height: 72,
                                        child: Image.asset(
                                          'assets/images/market.jpg',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Farm 1', // Default for no images
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Raised amount and progress
                  Row(
                    children: [
                      const Text(
                        'Raised',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value:
                                widget.campaign.targetAmount > 0
                                    ? (widget.campaign.totalRaised /
                                        widget.campaign.targetAmount)
                                    : 0,
                            backgroundColor: Colors.green[100],
                            valueColor: const AlwaysStoppedAnimation(
                              Colors.green,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.campaign.totalRaised.toInt()}', // Display as integer
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Target: ${formatNaira(widget.campaign.targetAmount)}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Details section (no longer a Card)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ), // Adjusted padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'Duration',
                    widget.campaign.gestationPeriod ?? 'N/A',
                  ),
                  _buildDetailItem('Status', widget.campaign.status),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            final loanRequest = LoanRequest(
                              id: widget.campaign.id,
                              loanType: widget.campaign.type,
                              amount: widget.campaign.targetAmount,
                              tenure: widget.campaign.gestationPeriod ?? 'N/A',
                              status: widget.campaign.status,
                              createdAt:
                                  widget.campaign.createdAt.toIso8601String(),
                              campaignName: widget.campaign.title,
                            );
                            return InvestNowScreen(campaign: loanRequest);
                          },
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
                      'Invest Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Implement watchlist toggle
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to watchlist')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text('Add to Watchlist'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          Flexible(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
