import 'dart:convert';

class Campaign {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final String type;
  final String status;
  final double targetAmount;
  final double minimumInvestment;
  final String category;
  final String? unit;
  final int? quantity;
  final String? gestationPeriod;
  final List<String>? tenureOptions;
  final double? averageCostPerUnit;
  final double? totalLoanIncludingFeePerUnit;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> imageUrls;
  final List<String> documentUrls;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double totalRaised;
  final int investorCount;
  final int totalInvestments;
  final int fundingPercentage;

  // Additional computed properties for investment calculator compatibility
  double get currentAmount => totalRaised;

  /// Whether the campaign is currently active and available for investment
  bool get isActiveForInvestment {
    final now = DateTime.now();
    return status.toLowerCase() == 'active' &&
        now.isAfter(startDate) &&
        now.isBefore(endDate) &&
        totalRaised < targetAmount;
  }

  /// The remaining amount needed to reach the target
  double get remainingAmount => targetAmount - totalRaised;

  Map<String, double> get returnRate {
    // Extract return rates from metadata or provide defaults
    if (metadata.containsKey('returnRates')) {
      final rates = metadata['returnRates'] as Map<String, dynamic>? ?? {};
      return rates.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    }

    // Provide default return rates based on campaign type and tenure options
    return _getDefaultReturnRates();
  }

  Campaign({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.targetAmount,
    required this.minimumInvestment,
    required this.category,
    this.unit,
    this.quantity,
    this.gestationPeriod,
    this.tenureOptions,
    this.averageCostPerUnit,
    this.totalLoanIncludingFeePerUnit,
    required this.startDate,
    required this.endDate,
    required this.imageUrls,
    required this.documentUrls,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    required this.totalRaised,
    required this.investorCount,
    required this.totalInvestments,
    required this.fundingPercentage,
  });

  Map<String, double> _getDefaultReturnRates() {
    final baseRates = <String, double>{};

    // Set default rates based on campaign type
    double multiplier = 1.0;
    switch (type.toLowerCase()) {
      case 'investment':
        multiplier = 1.2;
        break;
      case 'loan':
        multiplier = 1.0;
        break;
      case 'crowdfunding':
        multiplier = 0.8;
        break;
    }

    // Apply rates to tenure options
    if (tenureOptions != null) {
      for (String tenure in tenureOptions!) {
        baseRates[tenure] = _calculateDefaultRate(tenure) * multiplier;
      }
    } else {
      // Default tenure options if none provided
      baseRates['1 year'] = 10.0 * multiplier;
    }

    return baseRates;
  }

  double _calculateDefaultRate(String tenure) {
    final tenureMap = <String, double>{
      '3 months': 2.5,
      '6 months': 5.0,
      '9 months': 7.5,
      '1 year': 10.0,
      '18 months': 15.0,
      '2 years': 20.0,
      '3 years': 30.0,
    };

    return tenureMap[tenure] ?? 10.0;
  }

  /// Create Campaign from JSON with enhanced error handling
  factory Campaign.fromJson(Map<String, dynamic> json) {
    try {
      return Campaign(
        id: json['id']?.toString() ?? '',
        ownerId: json['ownerId']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        type: json['type']?.toString() ?? 'loan',
        status: json['status']?.toString() ?? 'draft',
        targetAmount: _parseDouble(json['targetAmount']),
        minimumInvestment: _parseDouble(json['minimumInvestment']),
        category: json['category']?.toString() ?? '',
        unit: json['unit']?.toString(),
        quantity: _parseInt(json['quantity']),
        gestationPeriod: json['gestationPeriod']?.toString(),
        tenureOptions: _parseStringList(json['tenureOptions']),
        averageCostPerUnit: _parseDoubleNullable(json['averageCostPerUnit']),
        totalLoanIncludingFeePerUnit: _parseDoubleNullable(
          json['totalLoanIncludingFeePerUnit'],
        ),
        startDate: _parseDateTime(json['startDate']),
        endDate: _parseDateTime(json['endDate']),
        imageUrls: _parseStringList(json['imageUrls']) ?? [],
        documentUrls: _parseStringList(json['documentUrls']) ?? [],
        metadata: _parseMetadata(json['metadata']),
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
        totalRaised: _parseDouble(json['totalRaised']),
        investorCount: _parseInt(json['investorCount']) ?? 0,
        totalInvestments: _parseInt(json['totalInvestments']) ?? 0,
        fundingPercentage: _parseInt(json['fundingPercentage']) ?? 0,
      );
    } catch (e) {
      throw FormatException('Failed to parse Campaign from JSON: $e');
    }
  }

  /// Convert Campaign to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'title': title,
      'description': description,
      'type': type,
      'status': status,
      'targetAmount': targetAmount,
      'minimumInvestment': minimumInvestment,
      'category': category,
      if (unit != null) 'unit': unit,
      if (quantity != null) 'quantity': quantity,
      if (gestationPeriod != null) 'gestationPeriod': gestationPeriod,
      if (tenureOptions != null) 'tenureOptions': tenureOptions,
      if (averageCostPerUnit != null) 'averageCostPerUnit': averageCostPerUnit,
      if (totalLoanIncludingFeePerUnit != null)
        'totalLoanIncludingFeePerUnit': totalLoanIncludingFeePerUnit,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'imageUrls': imageUrls,
      'documentUrls': documentUrls,
      'metadata': metadata,
      if (id.isNotEmpty) 'createdAt': createdAt.toIso8601String(),
      if (id.isNotEmpty) 'updatedAt': updatedAt.toIso8601String(),
      if (id.isNotEmpty) 'totalRaised': totalRaised,
      if (id.isNotEmpty) 'investorCount': investorCount,
      if (id.isNotEmpty) 'totalInvestments': totalInvestments,
      if (id.isNotEmpty) 'fundingPercentage': fundingPercentage,
    };
  }

  /// Create a copy of this Campaign with updated fields
  Campaign copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    String? type,
    String? status,
    double? targetAmount,
    double? minimumInvestment,
    String? category,
    String? unit,
    int? quantity,
    String? gestationPeriod,
    List<String>? tenureOptions,
    double? averageCostPerUnit,
    double? totalLoanIncludingFeePerUnit,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? imageUrls,
    List<String>? documentUrls,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? totalRaised,
    int? investorCount,
    int? totalInvestments,
    int? fundingPercentage,
  }) {
    return Campaign(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      targetAmount: targetAmount ?? this.targetAmount,
      minimumInvestment: minimumInvestment ?? this.minimumInvestment,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      gestationPeriod: gestationPeriod ?? this.gestationPeriod,
      tenureOptions: tenureOptions ?? this.tenureOptions,
      averageCostPerUnit: averageCostPerUnit ?? this.averageCostPerUnit,
      totalLoanIncludingFeePerUnit:
          totalLoanIncludingFeePerUnit ?? this.totalLoanIncludingFeePerUnit,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      imageUrls: imageUrls ?? this.imageUrls,
      documentUrls: documentUrls ?? this.documentUrls,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalRaised: totalRaised ?? this.totalRaised,
      investorCount: investorCount ?? this.investorCount,
      totalInvestments: totalInvestments ?? this.totalInvestments,
      fundingPercentage: fundingPercentage ?? this.fundingPercentage,
    );
  }

  /// Check if campaign is active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) &&
        now.isBefore(endDate) &&
        status.toLowerCase() == 'active';
  }

  /// Check if campaign is fully funded
  bool get isFullyFunded => totalRaised >= targetAmount;

  /// Get funding progress percentage
  double get fundingProgress {
    if (targetAmount <= 0) return 0.0;
    return ((totalRaised / targetAmount) * 100).clamp(0.0, 100.0);
  }

  /// Get days remaining
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  /// Get campaign duration in days
  int get totalDurationDays => endDate.difference(startDate).inDays;

  /// Get time elapsed since campaign started
  double get timeElapsedPercentage {
    if (totalDurationDays <= 0) return 0.0;
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0.0;
    if (now.isAfter(endDate)) return 100.0;

    final elapsedDays = now.difference(startDate).inDays;
    return ((elapsedDays / totalDurationDays) * 100).clamp(0.0, 100.0);
  }

  /// Get campaign risk level based on various factors
  String get riskLevel {
    int riskScore = 0;

    // Category-based risk
    const categoryRisk = {
      'Crop': 3,
      'Livestock': 4,
      'Poultry': 4,
      'Aquaculture': 5,
      'Horticulture': 3,
      'Agro-processing': 2,
      'Farm Equipment': 1,
    };

    riskScore += categoryRisk[category] ?? 3;

    // Funding progress risk
    if (fundingProgress < 20)
      riskScore += 2;
    else if (fundingProgress < 50)
      riskScore += 1;
    else if (fundingProgress > 90)
      riskScore -= 1;

    // Time remaining risk
    if (daysRemaining < 30)
      riskScore += 2;
    else if (daysRemaining < 90)
      riskScore += 1;

    // Amount size risk
    if (targetAmount > 10000000) riskScore += 1;
    if (minimumInvestment > 500000) riskScore += 1;

    if (riskScore <= 3) return 'Low';
    if (riskScore >= 7) return 'High';
    return 'Medium';
  }

  /// Get campaign momentum
  String get momentum {
    if (totalDurationDays <= 0) return 'Stable';

    final timeProgress = timeElapsedPercentage;
    final fundingProgressPercent = fundingProgress;

    if (fundingProgressPercent > timeProgress * 1.3) return 'Accelerating';
    if (fundingProgressPercent > timeProgress * 1.1) return 'Strong';
    if (fundingProgressPercent < timeProgress * 0.7) return 'Slowing';
    if (fundingProgressPercent < timeProgress * 0.5) return 'Critical';
    return 'Stable';
  }

  /// Check if this campaign equals another
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Campaign && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Campaign{id: $id, title: $title, type: $type, status: $status, progress: ${fundingProgress.toStringAsFixed(1)}%}';
  }

  // Static helper methods for parsing JSON values safely
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static double? _parseDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return null;
  }

  static Map<String, dynamic> _parseMetadata(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        // If JSON parsing fails, return empty map
      }
    }
    return {};
  }

  /// Validate campaign data
  List<String> validate() {
    final errors = <String>[];

    if (title.trim().isEmpty) {
      errors.add('Campaign title is required');
    } else if (title.length < 10) {
      errors.add('Campaign title must be at least 10 characters');
    } else if (title.length > 100) {
      errors.add('Campaign title must be less than 100 characters');
    }

    if (description.trim().isEmpty) {
      errors.add('Campaign description is required');
    } else if (description.length < 50) {
      errors.add('Campaign description must be at least 50 characters');
    } else if (description.length > 5000) {
      errors.add('Campaign description must be less than 5000 characters');
    }

    if (targetAmount <= 0) {
      errors.add('Target amount must be greater than 0');
    } else if (targetAmount > 1000000000) {
      errors.add('Target amount cannot exceed ₦1 billion');
    }

    if (minimumInvestment <= 0) {
      errors.add('Minimum investment must be greater than 0');
    } else if (minimumInvestment > targetAmount) {
      errors.add('Minimum investment cannot exceed target amount');
    }

    if (category.trim().isEmpty) {
      errors.add('Campaign category is required');
    }

    if (startDate.isAfter(endDate)) {
      errors.add('Start date must be before end date');
    }

    if (endDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      errors.add('End date must be in the future');
    }

    final maxDuration = const Duration(days: 365 * 2); // 2 years max
    if (endDate.difference(startDate) > maxDuration) {
      errors.add('Campaign duration cannot exceed 2 years');
    }

    if (tenureOptions?.isEmpty ?? true) {
      errors.add('At least one tenure option must be provided');
    }

    // Validate tenure options format
    if (tenureOptions != null) {
      for (String tenure in tenureOptions!) {
        if (!_isValidTenureFormat(tenure)) {
          errors.add('Invalid tenure format: $tenure');
        }
      }
    }

    // Validate average cost and loan fee
    if (averageCostPerUnit != null && averageCostPerUnit! <= 0) {
      errors.add('Average cost per unit must be positive');
    }

    if (totalLoanIncludingFeePerUnit != null && averageCostPerUnit != null) {
      final expectedFee = averageCostPerUnit! * 1.025;
      final tolerance = averageCostPerUnit! * 0.001; // 0.1% tolerance
      if ((totalLoanIncludingFeePerUnit! - expectedFee).abs() > tolerance) {
        errors.add('Total loan fee calculation appears incorrect');
      }
    }

    return errors;
  }

  static bool _isValidTenureFormat(String tenure) {
    // Valid formats: "3 months", "1 year", "2 years", etc.
    final regex = RegExp(
      r'^\d+\s+(month|months|year|years)$',
      caseSensitive: false,
    );
    return regex.hasMatch(tenure);
  }

  /// Create a draft campaign with minimal required fields
  static Campaign createDraft({
    required String title,
    required String description,
    required String type,
    required double targetAmount,
    required double minimumInvestment,
    required String category,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? tenureOptions,
  }) {
    return Campaign(
      id: '',
      ownerId: '',
      title: title,
      description: description,
      type: type,
      status: 'Draft',
      targetAmount: targetAmount,
      minimumInvestment: minimumInvestment,
      category: category,
      startDate: startDate,
      endDate: endDate,
      tenureOptions: tenureOptions ?? ['1 year'],
      imageUrls: [],
      documentUrls: [],
      metadata: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      totalRaised: 0.0,
      investorCount: 0,
      totalInvestments: 0,
      fundingPercentage: 0,
    );
  }

  /// Create a test campaign for development/testing purposes
  static Campaign createTestCampaign({
    String? id,
    String? ownerId,
    double? fundingProgress,
  }) {
    final now = DateTime.now();
    final targetAmount = 1000000.0;
    final raised =
        fundingProgress != null
            ? targetAmount * (fundingProgress / 100)
            : 250000.0;

    return Campaign(
      id: id ?? 'test_${now.millisecondsSinceEpoch}',
      ownerId: ownerId ?? 'test_owner',
      title: 'Test Agriculture Campaign',
      description:
          'This is a test campaign for development and testing purposes. It showcases typical agricultural investment opportunities with realistic data and metrics.',
      type: 'investment',
      status: 'Active',
      targetAmount: targetAmount,
      minimumInvestment: 50000.0,
      category: 'Crop',
      unit: 'Hectare',
      quantity: 10,
      gestationPeriod: '4-6 months',
      tenureOptions: ['6 months', '1 year', '2 years'],
      averageCostPerUnit: 100000.0,
      totalLoanIncludingFeePerUnit: 102500.0,
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now.add(const Duration(days: 90)),
      imageUrls: [
        'https://example.com/image1.jpg',
        'https://example.com/image2.jpg',
      ],
      documentUrls: ['https://example.com/document1.pdf'],
      metadata: {
        'returnRates': {'6 months': 8.0, '1 year': 15.0, '2 years': 30.0},
        'riskLevel': 'Medium',
        'location': 'Lagos State',
        'farmerExperience': '5 years',
        'cropType': 'Maize',
        'isTest': true,
      },
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
      totalRaised: raised,
      investorCount: (raised / 50000).floor(),
      totalInvestments: (raised / 50000).floor(),
      fundingPercentage: ((raised / targetAmount) * 100).round(),
    );
  }
}
