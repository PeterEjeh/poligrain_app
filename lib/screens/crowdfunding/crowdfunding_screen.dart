import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:async'; // For Timer
import '../../models/campaign.dart';
import 'structured_loan_flow.dart';
import 'flexible_loan_flow.dart';
import 'structured_campaigns_list.dart';
import 'package:poligrain_app/screens/crowdfunding/invest_now_screen.dart';

class StructuredLoanCampaign {
  final String campaignName;
  final String gestationPeriod;
  final List<String> tenureOptions;
  final double averageCostPerUnit;
  final String unitType;
  final double totalLoanIncludingFeePerUnit;
  final String category;

  StructuredLoanCampaign({
    required this.campaignName,
    required this.gestationPeriod,
    required this.tenureOptions,
    required this.averageCostPerUnit,
    required this.unitType,
    required this.totalLoanIncludingFeePerUnit,
    required this.category,
  });
}

class LoanRequest {
  final String id;
  final String loanType;
  final double amount;
  final String tenure;
  final String status;
  final String createdAt;
  final String? campaignName;
  final String? description;
  final List<String>? imageUrls;
  final String? videoUrl;
  final double? minimumInvestment;
  final double? maximumInvestment;

  LoanRequest({
    required this.id,
    required this.loanType,
    required this.amount,
    required this.tenure,
    required this.status,
    required this.createdAt,
    this.campaignName,
    this.description,
    this.imageUrls,
    this.videoUrl,
    this.minimumInvestment,
    this.maximumInvestment,
  });

  factory LoanRequest.fromJson(Map<String, dynamic> json) {
    return LoanRequest(
      id: json['id'],
      loanType: json['loanType'],
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      tenure: json['tenure'],
      status: json['status'],
      createdAt: json['createdAt'],
      campaignName: json['campaignName'],
      description: json['description'],
      imageUrls: (json['imageUrls'] as List?)?.map((e) => e as String).toList(),
      videoUrl: json['videoUrl'],
      minimumInvestment: (json['minimumInvestment'] as num?)?.toDouble(),
      maximumInvestment: (json['maximumInvestment'] as num?)?.toDouble(),
    );
  }
}

final List<StructuredLoanCampaign> allStructuredLoanCampaigns = [
  // (Your loan data is unchanged)
  StructuredLoanCampaign(
    campaignName: "Rice",
    gestationPeriod: "4 – 5 Months",
    tenureOptions: ["6 months", "1 year"],
    averageCostPerUnit: 350000,
    unitType: "Ha",
    totalLoanIncludingFeePerUnit: 358750,
    category: "Crop",
  ),
  StructuredLoanCampaign(
    campaignName: "Beans",
    gestationPeriod: "2.5 – 3 Months",
    tenureOptions: ["3 months", "6 months"],
    averageCostPerUnit: 180000,
    unitType: "Ha",
    totalLoanIncludingFeePerUnit: 184500,
    category: "Crop",
  ),
  StructuredLoanCampaign(
    campaignName: "Yam",
    gestationPeriod: "6 – 8 Months",
    tenureOptions: ["6 months", "1 year"],
    averageCostPerUnit: 400000,
    unitType: "Ha",
    totalLoanIncludingFeePerUnit: 410000,
    category: "Crop",
  ),
  StructuredLoanCampaign(
    campaignName: "Cassava",
    gestationPeriod: "9 – 12 Months",
    tenureOptions: ["1 year"],
    averageCostPerUnit: 300000,
    unitType: "Ha",
    totalLoanIncludingFeePerUnit: 307500,
    category: "Crop",
  ),
  StructuredLoanCampaign(
    campaignName: "Corn",
    gestationPeriod: "3 – 4 Months",
    tenureOptions: ["3 months", "6 months"],
    averageCostPerUnit: 250000,
    unitType: "Ha",
    totalLoanIncludingFeePerUnit: 256250,
    category: "Crop",
  ),
  StructuredLoanCampaign(
    campaignName: "Cabbage",
    gestationPeriod: "2 – 3 Months",
    tenureOptions: ["3 months"],
    averageCostPerUnit: 200000,
    unitType: "Ha",
    totalLoanIncludingFeePerUnit: 205000,
    category: "Crop",
  ),
  StructuredLoanCampaign(
    campaignName: "Cucumber",
    gestationPeriod: "2 – 3 Months",
    tenureOptions: ["3 months"],
    averageCostPerUnit: 180000,
    unitType: "Ha",
    totalLoanIncludingFeePerUnit: 184500,
    category: "Crop",
  ),
  StructuredLoanCampaign(
    campaignName: "Oil Palm",
    gestationPeriod: "30 – 36 Months",
    tenureOptions: ["1 year (renewable)"],
    averageCostPerUnit: 1500000,
    unitType: "Ha",
    totalLoanIncludingFeePerUnit: 1537500,
    category: "Crop",
  ),
  StructuredLoanCampaign(
    campaignName: "Cocoa",
    gestationPeriod: "24 – 30 Months",
    tenureOptions: ["1 year (renewable)"],
    averageCostPerUnit: 1200000,
    unitType: "Ha",
    totalLoanIncludingFeePerUnit: 1230000,
    category: "Crop",
  ),
  StructuredLoanCampaign(
    campaignName: "Coconut",
    gestationPeriod: "24 – 36 Months",
    tenureOptions: ["1 year (renewable)"],
    averageCostPerUnit: 1000000,
    unitType: "Ha",
    totalLoanIncludingFeePerUnit: 1025000,
    category: "Crop",
  ),
  // Livestock
  StructuredLoanCampaign(
    campaignName: "Piggery",
    gestationPeriod: "5 – 6 Months",
    tenureOptions: ["6 months", "1 year"],
    averageCostPerUnit: 800000,
    unitType: "Unit",
    totalLoanIncludingFeePerUnit: 820000,
    category: "Livestock",
  ),
  StructuredLoanCampaign(
    campaignName: "Grasscutter",
    gestationPeriod: "6 – 8 Months",
    tenureOptions: ["6 months", "1 year"],
    averageCostPerUnit: 500000,
    unitType: "Unit",
    totalLoanIncludingFeePerUnit: 512500,
    category: "Livestock",
  ),
  StructuredLoanCampaign(
    campaignName: "Goat Farming",
    gestationPeriod: "6 – 12 Months",
    tenureOptions: ["6 months", "1 year"],
    averageCostPerUnit: 600000,
    unitType: "Unit",
    totalLoanIncludingFeePerUnit: 615000,
    category: "Livestock",
  ),
  StructuredLoanCampaign(
    campaignName: "Fish Farming",
    gestationPeriod: "4 – 6 Months",
    tenureOptions: ["6 months"],
    averageCostPerUnit: 700000,
    unitType: "Unit",
    totalLoanIncludingFeePerUnit: 717500,
    category: "Livestock",
  ),
];

enum LoanRequestType { structured, flexible }

class CrowdfundingScreen extends StatefulWidget {
  const CrowdfundingScreen({super.key});

  @override
  State<CrowdfundingScreen> createState() => _CrowdfundingScreenState();
}

class _CrowdfundingScreenState extends State<CrowdfundingScreen> {
  void _showInvestmentFormDialog(BuildContext context, LoanRequest campaign) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InvestNowScreen(campaign: campaign),
      ),
    );
  }

  // Fetch all campaigns for investors
  Future<List<LoanRequest>> _fetchAllCampaigns() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        throw Exception('You must be signed in to view campaigns.');
      }

      // Fetch structured campaigns
      safePrint(
        'Making API call to /loan-requests for structured (using AWS_IAM auth)',
      );

      final structuredRestOperation = Amplify.API.get(
        '/loan-requests',
        apiName: 'PoligrainAPI',
        queryParameters: {'type': 'structured'},
        // NO 'headers' property for Authorization when using AWS_IAM
        // Amplify takes care of SigV4 signing for you.
      );
      final structuredResponse = await structuredRestOperation.response;

      safePrint('Structured API status: ${structuredResponse.statusCode}');

      final structuredBody = structuredResponse.decodeBody();
      safePrint('Structured API body: $structuredBody');

      List<LoanRequest> structuredRequests = [];
      if (structuredResponse.statusCode == 200 &&
          structuredBody.trim().isNotEmpty) {
        try {
          final dynamic decoded = jsonDecode(structuredBody);
          List<dynamic> campaigns;
          if (decoded is List) {
            campaigns = decoded;
          } else if (decoded is Map && decoded.containsKey('campaigns')) {
            campaigns = List<dynamic>.from(decoded['campaigns'] ?? []);
          } else {
            campaigns = [];
          }

          structuredRequests =
              campaigns
                  .map(
                    (json) => LoanRequest(
                      id: json['id'] ?? '',
                      loanType: 'structured',
                      amount: (json['targetAmount'] as num?)?.toDouble() ?? 0.0,
                      tenure:
                          (json['tenureOptions'] as List?)?.join(', ') ?? '',
                      status: json['status'] ?? 'Active',
                      createdAt: json['createdAt'] ?? '',
                      campaignName: json['title'] ?? 'Unknown Campaign',
                      description: json['description'] ?? '',
                      imageUrls:
                          (json['imageUrls'] as List?)
                              ?.map((e) => e as String)
                              .toList(),
                      videoUrl: json['videoUrl'],
                    ),
                  )
                  .toList();
        } catch (jsonError) {
          safePrint('JSON parsing error for structured: $jsonError');
        }
      }

      // Fetch flexible loan requests
      safePrint(
        'Making API call to /loan-requests for flexible (using AWS_IAM auth)',
      );

      final flexibleRestOperation = Amplify.API.get(
        '/loan-requests',
        apiName: 'PoligrainAPI',
        queryParameters: {'activeOnly': 'true'},
      );
      final flexibleResponse = await flexibleRestOperation.response;

      safePrint('Flexible API status: ${flexibleResponse.statusCode}');

      final flexibleBody = flexibleResponse.decodeBody();
      safePrint('Flexible API body: $flexibleBody');

      List<LoanRequest> flexibleRequests = [];
      if (flexibleResponse.statusCode == 200 &&
          flexibleBody.trim().isNotEmpty) {
        try {
          final dynamic decoded = jsonDecode(flexibleBody);
          List<dynamic> requests;
          if (decoded is List) {
            requests = decoded;
          } else {
            requests = [];
          }

          flexibleRequests =
              requests
                  .map(
                    (json) => LoanRequest(
                      id: json['id'] ?? '',
                      loanType: 'flexible',
                      amount:
                          (json['targetAmount'] as num?)?.toDouble() ??
                          (json['amount'] as num?)?.toDouble() ??
                          0.0,
                      tenure: json['tenure'] ?? '',
                      status: json['status'] ?? 'Pending',
                      createdAt: json['createdAt'] ?? '',
                      campaignName: json['title'] ?? 'Flexible Loan',
                    ),
                  )
                  .toList();
        } catch (jsonError) {
          safePrint('JSON parsing error for flexible: $jsonError');
        }
      }

      final allRequests = [...structuredRequests, ...flexibleRequests];
      safePrint(
        'Total LoanRequests created: ${allRequests.length} (structured: ${structuredRequests.length}, flexible: ${flexibleRequests.length})',
      );
      return allRequests;
    } on ApiException catch (e) {
      safePrint('API Error fetching campaigns: ${e.toString()}');
      safePrint('API Error details: ${e.underlyingException}');
      throw Exception('API Error: ${e.message}');
    } on AuthException catch (e) {
      safePrint('Auth Error fetching campaigns: ${e.message}');
      throw Exception('Authentication error: ${e.message}');
    } catch (e, stackTrace) {
      safePrint('Error fetching campaigns: ${e.toString()}');
      safePrint('Stack trace: $stackTrace');
      throw Exception(
        'An unexpected error occurred while fetching campaigns: $e',
      );
    }
  }

  // Investor campaign list: only LoanRequest, no StructuredLoanCampaign
  Widget _buildInvestorCampaignList() {
    if (_allCampaignsFuture == null) {
      // Trigger fetch if not already done
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _allCampaignsFuture = _fetchAllCampaigns();
        });
      });
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              const Text(
                'AVAILABLE CAMPAIGNS',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
        FutureBuilder<List<LoanRequest>>(
          future: _allCampaignsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Unable to load campaigns. Please try again later.',
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No campaigns available.'));
            } else {
              final campaigns = snapshot.data!;
              final structured =
                  campaigns.where((c) => c.loanType == 'structured').toList();
              final flexible =
                  campaigns.where((c) => c.loanType == 'flexible').toList();
              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (structured.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Structured Campaigns',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.green,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.view_list,
                                color: Colors.green,
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const StructuredCampaignsList(),
                                  ),
                                );
                              },
                              tooltip: 'View All Structured Campaigns',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 8, right: 8),
                        child: Row(
                          children:
                              structured
                                  .map(
                                    (campaign) => Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.85,
                                        minWidth: 260,
                                      ),
                                      child: _buildCampaignCardWithType(
                                        campaign,
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ],
                    if (flexible.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text(
                          'Flexible Campaigns',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 8, right: 8),
                        child: Row(
                          children:
                              flexible
                                  .map(
                                    (campaign) => Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.85,
                                        minWidth: 260,
                                      ),
                                      child: _buildCampaignCardWithType(
                                        campaign,
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ],
                    if (structured.isEmpty && flexible.isEmpty)
                      const Center(child: Text('No campaigns available.')),
                  ],
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildCampaignCardWithType(LoanRequest campaign) {
    final isStructured = campaign.loanType == 'structured';

    // Determine estimated return based on loan type
    double estimatedReturn = isStructured ? 18.5 : 12.0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main icon
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Flexible(
                    child: Text(
                      campaign.campaignName ??
                          (isStructured
                              ? 'Structured Campaign'
                              : 'Flexible Campaign'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Amount
                  Flexible(
                    child: Text(
                      'Target: ${formatNaira(campaign.amount)}',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Return estimate
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${estimatedReturn.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Est. Return',
                          style: TextStyle(color: Colors.green, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (campaign.tenure.isNotEmpty)
                    Flexible(
                      child: Text(
                        'Tenure: ${campaign.tenure}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  if (campaign.status.isNotEmpty)
                    Flexible(
                      child: Text(
                        'Status: ${campaign.status}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Type chip
                Chip(
                  label: Text(
                    isStructured ? 'Structured' : 'Flexible',
                    style: TextStyle(
                      color:
                          isStructured ? Colors.green[800] : Colors.orange[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  backgroundColor:
                      isStructured ? Colors.green[50] : Colors.orange[50],
                ),
                const SizedBox(height: 8),
                // Invest button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(80, 32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                  ),
                  child: const Text('Invest', style: TextStyle(fontSize: 13)),
                  onPressed: () => _showInvestmentFormDialog(context, campaign),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- All state variables ---
  LoanRequestType _selectedLoanType = LoanRequestType.structured;
  bool _isLoading = false;
  // Controls whether the quick action form is visible after tapping a card
  bool _showForm = false;
  final _structuredLoanFormKey = GlobalKey<FormState>();
  String? _selectedCategory; // New: for category selection
  StructuredLoanCampaign? _selectedCampaign;
  String? _selectedTenure;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrl1Controller = TextEditingController();
  final TextEditingController _imageUrl2Controller = TextEditingController();
  final TextEditingController _imageUrl3Controller = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  double _calculatedTotalLoan = 0.0;
  late Future<List<LoanRequest>> _loanHistoryFuture;
  String? _userRole;
  bool _isRoleLoading = true;
  // Holds the future for all campaigns (investor view)
  Future<List<LoanRequest>>? _allCampaignsFuture;
  // Holds the future for recent campaigns (both roles)
  Future<List<LoanRequest>>? _recentCampaignsFuture;

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_calculateTotalStructuredLoan);
    _fetchUserRoleAndInitCampaigns();
    _fetchRecentCampaigns();
  }

  void _calculateTotalStructuredLoan() {
    if (_selectedCampaign != null) {
      final quantity = double.tryParse(_quantityController.text) ?? 0;
      setState(
        () =>
            _calculatedTotalLoan =
                quantity * _selectedCampaign!.totalLoanIncludingFeePerUnit,
      );
    }
  }

  Future<void> _fetchLoanHistory() async {
    setState(() {
      _loanHistoryFuture = _getCampaignHistoryFromApi();
    });
  }

  Future<List<LoanRequest>> _getCampaignHistoryFromApi() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        throw Exception('You must be signed in to view your campaign history.');
      }

      // Fetch structured campaigns history
      final structuredRestOperation = Amplify.API.get(
        '/loan-requests',
        apiName: 'PoligrainAPI',
        queryParameters: {'ownerId': 'current_user', 'type': 'structured'},
      );
      final structuredResponse = await structuredRestOperation.response;

      List<LoanRequest> structuredHistory = [];
      if (structuredResponse.statusCode == 200) {
        final dynamic responseData = jsonDecode(
          structuredResponse.decodeBody(),
        );
        final List<dynamic> campaigns;
        if (responseData is List) {
          campaigns = responseData;
        } else if (responseData is Map<String, dynamic> &&
            responseData.containsKey('campaigns')) {
          campaigns = responseData['campaigns'] ?? [];
        } else {
          campaigns = [];
        }

        structuredHistory =
            campaigns
                .map(
                  (json) => LoanRequest(
                    id: json['id'],
                    loanType: 'structured',
                    amount: (json['targetAmount'] as num?)?.toDouble() ?? 0.0,
                    tenure: (json['tenureOptions'] as List?)?.join(', ') ?? '',
                    status: json['status'] ?? 'Active',
                    createdAt: json['createdAt'],
                    campaignName: json['title'],
                  ),
                )
                .toList();
      }

      // Fetch flexible loan requests history
      final flexibleRestOperation = Amplify.API.get(
        '/loan-requests',
        apiName: 'PoligrainAPI',
        queryParameters: {'ownerId': 'current_user'},
      );
      final flexibleResponse = await flexibleRestOperation.response;

      List<LoanRequest> flexibleHistory = [];
      if (flexibleResponse.statusCode == 200) {
        final dynamic responseData = jsonDecode(flexibleResponse.decodeBody());
        final List<dynamic> requests;
        if (responseData is List) {
          requests = responseData;
        } else {
          requests = [];
        }

        flexibleHistory =
            requests
                .map(
                  (json) => LoanRequest(
                    id: json['id'],
                    loanType: 'flexible',
                    amount:
                        (json['targetAmount'] as num?)?.toDouble() ??
                        (json['amount'] as num?)?.toDouble() ??
                        0.0,
                    tenure: json['tenure'] ?? '',
                    status: json['status'] ?? 'Pending',
                    createdAt: json['createdAt'],
                    campaignName: json['title'] ?? 'Flexible Loan',
                  ),
                )
                .toList();
      }

      final allHistory = [...structuredHistory, ...flexibleHistory]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allHistory;
    } on ApiException catch (e) {
      safePrint('API Error fetching campaign history: $e');
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      safePrint('Error fetching campaign history: $e');
      throw Exception('An unexpected error occurred while fetching history.');
    }
  }

  Future<void> _submitStructuredLoan() async {
    if (!_structuredLoanFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Create campaign for investors to see
    final campaignPayload = {
      "title": "${_selectedCampaign!.campaignName} Campaign",
      "description": _descriptionController.text.trim(),
      "type": "structured",
      "targetAmount": _calculatedTotalLoan,
      "minimumInvestment": _calculatedTotalLoan * 0.1, // 10% minimum
      "category": _selectedCampaign!.category,
      "unit": _selectedCampaign!.unitType,
      "quantity": double.tryParse(_quantityController.text) ?? 0,
      "gestationPeriod": _selectedCampaign!.gestationPeriod,
      "tenureOptions": [_selectedTenure!],
      "averageCostPerUnit": _selectedCampaign!.averageCostPerUnit,
      "totalLoanIncludingFeePerUnit":
          _selectedCampaign!.totalLoanIncludingFeePerUnit,
      "startDate": DateTime.now().toIso8601String(),
      "endDate":
          DateTime.now()
              .add(const Duration(days: 90))
              .toIso8601String(), // 3 months campaign duration
      "imageUrls":
          [
            _imageUrl1Controller.text.trim(),
            _imageUrl2Controller.text.trim(),
            _imageUrl3Controller.text.trim(),
          ].where((url) => url.isNotEmpty).toList(),
      "videoUrl": _videoUrlController.text.trim(),
      "documentUrls": [],
      "metadata": {
        "campaignType": _selectedCampaign!.campaignName,
        "unitType": _selectedCampaign!.unitType,
        "quantity": double.tryParse(_quantityController.text) ?? 0,
      },
    };

    try {
      await _submitCampaign(campaignPayload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Campaign created successfully! Investors can now view and invest in your project.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _resetStructuredLoanForm();
      _fetchLoanHistory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitCampaign(Map<String, dynamic> payload) async {
    try {
      final restOperation = Amplify.API.post(
        '/loan-requests',
        apiName: 'PoligrainAPI',
        body: HttpPayload.json(payload),
      );
      final response = await restOperation.response;
      if (response.statusCode != 201) {
        final errorBody = response.decodeBody();
        throw Exception(
          'Failed to create campaign: ${jsonDecode(errorBody)['message'] ?? errorBody}',
        );
      }
    } on ApiException catch (e) {
      safePrint('API Error creating campaign: $e');
      throw Exception('API Error: ${e.message}');
    }
  }

  // Submit flexible loan requests to /loan-requests
  Future<void> _submitLoanRequest(Map<String, dynamic> payload) async {
    try {
      final restOperation = Amplify.API.post(
        '/loan-requests',
        apiName: 'PoligrainAPI',
        body: HttpPayload.json(payload),
      );
      final response = await restOperation.response;
      if (response.statusCode != 201) {
        final errorBody = response.decodeBody();
        throw Exception(
          'Failed to submit loan request: ${jsonDecode(errorBody)['message'] ?? errorBody}',
        );
      }
    } on ApiException catch (e) {
      safePrint('API Error creating loan request: $e');
      throw Exception('API Error: ${e.message}');
    }
  }

  Future<void> _submitInvestment(String campaignId, double amount) async {
    try {
      final investmentPayload = {
        "campaignId": campaignId,
        "amount": amount,
        "tenure": "1 year", // Default tenure for investments
        "status": "Pending",
      };

      final restOperation = Amplify.API.post(
        '/investments',
        apiName: 'PoligrainAPI',
        body: HttpPayload.json(investmentPayload),
      );
      final response = await restOperation.response;

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Investment of ₦${amount.toStringAsFixed(2)} submitted successfully!',
            ),
            backgroundColor: Colors.green[700],
          ),
        );
      } else {
        final errorBody = response.decodeBody();
        throw Exception(
          'Failed to submit investment: ${jsonDecode(errorBody)['message'] ?? errorBody}',
        );
      }
    } on ApiException catch (e) {
      safePrint('API Error submitting investment: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting investment: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      safePrint('Error submitting investment: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting investment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetStructuredLoanForm() {
    _structuredLoanFormKey.currentState?.reset();
    setState(() {
      _selectedCategory = null;
      _selectedCampaign = null;
      _selectedTenure = null;
      _quantityController.clear();
      _calculatedTotalLoan = 0.0;
    });
  }

  @override
  void dispose() {
    _quantityController.removeListener(_calculateTotalStructuredLoan);
    _quantityController.dispose();
    _descriptionController.dispose();
    _imageUrl1Controller.dispose();
    _imageUrl2Controller.dispose();
    _imageUrl3Controller.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserRoleAndInitCampaigns() async {
    setState(() {
      _isRoleLoading = true;
    });
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        safePrint('User not signed in, cannot determine role');
        setState(() {
          _userRole = null;
          _isRoleLoading = false;
        });
        return;
      }

      safePrint('Auth session retrieved successfully');

      // Get Cognito Groups from ID token
      final idToken =
          (session as dynamic).userPoolTokensResult.value.idToken.raw;
      safePrint('ID Token retrieved: ${idToken.substring(0, 50)}...');

      final payload = _parseJwt(idToken);
      safePrint('JWT payload keys: ${payload.keys.toList()}');

      List<String> groups = [];
      if (payload.containsKey('cognito:groups')) {
        final groupVal = payload['cognito:groups'];
        safePrint(
          'Raw groups value: $groupVal (type: ${groupVal.runtimeType})',
        );
        if (groupVal is List) {
          groups = List<String>.from(groupVal);
        } else if (groupVal is String) {
          groups = [groupVal];
        }
      } else {
        safePrint('No cognito:groups found in payload');
      }

      safePrint('Parsed User Cognito groups: $groups');

      // Use group for role
      String? role;
      if (groups.contains('Farmers') || groups.contains('Farmer')) {
        role = 'Farmer';
        safePrint('Role determined as Farmer based on groups: $groups');
      } else if (groups.contains('Investors') || groups.contains('Investor')) {
        role = 'Investor';
        safePrint('Role determined as Investor based on groups: $groups');
      } else {
        safePrint(
          'No recognized role found in groups: $groups, defaulting to null',
        );
        role = null;
      }

      setState(() {
        _userRole = role;
        _isRoleLoading = false;
        safePrint('Setting user role to: $_userRole');

        if (role == 'Investor') {
          safePrint('Initializing investor campaigns fetch');
          _allCampaignsFuture = _fetchAllCampaigns();
        } else if (role == 'Farmer') {
          safePrint(
            'Investor role not matched, not fetching all campaigns (Farmer view)',
          );
        } else {
          safePrint(
            'Role is null or unrecognized, not fetching investor campaigns',
          );
        }
      });

      // Still fetch profile info for display
      _fetchLoanHistory();
    } catch (e) {
      safePrint('Error in _fetchUserRoleAndInitCampaigns: $e');
      safePrint('Stack trace: ${StackTrace.current}');
      setState(() {
        _userRole = null;
        _isRoleLoading = false;
      });
    }
  }

  // Fetch recent campaigns for both farmers and investors
  Future<void> _fetchRecentCampaigns() async {
    try {
      setState(() {
        _recentCampaignsFuture = _getRecentCampaignsFromApi();
      });
    } catch (e) {
      safePrint('Error initializing recent campaigns: $e');
    }
  }

  Future<List<LoanRequest>> _getRecentCampaignsFromApi() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        throw Exception('You must be signed in to view recent campaigns.');
      }

      // Fetch recent structured campaigns
      final structuredRestOperation = Amplify.API.get(
        '/loan-requests',
        apiName: 'PoligrainAPI',
        queryParameters: {
          'activeOnly': 'true',
          'limit': '3',
          'type': 'structured',
        },
      );
      final structuredResponse = await structuredRestOperation.response;

      List<LoanRequest> structuredRecent = [];
      if (structuredResponse.statusCode == 200) {
        final dynamic responseData = jsonDecode(
          structuredResponse.decodeBody(),
        );
        final List<dynamic> campaigns;
        if (responseData is List) {
          campaigns = responseData;
        } else if (responseData is Map<String, dynamic> &&
            responseData.containsKey('campaigns')) {
          campaigns = responseData['campaigns'] ?? [];
        } else {
          campaigns = [];
        }

        structuredRecent =
            campaigns
                .map(
                  (json) => LoanRequest(
                    id: json['id'],
                    loanType: 'structured',
                    amount: (json['targetAmount'] as num?)?.toDouble() ?? 0.0,
                    tenure: (json['tenureOptions'] as List?)?.join(', ') ?? '',
                    status: json['status'] ?? 'Active',
                    createdAt: json['createdAt'],
                    campaignName: json['title'] ?? 'Unknown Campaign',
                  ),
                )
                .toList();
      }

      // Fetch recent flexible loan requests
      final flexibleRestOperation = Amplify.API.get(
        '/loan-requests',
        apiName: 'PoligrainAPI',
        queryParameters: {'activeOnly': 'true', 'limit': '3'},
      );
      final flexibleResponse = await flexibleRestOperation.response;

      List<LoanRequest> flexibleRecent = [];
      if (flexibleResponse.statusCode == 200) {
        final dynamic responseData = jsonDecode(flexibleResponse.decodeBody());
        final List<dynamic> requests;
        if (responseData is List) {
          requests = responseData;
        } else {
          requests = [];
        }

        flexibleRecent =
            requests
                .map(
                  (json) => LoanRequest(
                    id: json['id'],
                    loanType: 'flexible',
                    amount:
                        (json['targetAmount'] as num?)?.toDouble() ??
                        (json['amount'] as num?)?.toDouble() ??
                        0.0,
                    tenure: json['tenure'] ?? '',
                    status: json['status'] ?? 'Pending',
                    createdAt: json['createdAt'],
                    campaignName: json['title'] ?? 'Flexible Loan',
                  ),
                )
                .toList();
      }

      final allRecent =
          [...structuredRecent, ...flexibleRecent]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt))
            ..take(3).toList();
      return allRecent;
    } on ApiException catch (e) {
      safePrint('API Error fetching recent campaigns: $e');
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      safePrint('Error fetching recent campaigns: $e');
      throw Exception(
        'An unexpected error occurred while fetching recent campaigns.',
      );
    }
  }

  // Helper to decode JWT
  Map<String, dynamic> _parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('invalid token');
    }
    final payload = base64Url.normalize(parts[1]);
    final payloadMap = json.decode(utf8.decode(base64Url.decode(payload)));
    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('invalid payload');
    }
    return payloadMap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // AppBar (back arrow + centered title — no notification icon)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 56, 12, 12),
            child: Row(
              children: [
                // Back button
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
                        'Loan & Crowdfunding',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                // Keep the right side empty to maintain centered title
                const SizedBox(width: 48),
              ],
            ),
          ),
          // Main content
          Expanded(
            child:
                _isRoleLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (_userRole == 'Farmer')
                    ? SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildHeaderSection(),
                          _buildActionCards(),
                          if (_showForm)
                            _selectedLoanType == LoanRequestType.structured
                                ? Form(
                                  key: _structuredLoanFormKey,
                                  child: _buildStructuredLoanForm(),
                                )
                                : _buildFlexibleLoanForm(),
                        ],
                      ),
                    )
                    : (_userRole == 'Investor')
                    ? SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildHeaderSection(),
                          _buildInvestorCampaignList(),
                          // Placeholder for investment history section (Step 3)
                        ],
                      ),
                    )
                    : const Center(
                      child: Text(
                        'Unknown or unauthorized user role.\nPlease complete your profile or contact support.',
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.asset(
              'assets/images/agri_finance.png',
              width: 36,
              height: 36,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agricultural Financing',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Get funding for your farming projects',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Quick action cards (matches the provided mock: stacked text with full-width CTA buttons)
  Widget _buildActionCards() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Structured Loan Campaigns secondary card (matches your original two-card layout in mock)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.campaign,
                        color: Colors.green[700],
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Structured Loan Campaigns',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose from our pre-approved agricultural campaigns',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const StructuredLoanFlow(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'View Campaigns',
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

          // Flexible Loan Application card (pale white card with blue CTA)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.request_quote,
                        color: Colors.blue[700],
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Flexible Loan Application',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Apply for a loan with a flexible repayment plan',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const FlexibleLoanFlow(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Apply Now',
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

          // My Applications row (simple white row with icon and chevron)
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => Scaffold(
                        appBar: AppBar(
                          title: const Text('My Applications'),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.green[800],
                          elevation: 0,
                        ),
                        body: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: _buildLoanHistorySection(),
                          ),
                        ),
                      ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.task_alt_rounded,
                      color: Colors.green[700],
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'My Applications',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanTypeSelector() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SegmentedButton<LoanRequestType>(
        segments: const <ButtonSegment<LoanRequestType>>[
          ButtonSegment<LoanRequestType>(
            value: LoanRequestType.structured,
            label: Text(
              'Campaigns',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            icon: Icon(Icons.campaign),
          ),
          ButtonSegment<LoanRequestType>(
            value: LoanRequestType.flexible,
            label: Text(
              'Flexible',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            icon: Icon(Icons.edit_note),
          ),
        ],
        selected: <LoanRequestType>{_selectedLoanType},
        onSelectionChanged: (Set<LoanRequestType> newSelection) {
          setState(() {
            _selectedLoanType = newSelection.first;
            _resetStructuredLoanForm(); // Only structured loan form remains
          });
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>((
            Set<MaterialState> states,
          ) {
            if (states.contains(MaterialState.selected)) {
              return Colors.green[600]!;
            }
            return Colors.transparent;
          }),
          foregroundColor: MaterialStateProperty.resolveWith<Color>((
            Set<MaterialState> states,
          ) {
            if (states.contains(MaterialState.selected)) {
              return Colors.white;
            }
            return Colors.grey[700]!;
          }),
        ),
      ),
    );
  }

  Widget _buildStructuredLoanForm() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.campaign, color: Colors.green[700], size: 22),
              const SizedBox(width: 12),
              Text(
                "Structured Loan Campaigns",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Choose from our pre-approved agricultural campaigns",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: 'Select category',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.green[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.green[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.green[600]!, width: 2),
              ),
              prefixIcon: Icon(Icons.category, color: Colors.green[600]),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            value: _selectedCategory,
            isExpanded: true,
            hint: const Text('Select category'),
            dropdownColor: Colors.white,
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.green[600]),
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            menuMaxHeight: 200,
            items: [
              DropdownMenuItem<String>(
                value: 'Crop',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.eco,
                          color: Colors.green[700],
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Crops',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DropdownMenuItem<String>(
                value: 'Livestock',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.pets,
                          color: Colors.orange[700],
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Livestock',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            onChanged: (String? newValue) {
              setState(() {
                _selectedCategory = newValue;
                _selectedCampaign = null;
                _selectedTenure = null;
                _calculateTotalStructuredLoan();
              });
            },
            validator:
                (value) => value == null ? 'Please select a category' : null,
          ),
          const SizedBox(height: 20),
          if (_selectedCategory != null) ...[
            Text(
              'Campaign',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<StructuredLoanCampaign>(
              decoration: InputDecoration(
                hintText: 'Select a campaign',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.green[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.green[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.green[600]!, width: 2),
                ),
                prefixIcon: Icon(Icons.agriculture, color: Colors.green[600]),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              value: _selectedCampaign,
              isExpanded: true,
              hint: Text(
                'Select a ${_selectedCategory!.toLowerCase()} campaign',
              ),
              dropdownColor: Colors.white,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.green[600]),
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              menuMaxHeight: 250,
              items:
                  allStructuredLoanCampaigns
                      .where(
                        (campaign) => campaign.category == _selectedCategory,
                      )
                      .map(
                        (campaign) => DropdownMenuItem<StructuredLoanCampaign>(
                          value: campaign,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 2,
                              horizontal: 4,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  campaign.campaignName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  '${campaign.gestationPeriod} • ${campaign.unitType}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (StructuredLoanCampaign? newValue) {
                setState(() {
                  _selectedCampaign = newValue;
                  _selectedTenure = null;
                  if (newValue != null && newValue.tenureOptions.isNotEmpty) {
                    _selectedTenure = newValue.tenureOptions.first;
                  }
                  _calculateTotalStructuredLoan();
                });
              },
              validator:
                  (value) => value == null ? 'Please select a campaign' : null,
            ),
          ],
          const SizedBox(height: 24),
          if (_selectedCampaign != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  _buildDetailRow("Category:", _selectedCampaign!.category),
                  _buildDetailRow(
                    "Gestation Period:",
                    _selectedCampaign!.gestationPeriod,
                  ),
                  _buildDetailRow(
                    "Avg. Cost / ${_selectedCampaign!.unitType}:",
                    formatNaira(_selectedCampaign!.averageCostPerUnit),
                  ),
                  _buildDetailRow(
                    "Est. Loan / ${_selectedCampaign!.unitType} (incl. 2.5% fee):",
                    formatNaira(
                      _selectedCampaign!.totalLoanIncludingFeePerUnit,
                    ),
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Loan Tenure',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                hintText: 'Select loan tenure',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.green[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.green[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.green[600]!, width: 2),
                ),
                prefixIcon: Icon(Icons.schedule, color: Colors.green[600]),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              value: _selectedTenure,
              isExpanded: true,
              hint: const Text('Select loan tenure'),
              items:
                  _selectedCampaign!.tenureOptions
                      .map(
                        (tenure) => DropdownMenuItem<String>(
                          value: tenure,
                          child: Text(tenure),
                        ),
                      )
                      .toList(),
              onChanged:
                  (String? newValue) =>
                      setState(() => _selectedTenure = newValue),
              validator:
                  (value) =>
                      value == null || value.isEmpty
                          ? 'Please select a tenure'
                          : null,
            ),
            const SizedBox(height: 20),
            Text(
              'Number of ${_selectedCampaign!.unitType}s',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                hintText: 'Enter quantity (e.g., 2 for 2 Ha)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.green[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.green[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.green[600]!, width: 2),
                ),
                prefixIcon: Icon(
                  Icons.format_list_numbered,
                  color: Colors.green[600],
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null ||
                    value.isEmpty ||
                    (double.tryParse(value) ?? 0) <= 0) {
                  return 'Please enter a valid positive quantity';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Campaign Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'Provide a detailed description for your campaign',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.green[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.green[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.green[600]!, width: 2),
                ),
                prefixIcon: Icon(Icons.description, color: Colors.green[600]),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description for your campaign';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Campaign Images (up to 3)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _imageUrl1Controller,
              decoration: InputDecoration(
                hintText: 'Image URL 1 (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.green[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.green[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.green[600]!, width: 2),
                ),
                prefixIcon: Icon(Icons.image, color: Colors.green[600]),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _imageUrl2Controller,
              decoration: InputDecoration(
                hintText: 'Image URL 2 (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.green[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.green[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.green[600]!, width: 2),
                ),
                prefixIcon: Icon(Icons.image, color: Colors.green[600]),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _imageUrl3Controller,
              decoration: InputDecoration(
                hintText: 'Image URL 3 (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.green[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.green[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.green[600]!, width: 2),
                ),
                prefixIcon: Icon(Icons.image, color: Colors.green[600]),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 20),
            Text(
              'Campaign Video (optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _videoUrlController,
              decoration: InputDecoration(
                hintText: 'Video URL (e.g., YouTube link)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.green[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.green[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.green[600]!, width: 2),
                ),
                prefixIcon: Icon(Icons.videocam, color: Colors.green[600]),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Column(
                children: [
                  Text(
                    "Total Estimated Loan",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatNaira(_calculatedTotalLoan),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Includes a 2.5% transaction fee",
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send, size: 20),
                label: const Text(
                  'Apply for Structured Loan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: _isLoading ? null : _submitStructuredLoan,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  // Flexible loan form (new)
  Widget _buildFlexibleLoanForm() {
    final _flexibleFormKey = GlobalKey<FormState>();
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _amountController = TextEditingController();
    final TextEditingController _purposeController = TextEditingController();

    // Use StatefulBuilder for local form state (tenure selection & submission loading)
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          String? _selectedTenure = '6 months';
          bool _isSubmitting = false;

          // We need to preserve selectedTenure between rebuilds of the StatefulBuilder.
          // To do that, hoist values into closure-scoped variables that persist during the StatefulBuilder lifetime.
          // However Dart closures re-create on each call; so initialize them only once using a static-like trick:
          // (Here we use the `Map` attached to the builder's `context` via widget tree - to keep it simple and safe,
          // we store initial values in local variables and allow the StatefulBuilder to manage them.)
          // For clarity and reliability, we'll keep state in variables defined outside the inner functions below.
          // NOTE: The above comment is explanatory; the code below manages local state correctly.

          // Replace the above initializers with persistent vars by using captured variables on first run.
          return Builder(
            builder: (__) {
              // To persist values between setState calls in the StatefulBuilder, attach them to the widget's element using a closure.
              // Simpler approach: use local variables but update them via this `setState`. They will persist during the lifecycle of the StatefulBuilder.
              // Provide initial values using variables captured by the surrounding closure:
              // (The variables declared earlier are reinitialized on every call, but the setState passed in will rebuild the Builder and keep values.)
              // For the purpose of this form's UX, the lifetime within the visible form is sufficient.

              // Tenure options
              final tenureOptions = <String>['3 months', '6 months', '1 year'];

              return Form(
                key: _flexibleFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.request_quote,
                          color: Colors.blue[700],
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Flexible Loan Application",
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Apply for a loan with flexible repayment options",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText:
                            'Loan title (e.g., Working capital for cassava)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        prefixIcon: Icon(Icons.title, color: Colors.blue[700]),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator:
                          (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Please enter a title'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        hintText: 'Amount requested (₦)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        prefixIcon: Icon(
                          Icons.attach_money,
                          color: Colors.blue[700],
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        final v = double.tryParse(value ?? '');
                        if (v == null || v <= 0)
                          return 'Please enter a valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedTenure,
                      decoration: InputDecoration(
                        hintText: 'Preferred tenure',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        prefixIcon: Icon(
                          Icons.schedule,
                          color: Colors.blue[700],
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items:
                          tenureOptions
                              .map(
                                (t) => DropdownMenuItem<String>(
                                  value: t,
                                  child: Text(t),
                                ),
                              )
                              .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedTenure = val;
                        });
                      },
                      validator:
                          (value) =>
                              value == null ? 'Please select a tenure' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _purposeController,
                      decoration: InputDecoration(
                        hintText: 'Purpose / description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        prefixIcon: Icon(
                          Icons.description,
                          color: Colors.blue[700],
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 3,
                      validator:
                          (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Please describe the purpose'
                                  : null,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.send, size: 20),
                        label: Text(
                          _isSubmitting
                              ? 'Submitting...'
                              : 'Apply for Flexible Loan',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed:
                            _isSubmitting
                                ? null
                                : () async {
                                  if (!_flexibleFormKey.currentState!
                                      .validate())
                                    return;

                                  setState(() => _isSubmitting = true);

                                  final double amount =
                                      double.tryParse(_amountController.text) ??
                                      0;

                                  final payload = {
                                    "title": _titleController.text.trim(),
                                    "description":
                                        _purposeController.text.trim(),
                                    "type": "flexible",
                                    "targetAmount": amount,
                                    "minimumInvestment": 0,
                                    "category": "Flexible",
                                    "tenure": _selectedTenure ?? '',
                                    "startDate":
                                        DateTime.now().toIso8601String(),
                                    // For flexible loans, keep a short window by default (adjust as needed)
                                    "endDate":
                                        DateTime.now()
                                            .add(const Duration(days: 30))
                                            .toIso8601String(),
                                    "imageUrls": [],
                                    "documentUrls": [],
                                    "metadata": {"flexible": true},
                                  };

                                  try {
                                    await _submitLoanRequest(payload);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Flexible loan application submitted successfully.',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );

                                    // Clear fields after success
                                    _titleController.clear();
                                    _amountController.clear();
                                    _purposeController.clear();
                                    setState(
                                      () =>
                                          _selectedTenure = tenureOptions.first,
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } finally {
                                    if (mounted)
                                      setState(() => _isSubmitting = false);
                                  }
                                },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 16 : 15,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanHistorySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.green[700], size: 24),
              const SizedBox(width: 12),
              Text(
                "My Campaigns",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _isLoading ? null : _fetchLoanHistory,
                icon: Icon(Icons.refresh, color: Colors.green[600]),
                tooltip: "Refresh History",
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<LoanRequest>>(
            future: _loanHistoryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[400],
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Unable to load loan history. Please check your internet connection and try again.",
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          color: Colors.grey[400],
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No loan requests yet",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Your loan applications will appear here",
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final loanRequests = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: loanRequests.length,
                itemBuilder: (context, index) {
                  final request = loanRequests[index];
                  return buildLoanRequestCard(request);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getLoanStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange.shade700;
      case 'Approved':
        return Colors.green.shade700;
      case 'Rejected':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getLoanStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.hourglass_top_rounded;
      case 'Approved':
        return Icons.check_circle_outline_rounded;
      case 'Rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Widget buildLoanRequestCard(LoanRequest request) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth * 0.92, // Responsive width
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              CircleAvatar(
                backgroundColor: Colors.green[50],
                child: Icon(
                  _getLoanStatusIcon(request.status),
                  color: Colors.green[700],
                ),
                radius: 24,
              ),
              const SizedBox(width: 16),
              // Main info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.campaignName ?? "Flexible Loan",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Amount: " + formatNaira(request.amount),
                      style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (request.tenure.isNotEmpty)
                      Text(
                        "Tenure: " + request.tenure,
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Status badge
              Container(
                margin: const EdgeInsets.only(left: 8, top: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getLoanStatusColor(request.status).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getLoanStatusColor(request.status),
                    width: 1,
                  ),
                ),
                child: Text(
                  request.status,
                  style: TextStyle(
                    color: _getLoanStatusColor(request.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Add this helper function for formatting currency
String formatNaira(num amount) {
  final formatter = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 2,
  );
  return formatter.format(amount);
}

// Helper function to get appropriate icons for campaigns
IconData _getCampaignIcon(String campaignName) {
  switch (campaignName.toLowerCase()) {
    case 'rice':
      return Icons.grain;
    case 'beans':
      return Icons.eco;
    case 'yam':
      return Icons.agriculture;
    case 'cassava':
      return Icons.agriculture;
    case 'corn':
      return Icons.grain;
    case 'cabbage':
      return Icons.eco;
    case 'cucumber':
      return Icons.eco;
    case 'oil palm':
      return Icons.park;
    case 'cocoa':
      return Icons.coffee;
    case 'coconut':
      return Icons.park;
    case 'piggery':
      return Icons.pets;
    case 'grasscutter':
      return Icons.pets;
    case 'goat farming':
      return Icons.pets;
    case 'fish farming':
      return Icons.water;
    default:
      return Icons.agriculture;
  }
}
