import 'dart:convert';

/// Investment status enumeration
enum InvestmentStatus {
  pending,
  approved,
  active,
  completed,
  cancelled,
  failed;

  String get value => name;

  static InvestmentStatus fromString(String status) {
    return InvestmentStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => InvestmentStatus.pending,
    );
  }
}

/// Investment model for tracking user investments in campaigns
class Investment {
  final String id;
  final String campaignId;
  final String campaignTitle;
  final String investorId;
  final String investorName;
  final double amount;
  final String tenure;
  final double expectedReturn;
  final double actualReturn;
  final InvestmentStatus status;
  final String paymentReference;
  final DateTime investmentDate;
  final DateTime expectedMaturityDate;
  final DateTime? actualMaturityDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const Investment({
    required this.id,
    required this.campaignId,
    required this.campaignTitle,
    required this.investorId,
    required this.investorName,
    required this.amount,
    required this.tenure,
    required this.expectedReturn,
    required this.actualReturn,
    required this.status,
    required this.paymentReference,
    required this.investmentDate,
    required this.expectedMaturityDate,
    this.actualMaturityDate,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  /// Check if investment is active
  bool get isActive => status == InvestmentStatus.active;

  /// Check if investment is completed
  bool get isCompleted => status == InvestmentStatus.completed;

  /// Check if investment has matured
  bool get hasMatured => DateTime.now().isAfter(expectedMaturityDate);

  /// Get days until maturity
  int get daysUntilMaturity {
    final now = DateTime.now();
    if (now.isAfter(expectedMaturityDate)) return 0;
    return expectedMaturityDate.difference(now).inDays;
  }

  /// Calculate ROI percentage
  double get roiPercentage => amount > 0 ? ((actualReturn - amount) / amount) * 100 : 0;

  /// Get formatted ROI
  String get formattedROI => '${roiPercentage.toStringAsFixed(2)}%';

  /// Create Investment from JSON
  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'] as String,
      campaignId: json['campaignId'] as String,
      campaignTitle: json['campaignTitle'] as String? ?? '',
      investorId: json['investorId'] as String,
      investorName: json['investorName'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      tenure: json['tenure'] as String? ?? '',
      expectedReturn: (json['expectedReturn'] as num?)?.toDouble() ?? 0.0,
      actualReturn: (json['actualReturn'] as num?)?.toDouble() ?? 0.0,
      status: InvestmentStatus.fromString(json['status'] as String? ?? 'pending'),
      paymentReference: json['paymentReference'] as String? ?? '',
      investmentDate: DateTime.parse(json['investmentDate'] as String),
      expectedMaturityDate: DateTime.parse(json['expectedMaturityDate'] as String),
      actualMaturityDate: json['actualMaturityDate'] != null 
          ? DateTime.parse(json['actualMaturityDate'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert Investment to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'campaignId': campaignId,
      'campaignTitle': campaignTitle,
      'investorId': investorId,
      'investorName': investorName,
      'amount': amount,
      'tenure': tenure,
      'expectedReturn': expectedReturn,
      'actualReturn': actualReturn,
      'status': status.value,
      'paymentReference': paymentReference,
      'investmentDate': investmentDate.toIso8601String(),
      'expectedMaturityDate': expectedMaturityDate.toIso8601String(),
      if (actualMaturityDate != null) 'actualMaturityDate': actualMaturityDate!.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  Investment copyWith({
    String? id,
    String? campaignId,
    String? campaignTitle,
    String? investorId,
    String? investorName,
    double? amount,
    String? tenure,
    double? expectedReturn,
    double? actualReturn,
    InvestmentStatus? status,
    String? paymentReference,
    DateTime? investmentDate,
    DateTime? expectedMaturityDate,
    DateTime? actualMaturityDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Investment(
      id: id ?? this.id,
      campaignId: campaignId ?? this.campaignId,
      campaignTitle: campaignTitle ?? this.campaignTitle,
      investorId: investorId ?? this.investorId,
      investorName: investorName ?? this.investorName,
      amount: amount ?? this.amount,
      tenure: tenure ?? this.tenure,
      expectedReturn: expectedReturn ?? this.expectedReturn,
      actualReturn: actualReturn ?? this.actualReturn,
      status: status ?? this.status,
      paymentReference: paymentReference ?? this.paymentReference,
      investmentDate: investmentDate ?? this.investmentDate,
      expectedMaturityDate: expectedMaturityDate ?? this.expectedMaturityDate,
      actualMaturityDate: actualMaturityDate ?? this.actualMaturityDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'Investment(id: $id, campaign: $campaignTitle, amount: $amount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Investment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
