import 'dart:math' as math;
import 'package:poligrain_app/models/campaign.dart';
import 'package:poligrain_app/models/campaign_enum.dart';

class InvestmentCalculator {
  // Default return rates for different campaign types
  static const Map<String, Map<String, double>> _defaultReturnRates = {
    'loan': {
      '3 months': 2.5,
      '6 months': 5.0,
      '9 months': 7.5,
      '1 year': 10.0,
      '2 years': 20.0,
      '3 years': 30.0,
    },
    'investment': {
      '3 months': 3.0,
      '6 months': 6.0,
      '9 months': 9.0,
      '1 year': 12.0,
      '2 years': 25.0,
      '3 years': 38.0,
    },
    'crowdfunding': {
      '3 months': 1.5,
      '6 months': 3.0,
      '9 months': 4.5,
      '1 year': 6.0,
      '2 years': 12.0,
      '3 years': 18.0,
    },
  };

  static Map<String, dynamic> calculatePotentialReturn(
    double investmentAmount,
    Campaign campaign,
    String tenure,
  ) {
    try {
      if (investmentAmount <= 0) {
        throw ArgumentError('Investment amount must be positive');
      }

      double returnPercentage = _getReturnRate(campaign, tenure);
      double tenureInYears = _convertTenureToYears(tenure);

      // Calculate compound interest for multi-year investments
      double totalReturn =
          investmentAmount *
          math.pow(1 + (returnPercentage / 100), tenureInYears);
      double expectedProfit = totalReturn - investmentAmount;
      double annualReturnRate = returnPercentage / 100;

      // Calculate monthly returns for progress tracking
      List<Map<String, dynamic>> monthlyReturns = _calculateMonthlyReturns(
        investmentAmount,
        annualReturnRate,
        tenureInYears,
      );

      return {
        'totalReturn': totalReturn,
        'expectedProfit': expectedProfit,
        'returnPercentage': returnPercentage,
        'annualReturnRate': annualReturnRate,
        'tenureInYears': tenureInYears,
        'monthlyReturns': monthlyReturns,
        'projectedROI': (expectedProfit / investmentAmount) * 100,
        'monthlyROI': returnPercentage / (tenureInYears * 12),
        'breakEvenMonth': _calculateBreakEvenMonth(
          investmentAmount,
          annualReturnRate,
        ),
        'riskAdjustedReturn': _calculateRiskAdjustedReturn(
          expectedProfit,
          campaign,
        ),
      };
    } catch (e) {
      // Return safe defaults on error
      return {
        'totalReturn': investmentAmount,
        'expectedProfit': 0.0,
        'returnPercentage': 0.0,
        'annualReturnRate': 0.0,
        'tenureInYears': 1.0,
        'monthlyReturns': <Map<String, dynamic>>[],
        'projectedROI': 0.0,
        'monthlyROI': 0.0,
        'breakEvenMonth': 12,
        'riskAdjustedReturn': 0.0,
        'error': e.toString(),
      };
    }
  }

  static double _getReturnRate(Campaign campaign, String tenure) {
    // Try to get return rate from campaign metadata first
    if (campaign.metadata.containsKey('returnRates')) {
      final returnRates =
          campaign.metadata['returnRates'] as Map<String, dynamic>?;
      if (returnRates != null && returnRates.containsKey(tenure)) {
        return (returnRates[tenure] as num).toDouble();
      }
    }

    // Fall back to default rates based on campaign type
    final campaignType = campaign.type.toLowerCase();
    if (_defaultReturnRates.containsKey(campaignType)) {
      final typeRates = _defaultReturnRates[campaignType]!;
      return typeRates[tenure] ?? typeRates['1 year'] ?? 10.0;
    }

    // Final fallback
    return 10.0;
  }

  static List<Map<String, dynamic>> _calculateMonthlyReturns(
    double principal,
    double annualRate,
    double years,
  ) {
    List<Map<String, dynamic>> returns = [];
    int totalMonths = (years * 12).round();
    double monthlyRate = annualRate / 12;

    for (int month = 1; month <= totalMonths; month++) {
      double amount = principal * math.pow(1 + monthlyRate, month);
      double interest = amount - principal;
      double monthlyGain =
          month == 1
              ? interest
              : (amount - returns[month - 2]['amount'] as double);

      returns.add({
        'month': month,
        'amount': amount,
        'interest': interest,
        'monthlyGain': monthlyGain,
        'roi': (interest / principal) * 100,
      });
    }

    return returns;
  }

  static int _calculateBreakEvenMonth(double principal, double annualRate) {
    if (annualRate <= 0) return 12;
    double monthlyRate = annualRate / 12;
    // Time to recover initial investment
    return (math.log(2) / math.log(1 + monthlyRate)).ceil();
  }

  static double _calculateRiskAdjustedReturn(
    double expectedReturn,
    Campaign campaign,
  ) {
    double riskMultiplier = _getRiskMultiplier(campaign);
    return expectedReturn * riskMultiplier;
  }

  static double _getRiskMultiplier(Campaign campaign) {
    String riskLevel = _calculateRiskLevel(campaign);
    switch (riskLevel) {
      case 'Low':
        return 0.95; // Slightly lower returns for lower risk
      case 'High':
        return 1.05; // Slightly higher potential for high risk
      default:
        return 1.0; // Medium risk baseline
    }
  }

  static double calculateFundingProgress(Campaign campaign) {
    if (campaign.targetAmount <= 0) {
      return 0.0;
    }
    double progress = (campaign.totalRaised / campaign.targetAmount) * 100;
    return progress.clamp(0.0, 100.0);
  }

  static String calculateFundingMomentum(Campaign campaign) {
    try {
      int totalDays = campaign.endDate.difference(campaign.startDate).inDays;
      int daysSinceStart = DateTime.now().difference(campaign.startDate).inDays;

      if (daysSinceStart <= 0 || totalDays <= 0) return 'Stable';

      double timeProgress = daysSinceStart / totalDays;
      double fundingProgress = calculateFundingProgress(campaign) / 100;

      if (fundingProgress > timeProgress * 1.3) return 'Accelerating';
      if (fundingProgress > timeProgress * 1.1) return 'Strong';
      if (fundingProgress < timeProgress * 0.7) return 'Slowing';
      if (fundingProgress < timeProgress * 0.5) return 'Critical';
      return 'Stable';
    } catch (e) {
      return 'Stable';
    }
  }

  static Map<String, dynamic> calculateFundingAnalytics(Campaign campaign) {
    double progress = calculateFundingProgress(campaign);
    String momentum = calculateFundingMomentum(campaign);
    int daysRemaining = getDaysRemaining(campaign);

    double dailyFundingRate = 0.0;
    if (campaign.startDate.isBefore(DateTime.now())) {
      int daysSinceStart = DateTime.now().difference(campaign.startDate).inDays;
      if (daysSinceStart > 0) {
        dailyFundingRate = campaign.totalRaised / daysSinceStart;
      }
    }

    double projectedFinalAmount =
        campaign.totalRaised + (dailyFundingRate * daysRemaining);
    double projectedProgress =
        projectedFinalAmount / campaign.targetAmount * 100;

    return {
      'currentProgress': progress,
      'momentum': momentum,
      'daysRemaining': daysRemaining,
      'dailyFundingRate': dailyFundingRate,
      'projectedFinalAmount': projectedFinalAmount,
      'projectedProgress': projectedProgress.clamp(0.0, 100.0),
      'isOnTrack': projectedProgress >= 95.0,
      'fundingVelocity': _calculateFundingVelocity(campaign),
    };
  }

  static double _calculateFundingVelocity(Campaign campaign) {
    // Calculate funding velocity as percentage of target per day
    int daysSinceStart = DateTime.now().difference(campaign.startDate).inDays;
    if (daysSinceStart <= 0) return 0.0;

    double dailyPercentage =
        (campaign.totalRaised / campaign.targetAmount) / daysSinceStart * 100;
    return dailyPercentage;
  }

  static Map<String, dynamic> calculateInvestmentScore(Campaign campaign) {
    try {
      // Progress Score (0-100)
      double progressScore = calculateFundingProgress(campaign);

      // Time Score (0-100) - based on how much time has passed vs remaining
      int totalDuration =
          campaign.endDate.difference(campaign.startDate).inDays;
      int daysRemaining = getDaysRemaining(campaign);
      double timeScore =
          totalDuration > 0
              ? ((totalDuration - daysRemaining) / totalDuration * 100).clamp(
                0.0,
                100.0,
              )
              : 0.0;

      // ROI Score (0-100) - based on potential returns
      double roiScore = _calculateROIScore(campaign);

      // Risk Level Assessment
      String riskLevel = _calculateRiskLevel(campaign);
      double riskAdjustment = _getRiskAdjustmentFactor(riskLevel);

      // Market Score (0-100) - based on category and market conditions
      double marketScore = _calculateMarketScore(campaign);

      // Liquidity Score (0-100) - how quickly investment can be liquidated
      double liquidityScore = _calculateLiquidityScore(campaign);

      // Weighted overall score
      double overallScore =
          (progressScore * 0.25 + // 25% weight on current progress
              timeScore * 0.15 + // 15% weight on timing
              roiScore * 0.30 + // 30% weight on returns
              marketScore * 0.20 + // 20% weight on market conditions
              liquidityScore *
                  0.10 // 10% weight on liquidity
                  ) *
          riskAdjustment;

      return {
        'overallScore': overallScore.clamp(0.0, 100.0),
        'progressScore': progressScore,
        'timeScore': timeScore,
        'roiScore': roiScore,
        'marketScore': marketScore,
        'liquidityScore': liquidityScore,
        'riskLevel': riskLevel,
        'riskAdjustment': riskAdjustment,
        'recommendation': _getInvestmentRecommendation(overallScore),
        'confidenceLevel': _calculateConfidenceLevel(overallScore, riskLevel),
        'keyStrengths': _identifyKeyStrengths(campaign, overallScore),
        'keyRisks': _identifyKeyRisks(campaign, riskLevel),
      };
    } catch (e) {
      return {
        'overallScore': 50.0,
        'progressScore': 0.0,
        'timeScore': 0.0,
        'roiScore': 0.0,
        'marketScore': 50.0,
        'liquidityScore': 50.0,
        'riskLevel': 'Medium',
        'riskAdjustment': 1.0,
        'recommendation': 'Consider',
        'confidenceLevel': 'Low',
        'keyStrengths': <String>[],
        'keyRisks': ['Insufficient data for analysis'],
        'error': e.toString(),
      };
    }
  }

  static double _calculateROIScore(Campaign campaign) {
    // Base score on campaign type and expected returns
    String campaignType = campaign.type.toLowerCase();
    Map<String, double> baseScores = {
      'investment': 85.0,
      'loan': 70.0,
      'crowdfunding': 60.0,
    };

    double baseScore = baseScores[campaignType] ?? 70.0;

    // Adjust based on minimum investment accessibility
    if (campaign.minimumInvestment <= 50000) {
      // ₦50,000
      baseScore += 10.0;
    } else if (campaign.minimumInvestment <= 100000) {
      // ₦100,000
      baseScore += 5.0;
    }

    return baseScore.clamp(0.0, 100.0);
  }

  static double _calculateMarketScore(Campaign campaign) {
    // Score based on category popularity and market conditions
    Map<String, double> categoryScores = {
      'Crop': 85.0,
      'Livestock': 80.0,
      'Poultry': 75.0,
      'Aquaculture': 70.0,
      'Horticulture': 78.0,
      'Agro-processing': 82.0,
      'Farm Equipment': 65.0,
    };

    double score = categoryScores[campaign.category] ?? 70.0;

    // Adjust based on funding progress (market validation)
    double progress = calculateFundingProgress(campaign);
    if (progress > 80)
      score += 15.0;
    else if (progress > 60)
      score += 10.0;
    else if (progress > 40)
      score += 5.0;
    else if (progress < 20)
      score -= 10.0;

    return score.clamp(0.0, 100.0);
  }

  static double _calculateLiquidityScore(Campaign campaign) {
    // Score based on how quickly the investment can be liquidated
    String campaignType = campaign.type.toLowerCase();

    if (campaignType == 'loan') {
      return 85.0; // Loans typically have fixed terms and clear exit
    } else if (campaignType == 'investment') {
      return 60.0; // Investments may have longer lock-up periods
    } else {
      return 40.0; // Crowdfunding typically least liquid
    }
  }

  static String _calculateRiskLevel(Campaign campaign) {
    int riskScore = 0;

    // Category risk
    Map<String, int> categoryRisk = {
      'Crop': 3, // Weather dependent
      'Livestock': 4, // Disease risk
      'Poultry': 4, // Disease risk
      'Aquaculture': 5, // Environmental risk
      'Horticulture': 3, // Moderate risk
      'Agro-processing': 2, // More stable
      'Farm Equipment': 1, // Lowest risk
    };

    riskScore += categoryRisk[campaign.category] ?? 3;

    // Funding progress risk
    double progress = calculateFundingProgress(campaign);
    if (progress < 20)
      riskScore += 2;
    else if (progress < 50)
      riskScore += 1;
    else if (progress > 90)
      riskScore -= 1;

    // Time remaining risk
    int daysRemaining = getDaysRemaining(campaign);
    if (daysRemaining < 30)
      riskScore += 2;
    else if (daysRemaining < 90)
      riskScore += 1;

    // Amount size risk
    if (campaign.targetAmount > 10000000) riskScore += 1; // Large campaigns
    if (campaign.minimumInvestment > 500000) riskScore += 1; // High barriers

    // Determine risk level
    if (riskScore <= 3) return 'Low';
    if (riskScore >= 7) return 'High';
    return 'Medium';
  }

  static double _getRiskAdjustmentFactor(String riskLevel) {
    switch (riskLevel) {
      case 'Low':
        return 1.05; // Slight bonus for lower risk
      case 'High':
        return 0.90; // Penalty for higher risk
      default:
        return 1.0; // Medium risk baseline
    }
  }

  static String _getInvestmentRecommendation(double score) {
    if (score >= 85) return 'Highly Recommended';
    if (score >= 70) return 'Recommended';
    if (score >= 55) return 'Consider';
    if (score >= 40) return 'Caution Advised';
    return 'Not Recommended';
  }

  static String _calculateConfidenceLevel(double score, String riskLevel) {
    if (score >= 80 && riskLevel == 'Low') return 'Very High';
    if (score >= 70 && riskLevel != 'High') return 'High';
    if (score >= 60) return 'Medium';
    if (score >= 40) return 'Low';
    return 'Very Low';
  }

  static List<String> _identifyKeyStrengths(Campaign campaign, double score) {
    List<String> strengths = [];

    double progress = calculateFundingProgress(campaign);
    if (progress > 75) strengths.add('Strong investor interest');
    if (progress > 50 && getDaysRemaining(campaign) > 60) {
      strengths.add('Good funding momentum with time remaining');
    }

    if (campaign.investorCount > 20) {
      strengths.add('Diverse investor base');
    }

    if (campaign.minimumInvestment <= 100000) {
      strengths.add('Accessible investment amount');
    }

    if ([
      'Crop',
      'Agro-processing',
      'Horticulture',
    ].contains(campaign.category)) {
      strengths.add('Strong market sector');
    }

    if (score > 80) {
      strengths.add('Excellent overall investment metrics');
    }

    return strengths;
  }

  static List<String> _identifyKeyRisks(Campaign campaign, String riskLevel) {
    List<String> risks = [];

    if (riskLevel == 'High') {
      risks.add('High risk investment category');
    }

    double progress = calculateFundingProgress(campaign);
    if (progress < 30) {
      risks.add('Low funding progress may indicate market skepticism');
    }

    int daysRemaining = getDaysRemaining(campaign);
    if (daysRemaining < 30 && progress < 80) {
      risks.add('Limited time to reach funding target');
    }

    if (campaign.investorCount < 5) {
      risks.add('Limited investor interest to date');
    }

    if (campaign.targetAmount > 5000000) {
      risks.add('Large funding requirement');
    }

    if (['Aquaculture', 'Livestock'].contains(campaign.category)) {
      risks.add('Weather and disease risk exposure');
    }

    return risks;
  }

  static int getDaysRemaining(Campaign campaign) {
    final now = DateTime.now();
    if (now.isAfter(campaign.endDate)) return 0;
    return campaign.endDate.difference(now).inDays;
  }

  static double _convertTenureToYears(String tenure) {
    final parts = tenure.toLowerCase().split(' ');
    if (parts.length != 2) return 1.0;

    final num = double.tryParse(parts[0]) ?? 1.0;
    if (parts[1].startsWith('year')) {
      return num;
    }
    if (parts[1].startsWith('month')) {
      return num / 12.0;
    }
    return 1.0;
  }

  // Portfolio optimization methods
  static Map<String, dynamic> calculateOptimalAllocation(
    double totalAmount,
    List<Campaign> availableCampaigns,
    String riskTolerance, {
    Map<String, double>? categoryLimits,
    int? maxCampaigns,
  }) {
    if (availableCampaigns.isEmpty || totalAmount <= 0) {
      return {
        'allocations': <Map<String, dynamic>>[],
        'totalAllocated': 0.0,
        'expectedReturn': 0.0,
        'riskScore': 0.0,
        'message': 'No campaigns available or invalid amount',
      };
    }

    // Filter campaigns by risk tolerance
    List<Campaign> suitableCampaigns =
        availableCampaigns.where((campaign) {
          String campaignRisk = _calculateRiskLevel(campaign);
          return _isRiskToleranceMatch(riskTolerance, campaignRisk);
        }).toList();

    if (suitableCampaigns.isEmpty) {
      return {
        'allocations': <Map<String, dynamic>>[],
        'totalAllocated': 0.0,
        'expectedReturn': 0.0,
        'riskScore': 0.0,
        'message':
            'No suitable campaigns found for risk tolerance: $riskTolerance',
      };
    }

    // Score and sort campaigns
    List<Map<String, dynamic>> scoredCampaigns =
        suitableCampaigns.map((campaign) {
          var score = calculateInvestmentScore(campaign);
          return {
            'campaign': campaign,
            'score': score['overallScore'],
            'riskLevel': score['riskLevel'],
          };
        }).toList();

    scoredCampaigns.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );

    // Apply allocation strategy
    return _allocateFunds(
      totalAmount,
      scoredCampaigns,
      categoryLimits,
      maxCampaigns,
    );
  }

  static bool _isRiskToleranceMatch(String tolerance, String campaignRisk) {
    switch (tolerance.toLowerCase()) {
      case 'low':
        return campaignRisk == 'Low';
      case 'medium':
        return campaignRisk == 'Low' || campaignRisk == 'Medium';
      case 'high':
        return true; // Accept all risk levels
      default:
        return campaignRisk == 'Medium';
    }
  }

  static Map<String, dynamic> _allocateFunds(
    double totalAmount,
    List<Map<String, dynamic>> scoredCampaigns,
    Map<String, double>? categoryLimits,
    int? maxCampaigns,
  ) {
    int maxAllowedCampaigns =
        maxCampaigns ?? math.min(5, scoredCampaigns.length);
    List<Map<String, dynamic>> allocations = [];
    double totalAllocated = 0.0;
    Map<String, double> categoryAllocated = {};

    for (
      int i = 0;
      i < math.min(maxAllowedCampaigns, scoredCampaigns.length);
      i++
    ) {
      var campaignData = scoredCampaigns[i];
      Campaign campaign = campaignData['campaign'];

      // Check category limits if specified
      if (categoryLimits != null &&
          categoryLimits.containsKey(campaign.category)) {
        double categoryLimit = categoryLimits[campaign.category]! * totalAmount;
        double currentCategoryAllocation =
            categoryAllocated[campaign.category] ?? 0.0;
        if (currentCategoryAllocation >= categoryLimit) continue;
      }

      double remainingAmount = totalAmount - totalAllocated;
      if (remainingAmount < campaign.minimumInvestment) continue;

      // Calculate allocation amount
      double baseAllocation = totalAmount / maxAllowedCampaigns;
      double scoreWeight = (campaignData['score'] as double) / 100.0;
      double allocation = baseAllocation * (0.7 + 0.3 * scoreWeight);

      // Ensure minimum investment and don't exceed remaining
      allocation = math.max(allocation, campaign.minimumInvestment);
      allocation = math.min(allocation, remainingAmount);

      // Check category limits again
      if (categoryLimits != null &&
          categoryLimits.containsKey(campaign.category)) {
        double categoryLimit = categoryLimits[campaign.category]! * totalAmount;
        double currentCategoryAllocation =
            categoryAllocated[campaign.category] ?? 0.0;
        allocation = math.min(
          allocation,
          categoryLimit - currentCategoryAllocation,
        );
      }

      if (allocation >= campaign.minimumInvestment) {
        // Calculate expected returns
        String defaultTenure =
            campaign.tenureOptions?.isNotEmpty == true
                ? campaign.tenureOptions!.first
                : '1 year';
        var returnCalc = calculatePotentialReturn(
          allocation,
          campaign,
          defaultTenure,
        );

        allocations.add({
          'campaign': campaign,
          'allocation': allocation,
          'percentage': (allocation / totalAmount) * 100,
          'expectedReturn': returnCalc['totalReturn'],
          'expectedProfit': returnCalc['expectedProfit'],
          'score': campaignData['score'],
          'riskLevel': campaignData['riskLevel'],
          'tenure': defaultTenure,
          'projectedROI': returnCalc['projectedROI'],
        });

        totalAllocated += allocation;
        categoryAllocated[campaign.category] =
            (categoryAllocated[campaign.category] ?? 0.0) + allocation;

        if (totalAllocated >= totalAmount * 0.98)
          break; // 98% allocation threshold
      }
    }

    // Calculate portfolio metrics
    double totalExpectedReturn = allocations.fold(
      0.0,
      (sum, allocation) => sum + (allocation['expectedReturn'] as double),
    );
    double totalExpectedProfit = totalExpectedReturn - totalAllocated;

    return {
      'allocations': allocations,
      'totalAllocated': totalAllocated,
      'remainingAmount': totalAmount - totalAllocated,
      'expectedReturn': totalExpectedReturn,
      'expectedProfit': totalExpectedProfit,
      'totalROI':
          totalAllocated > 0
              ? (totalExpectedProfit / totalAllocated) * 100
              : 0.0,
      'diversificationCount': allocations.length,
      'averageRiskLevel': _calculateAverageRiskLevel(allocations),
      'categoryDistribution': categoryAllocated,
      'portfolioScore': _calculatePortfolioScore(allocations),
    };
  }

  static String _calculateAverageRiskLevel(
    List<Map<String, dynamic>> allocations,
  ) {
    if (allocations.isEmpty) return 'Medium';

    Map<String, int> riskCounts = {'Low': 0, 'Medium': 0, 'High': 0};
    for (var allocation in allocations) {
      String risk = allocation['riskLevel'] ?? 'Medium';
      riskCounts[risk] = (riskCounts[risk] ?? 0) + 1;
    }

    String maxRisk = 'Medium';
    int maxCount = 0;
    riskCounts.forEach((risk, count) {
      if (count > maxCount) {
        maxCount = count;
        maxRisk = risk;
      }
    });

    return maxRisk;
  }

  static double _calculatePortfolioScore(
    List<Map<String, dynamic>> allocations,
  ) {
    if (allocations.isEmpty) return 0.0;

    double weightedScore = 0.0;
    double totalWeight = 0.0;

    for (var allocation in allocations) {
      double allocationAmount = allocation['allocation'] as double;
      double campaignScore = allocation['score'] as double;
      weightedScore += campaignScore * allocationAmount;
      totalWeight += allocationAmount;
    }

    return totalWeight > 0 ? weightedScore / totalWeight : 0.0;
  }
}

// Progress tracking utility class
class ProgressTracker {
  static Map<String, dynamic> trackInvestmentProgress(
    Map<String, dynamic> investment,
    DateTime currentDate,
  ) {
    try {
      DateTime startDate = investment['startDate'] ?? DateTime.now();
      String tenure = investment['tenure'] ?? '1 year';
      double tenureInYears = InvestmentCalculator._convertTenureToYears(tenure);
      DateTime endDate = startDate.add(
        Duration(days: (tenureInYears * 365).round()),
      );

      int totalDays = endDate.difference(startDate).inDays;
      int elapsedDays = currentDate
          .difference(startDate)
          .inDays
          .clamp(0, totalDays);
      double progressPercentage =
          totalDays > 0 ? (elapsedDays / totalDays * 100) : 0;

      // Get calculation data
      var calculation =
          investment['calculation'] as Map<String, dynamic>? ?? {};
      List<dynamic> monthlyReturns = calculation['monthlyReturns'] ?? [];
      int currentMonth = (elapsedDays / 30.44).floor();

      Map<String, dynamic>? currentMonthData;
      if (currentMonth >= 0 && currentMonth < monthlyReturns.length) {
        currentMonthData =
            monthlyReturns[currentMonth] as Map<String, dynamic>?;
      }

      return {
        'progressPercentage': progressPercentage.clamp(0.0, 100.0),
        'elapsedDays': elapsedDays,
        'remainingDays': (totalDays - elapsedDays).clamp(0, totalDays),
        'totalDays': totalDays,
        'currentExpectedValue':
            currentMonthData?['amount'] ?? investment['amount'],
        'currentExpectedInterest': currentMonthData?['interest'] ?? 0.0,
        'monthlyGain': currentMonthData?['monthlyGain'] ?? 0.0,
        'currentROI': currentMonthData?['roi'] ?? 0.0,
        'isMatured': elapsedDays >= totalDays,
        'nextMilestone': _getNextMilestone(progressPercentage),
        'timeToMaturity': _formatTimeRemaining(totalDays - elapsedDays),
        'status': _getInvestmentStatus(
          progressPercentage,
          elapsedDays >= totalDays,
        ),
      };
    } catch (e) {
      return {
        'progressPercentage': 0.0,
        'elapsedDays': 0,
        'remainingDays': 0,
        'totalDays': 0,
        'currentExpectedValue': investment['amount'] ?? 0.0,
        'currentExpectedInterest': 0.0,
        'monthlyGain': 0.0,
        'currentROI': 0.0,
        'isMatured': false,
        'nextMilestone': null,
        'timeToMaturity': 'Unknown',
        'status': 'Error',
        'error': e.toString(),
      };
    }
  }

  static Map<String, dynamic>? _getNextMilestone(double currentProgress) {
    List<int> milestones = [25, 50, 75, 90, 100];
    for (int milestone in milestones) {
      if (currentProgress < milestone) {
        return {
          'percentage': milestone,
          'remainingProgress': milestone - currentProgress,
          'description': _getMilestoneDescription(milestone),
        };
      }
    }
    return null;
  }

  static String _getMilestoneDescription(int milestone) {
    switch (milestone) {
      case 25:
        return 'Quarter Complete';
      case 50:
        return 'Halfway Point';
      case 75:
        return 'Three Quarters Complete';
      case 90:
        return 'Near Maturity';
      case 100:
        return 'Maturity';
      default:
        return 'Milestone';
    }
  }

  static String _formatTimeRemaining(int days) {
    if (days <= 0) return 'Matured';
    if (days == 1) return '1 day';
    if (days < 30) return '$days days';

    int months = (days / 30.44).round();
    if (months == 1) return '1 month';
    if (months < 12) return '$months months';

    int years = (months / 12).floor();
    int remainingMonths = months % 12;
    if (years == 1 && remainingMonths == 0) return '1 year';
    if (remainingMonths == 0) return '$years years';
    return '$years years, $remainingMonths months';
  }

  static String _getInvestmentStatus(double progress, bool isMatured) {
    if (isMatured) return 'Matured';
    if (progress >= 90) return 'Near Maturity';
    if (progress >= 75) return 'Advanced';
    if (progress >= 50) return 'Mid-term';
    if (progress >= 25) return 'Early Stage';
    return 'Just Started';
  }
}
