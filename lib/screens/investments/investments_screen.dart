import 'package:flutter/material.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  // Mock data inspired by the provided design
  final List<InvestmentCampaign> campaigns = [
    InvestmentCampaign(
      riskLevel: 'CONSERVATIVE',
      riskColor: Colors.blue,
      annualReturn: 20.85,
      icon: Icons.account_balance,
      title: 'Cowrywise Investment Portfolio',
      subtitle: 'Structured Loan Fund',
    ),
    InvestmentCampaign(
      riskLevel: 'MODERATE',
      riskColor: Colors.orange,
      annualReturn: 15.2,
      icon: Icons.security,
      title: 'TrustBank Money Market Fund',
      subtitle: 'Diversified Loan Portfolio',
    ),
    InvestmentCampaign(
      riskLevel: 'AGGRESSIVE',
      riskColor: Colors.red,
      annualReturn: 28.5,
      icon: Icons.trending_up,
      title: 'High Yield Structured Loans',
      subtitle: 'Venture Debt Opportunities',
    ),
    // Add more mock campaigns as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investment Campaigns'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: campaigns.length,
          itemBuilder: (context, index) {
            final campaign = campaigns[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8.0),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Risk badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: campaign.riskColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            campaign.riskLevel == 'CONSERVATIVE'
                                ? Icons.shield
                                : campaign.riskLevel == 'MODERATE'
                                ? Icons.warning
                                : Icons.dangerous,
                            color: campaign.riskColor,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            campaign.riskLevel,
                            style: TextStyle(
                              color: campaign.riskColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Main content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                campaign.icon,
                                color: Colors.green,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      campaign.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      campaign.subtitle,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Return percentage
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 12.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${campaign.annualReturn}%',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const Text(
                                      'Annual Returns',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 10,
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
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class InvestmentCampaign {
  final String riskLevel;
  final Color riskColor;
  final double annualReturn;
  final IconData icon;
  final String title;
  final String subtitle;

  InvestmentCampaign({
    required this.riskLevel,
    required this.riskColor,
    required this.annualReturn,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
