import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../models/investment.dart';
import '../models/campaign.dart';
import '../exceptions/investment_exceptions.dart';

/// Service for managing investments and investment operations
class InvestmentService {
  static const String _apiName = 'PoligrainAPI';

  /// Process a new investment
  Future<Investment> processInvestment({
    required String campaignId,
    required double amount,
    required String tenure,
    required String paymentReference,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final requestBody = {
        'campaignId': campaignId,
        'amount': amount,
        'tenure': tenure,
        'paymentReference': paymentReference,
        if (metadata != null) 'metadata': metadata,
      };

      final response =
          await Amplify.API
              .post(
                '/investments',
                apiName: _apiName,
                body: HttpPayload.json(requestBody),
              )
              .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode == 402) {
        throw InsufficientFundsException('Insufficient funds for investment');
      }

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw InvestmentCreationException(
          'Failed to process investment: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
          details: errorBody,
        );
      }

      final investmentData = json.decode(responseBody) as Map<String, dynamic>;
      return Investment.fromJson(investmentData);
    } catch (e) {
      if (e is InvestmentException) {
        rethrow;
      }
      throw InvestmentProcessingException('Failed to process investment: $e');
    }
  }

  /// Get investment status by ID
  Future<Investment> getInvestmentStatus(String investmentId) async {
    try {
      final response =
          await Amplify.API
              .get('/investments/$investmentId', apiName: _apiName)
              .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode == 404) {
        throw InvestmentNotFoundException(
          'Investment not found: $investmentId',
        );
      }

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw InvestmentFetchException(
          'Failed to fetch investment: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
        );
      }

      final investmentData = json.decode(responseBody) as Map<String, dynamic>;
      return Investment.fromJson(investmentData);
    } catch (e) {
      if (e is InvestmentException) {
        rethrow;
      }
      throw InvestmentFetchException('Failed to fetch investment status: $e');
    }
  }

  /// Get investment history with pagination and filters
  Future<InvestmentHistoryResult> getInvestmentHistory({
    int limit = 20,
    String? lastKey,
    InvestmentStatus? status,
    String? campaignId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (lastKey != null) 'lastKey': lastKey,
        if (status != null) 'status': status.value,
        if (campaignId != null) 'campaignId': campaignId,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      final response =
          await Amplify.API
              .get(
                '/investments',
                apiName: _apiName,
                queryParameters: queryParams,
              )
              .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw InvestmentFetchException(
          'Failed to fetch investment history: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
        );
      }

      final responseData = json.decode(responseBody) as Map<String, dynamic>;
      final investments =
          (responseData['investments'] as List<dynamic>)
              .map(
                (investmentData) =>
                    Investment.fromJson(investmentData as Map<String, dynamic>),
              )
              .toList();

      final pagination = responseData['pagination'] as Map<String, dynamic>;

      return InvestmentHistoryResult(
        investments: investments,
        hasMore: pagination['hasMore'] as bool,
        nextPageKey: pagination['lastKey'] as String?,
      );
    } catch (e) {
      if (e is InvestmentException) {
        rethrow;
      }
      throw InvestmentFetchException('Failed to fetch investment history: $e');
    }
  }

  /// Update investment status (admin function)
  Future<Investment> updateInvestmentStatus({
    required String investmentId,
    required InvestmentStatus status,
    double? actualReturn,
    DateTime? actualMaturityDate,
    String? notes,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'status': status.value,
        if (actualReturn != null) 'actualReturn': actualReturn,
        if (actualMaturityDate != null)
          'actualMaturityDate': actualMaturityDate.toIso8601String(),
        if (notes != null) 'notes': notes,
      };

      final response =
          await Amplify.API
              .put(
                '/investments/$investmentId/status',
                apiName: _apiName,
                body: HttpPayload.json(requestBody),
              )
              .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode == 404) {
        throw InvestmentNotFoundException(
          'Investment not found: $investmentId',
        );
      }

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw InvestmentUpdateException(
          'Failed to update investment status: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
        );
      }

      final investmentData = json.decode(responseBody) as Map<String, dynamic>;
      return Investment.fromJson(investmentData);
    } catch (e) {
      if (e is InvestmentException) {
        rethrow;
      }
      throw InvestmentUpdateException('Failed to update investment status: $e');
    }
  }

  /// Get user's active investments
  Future<List<Investment>> getActiveInvestments() async {
    try {
      final result = await getInvestmentHistory(
        status: InvestmentStatus.active,
        limit: 100,
      );
      return result.investments;
    } catch (e) {
      throw InvestmentFetchException('Failed to fetch active investments: $e');
    }
  }

  /// Get completed investments
  Future<List<Investment>> getCompletedInvestments() async {
    try {
      final result = await getInvestmentHistory(
        status: InvestmentStatus.completed,
        limit: 100,
      );
      return result.investments;
    } catch (e) {
      throw InvestmentFetchException(
        'Failed to fetch completed investments: $e',
      );
    }
  }

  /// Get investments by campaign
  Future<List<Investment>> getInvestmentsByCampaign(String campaignId) async {
    try {
      final result = await getInvestmentHistory(
        campaignId: campaignId,
        limit: 100,
      );
      return result.investments;
    } catch (e) {
      throw InvestmentFetchException(
        'Failed to fetch campaign investments: $e',
      );
    }
  }

  /// Calculate expected return based on campaign and tenure
  Future<double> calculateExpectedReturn({
    required String campaignId,
    required double amount,
    required String tenure,
  }) async {
    try {
      final response =
          await Amplify.API
              .post(
                '/investments/calculate-return',
                apiName: _apiName,
                body: HttpPayload.json({
                  'campaignId': campaignId,
                  'amount': amount,
                  'tenure': tenure,
                }),
              )
              .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw InvestmentProcessingException(
          'Failed to calculate return: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
        );
      }

      final responseData = json.decode(responseBody) as Map<String, dynamic>;
      return (responseData['expectedReturn'] as num).toDouble();
    } catch (e) {
      if (e is InvestmentException) {
        rethrow;
      }
      throw InvestmentProcessingException(
        'Failed to calculate expected return: $e',
      );
    }
  }

  /// Validate investment data
  void validateInvestmentData({
    required Campaign campaign,
    required double amount,
    required String tenure,
  }) {
    if (!campaign.isActiveForInvestment) {
      throw InvestmentValidationException(
        'Campaign is not available for investment',
      );
    }

    if (amount < campaign.minimumInvestment) {
      throw InvestmentValidationException(
        'Investment amount must be at least ${campaign.minimumInvestment}',
      );
    }

    if (amount > campaign.remainingAmount) {
      throw InvestmentValidationException(
        'Investment amount exceeds remaining funding needed',
      );
    }

    if (campaign.tenureOptions?.contains(tenure) != true) {
      throw InvestmentValidationException('Invalid tenure option selected');
    }
  }

  /// Get investment summary/dashboard data
  Future<InvestmentSummary> getInvestmentSummary() async {
    try {
      final response =
          await Amplify.API
              .get('/investments/summary', apiName: _apiName)
              .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw InvestmentFetchException(
          'Failed to fetch investment summary: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
        );
      }

      final summaryData = json.decode(responseBody) as Map<String, dynamic>;
      return InvestmentSummary.fromJson(summaryData);
    } catch (e) {
      if (e is InvestmentException) {
        rethrow;
      }
      throw InvestmentFetchException('Failed to fetch investment summary: $e');
    }
  }
}

/// Result object for investment history pagination
class InvestmentHistoryResult {
  final List<Investment> investments;
  final bool hasMore;
  final String? nextPageKey;

  const InvestmentHistoryResult({
    required this.investments,
    required this.hasMore,
    this.nextPageKey,
  });

  /// Check if there are more investments to load
  bool get canLoadMore => hasMore && nextPageKey != null;

  /// Get total number of investments in current page
  int get count => investments.length;

  /// Get total investment amount for current page
  double get totalInvestmentAmount {
    return investments.fold(0.0, (sum, investment) => sum + investment.amount);
  }

  /// Get total expected returns for current page
  double get totalExpectedReturns {
    return investments.fold(
      0.0,
      (sum, investment) => sum + investment.expectedReturn,
    );
  }

  /// Get active investments count
  int get activeInvestmentsCount {
    return investments.where((i) => i.isActive).length;
  }
}

/// Investment summary for dashboard
class InvestmentSummary {
  final double totalInvested;
  final double totalReturns;
  final double expectedReturns;
  final int activeInvestments;
  final int completedInvestments;
  final double averageROI;

  const InvestmentSummary({
    required this.totalInvested,
    required this.totalReturns,
    required this.expectedReturns,
    required this.activeInvestments,
    required this.completedInvestments,
    required this.averageROI,
  });

  /// Create InvestmentSummary from JSON
  factory InvestmentSummary.fromJson(Map<String, dynamic> json) {
    return InvestmentSummary(
      totalInvested: (json['totalInvested'] as num?)?.toDouble() ?? 0.0,
      totalReturns: (json['totalReturns'] as num?)?.toDouble() ?? 0.0,
      expectedReturns: (json['expectedReturns'] as num?)?.toDouble() ?? 0.0,
      activeInvestments: json['activeInvestments'] as int? ?? 0,
      completedInvestments: json['completedInvestments'] as int? ?? 0,
      averageROI: (json['averageROI'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convert InvestmentSummary to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalInvested': totalInvested,
      'totalReturns': totalReturns,
      'expectedReturns': expectedReturns,
      'activeInvestments': activeInvestments,
      'completedInvestments': completedInvestments,
      'averageROI': averageROI,
    };
  }
}
