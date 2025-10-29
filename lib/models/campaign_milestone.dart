import 'campaign.dart';
import 'campaign_enum.dart';

/// Milestone status enumeration
enum MilestoneStatus {
  pending('Pending'),
  inProgress('In Progress'),
  completed('Completed'),
  overdue('Overdue'),
  cancelled('Cancelled');

  const MilestoneStatus(this.value);
  final String value;

  static MilestoneStatus fromString(String status) {
    return MilestoneStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => MilestoneStatus.pending,
    );
  }
}

/// Milestone type enumeration
enum MilestoneType {
  funding('Funding Target'),
  preparation('Preparation Phase'),
  planting('Planting Phase'),
  growth('Growth Phase'),
  harvest('Harvest Phase'),
  processing('Processing Phase'),
  distribution('Distribution Phase'),
  payout('Investor Payout');

  const MilestoneType(this.value);
  final String value;

  static MilestoneType fromString(String type) {
    return MilestoneType.values.firstWhere(
      (e) => e.value == type,
      orElse: () => MilestoneType.funding,
    );
  }
}

/// Risk level enumeration for campaigns
enum RiskLevel {
  low('Low', 'Low risk with stable returns'),
  medium('Medium', 'Moderate risk with good potential returns'),
  high('High', 'High risk with potentially high returns'),
  veryHigh('Very High', 'Very high risk - invest with caution');

  const RiskLevel(this.value, this.description);
  final String value;
  final String description;

  static RiskLevel fromString(String level) {
    return RiskLevel.values.firstWhere(
      (e) => e.value == level,
      orElse: () => RiskLevel.medium,
    );
  }
}

/// Campaign milestone model for tracking progress
class CampaignMilestone {
  final String id;
  final String campaignId;
  final String title;
  final String description;
  final MilestoneType type;
  final MilestoneStatus status;
  final double? targetAmount; // For funding milestones
  final double currentAmount; // Current progress amount
  final DateTime targetDate;
  final DateTime? completedDate;
  final String? notes;
  final List<String> imageUrls; // Progress photos
  final List<String> documentUrls; // Supporting documents
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CampaignMilestone({
    required this.id,
    required this.campaignId,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    this.targetAmount,
    this.currentAmount = 0.0,
    required this.targetDate,
    this.completedDate,
    this.notes,
    this.imageUrls = const [],
    this.documentUrls = const [],
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if milestone is completed
  bool get isCompleted => status == MilestoneStatus.completed;

  /// Check if milestone is overdue
  bool get isOverdue => !isCompleted && DateTime.now().isAfter(targetDate);

  /// Get progress percentage (for amount-based milestones)
  double get progressPercentage {
    if (targetAmount == null || targetAmount! <= 0) return 0.0;
    return (currentAmount / targetAmount!) * 100;
  }

  /// Get days until target date
  int get daysUntilTarget {
    final now = DateTime.now();
    if (now.isAfter(targetDate)) return 0;
    return targetDate.difference(now).inDays;
  }

  /// Get days overdue (if applicable)
  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(targetDate).inDays;
  }

  /// Create CampaignMilestone from JSON
  factory CampaignMilestone.fromJson(Map<String, dynamic> json) {
    return CampaignMilestone(
      id: json['id'] as String,
      campaignId: json['campaignId'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: MilestoneType.fromString(json['type'] as String? ?? 'funding'),
      status: MilestoneStatus.fromString(
        json['status'] as String? ?? 'pending',
      ),
      targetAmount: (json['targetAmount'] as num?)?.toDouble(),
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      targetDate: DateTime.parse(json['targetDate'] as String),
      completedDate:
          json['completedDate'] != null
              ? DateTime.parse(json['completedDate'] as String)
              : null,
      notes: json['notes'] as String?,
      imageUrls: List<String>.from(json['imageUrls'] as List? ?? []),
      documentUrls: List<String>.from(json['documentUrls'] as List? ?? []),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert CampaignMilestone to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'campaignId': campaignId,
      'title': title,
      'description': description,
      'type': type.value,
      'status': status.value,
      if (targetAmount != null) 'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate.toIso8601String(),
      if (completedDate != null)
        'completedDate': completedDate!.toIso8601String(),
      if (notes != null) 'notes': notes,
      'imageUrls': imageUrls,
      'documentUrls': documentUrls,
      if (metadata != null) 'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  CampaignMilestone copyWith({
    String? id,
    String? campaignId,
    String? title,
    String? description,
    MilestoneType? type,
    MilestoneStatus? status,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    DateTime? completedDate,
    String? notes,
    List<String>? imageUrls,
    List<String>? documentUrls,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CampaignMilestone(
      id: id ?? this.id,
      campaignId: campaignId ?? this.campaignId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      completedDate: completedDate ?? this.completedDate,
      notes: notes ?? this.notes,
      imageUrls: imageUrls ?? this.imageUrls,
      documentUrls: documentUrls ?? this.documentUrls,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CampaignMilestone(id: $id, title: $title, status: ${status.value}, progress: ${progressPercentage.toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CampaignMilestone && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Enhanced Campaign model with milestones and risk assessment
class EnhancedCampaign {
  final String id;
  final String title;
  final String description;
  final String ownerId;
  final String ownerName;
  final CampaignType type;
  final CampaignStatus status;
  final double targetAmount;
  final double currentAmount;
  final double minimumInvestment;
  final String category;
  final String unit;
  final int quantity;
  final String gestationPeriod;
  final List<String> tenureOptions;
  final double averageCostPerUnit;
  final double totalLoanIncludingFeePerUnit;
  final List<String> imageUrls;
  final List<String> documentUrls;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  // NEW: Enhanced features
  final List<CampaignMilestone> milestones;
  final RiskLevel riskLevel;
  final List<String> riskFactors;
  final String riskAssessment;
  final double expectedROI; // Expected Return on Investment percentage
  final String farmLocation; // Detailed location information
  final Map<String, String> farmDetails; // Farm size, soil type, etc.
  final List<String> certifications; // Organic, Fair Trade, etc.

  const EnhancedCampaign({
    required this.id,
    required this.title,
    required this.description,
    required this.ownerId,
    required this.ownerName,
    required this.type,
    required this.status,
    required this.targetAmount,
    required this.currentAmount,
    required this.minimumInvestment,
    required this.category,
    required this.unit,
    required this.quantity,
    required this.gestationPeriod,
    required this.tenureOptions,
    required this.averageCostPerUnit,
    required this.totalLoanIncludingFeePerUnit,
    required this.imageUrls,
    required this.documentUrls,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
    this.milestones = const [],
    this.riskLevel = RiskLevel.medium,
    this.riskFactors = const [],
    this.riskAssessment = '',
    this.expectedROI = 0.0,
    this.farmLocation = '',
    this.farmDetails = const {},
    this.certifications = const [],
  });

  /// Calculate funding progress percentage
  double get fundingProgress =>
      targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0;

  /// Check if campaign is fully funded
  bool get isFullyFunded => currentAmount >= targetAmount;

  /// Check if campaign is active and accepting investments
  bool get isActiveForInvestment =>
      status == CampaignStatus.active &&
      DateTime.now().isBefore(endDate) &&
      !isFullyFunded;

  /// Get remaining amount needed
  double get remainingAmount =>
      (targetAmount - currentAmount).clamp(0, double.infinity);

  /// Get days remaining for campaign
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  /// Get completed milestones
  List<CampaignMilestone> get completedMilestones =>
      milestones.where((m) => m.isCompleted).toList();

  /// Get pending milestones
  List<CampaignMilestone> get pendingMilestones =>
      milestones.where((m) => !m.isCompleted).toList();

  /// Get overdue milestones
  List<CampaignMilestone> get overdueMilestones =>
      milestones.where((m) => m.isOverdue).toList();

  /// Get next milestone
  CampaignMilestone? get nextMilestone {
    final pending = pendingMilestones;
    if (pending.isEmpty) return null;

    pending.sort((a, b) => a.targetDate.compareTo(b.targetDate));
    return pending.first;
  }

  /// Get milestone completion percentage
  double get milestoneProgress {
    if (milestones.isEmpty) return 0.0;
    final completed = completedMilestones.length;
    return (completed / milestones.length) * 100;
  }

  /// Check if campaign has any overdue milestones
  bool get hasOverdueMilestones => overdueMilestones.isNotEmpty;

  /// Get risk score (0-100, higher = riskier)
  int get riskScore {
    switch (riskLevel) {
      case RiskLevel.low:
        return 25;
      case RiskLevel.medium:
        return 50;
      case RiskLevel.high:
        return 75;
      case RiskLevel.veryHigh:
        return 90;
    }
  }

  /// Get formatted expected ROI
  String get formattedExpectedROI => '${expectedROI.toStringAsFixed(1)}%';

  /// Create EnhancedCampaign from JSON
  factory EnhancedCampaign.fromJson(Map<String, dynamic> json) {
    // Parse milestones
    final milestonesList = <CampaignMilestone>[];
    if (json['milestones'] is List) {
      milestonesList.addAll(
        (json['milestones'] as List)
            .map((m) => CampaignMilestone.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
    }

    return EnhancedCampaign(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      ownerId: json['ownerId'] as String,
      ownerName: json['ownerName'] as String? ?? '',
      type: CampaignType.fromString(json['type'] as String? ?? 'loan'),
      status: CampaignStatus.fromString(json['status'] as String? ?? 'draft'),
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      minimumInvestment: (json['minimumInvestment'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      gestationPeriod: json['gestationPeriod'] as String? ?? '',
      tenureOptions: List<String>.from(json['tenureOptions'] as List? ?? []),
      averageCostPerUnit:
          (json['averageCostPerUnit'] as num?)?.toDouble() ?? 0.0,
      totalLoanIncludingFeePerUnit:
          (json['totalLoanIncludingFeePerUnit'] as num?)?.toDouble() ?? 0.0,
      imageUrls: List<String>.from(json['imageUrls'] as List? ?? []),
      documentUrls: List<String>.from(json['documentUrls'] as List? ?? []),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      milestones: milestonesList,
      riskLevel: RiskLevel.fromString(json['riskLevel'] as String? ?? 'Medium'),
      riskFactors: List<String>.from(json['riskFactors'] as List? ?? []),
      riskAssessment: json['riskAssessment'] as String? ?? '',
      expectedROI: (json['expectedROI'] as num?)?.toDouble() ?? 0.0,
      farmLocation: json['farmLocation'] as String? ?? '',
      farmDetails: Map<String, String>.from(json['farmDetails'] as Map? ?? {}),
      certifications: List<String>.from(json['certifications'] as List? ?? []),
    );
  }

  /// Convert EnhancedCampaign to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'type': type.value,
      'status': status.value,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'minimumInvestment': minimumInvestment,
      'category': category,
      'unit': unit,
      'quantity': quantity,
      'gestationPeriod': gestationPeriod,
      'tenureOptions': tenureOptions,
      'averageCostPerUnit': averageCostPerUnit,
      'totalLoanIncludingFeePerUnit': totalLoanIncludingFeePerUnit,
      'imageUrls': imageUrls,
      'documentUrls': documentUrls,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
      'milestones': milestones.map((m) => m.toJson()).toList(),
      'riskLevel': riskLevel.value,
      'riskFactors': riskFactors,
      'riskAssessment': riskAssessment,
      'expectedROI': expectedROI,
      'farmLocation': farmLocation,
      'farmDetails': farmDetails,
      'certifications': certifications,
    };
  }

  /// Create a copy with updated fields
  EnhancedCampaign copyWith({
    String? id,
    String? title,
    String? description,
    String? ownerId,
    String? ownerName,
    CampaignType? type,
    CampaignStatus? status,
    double? targetAmount,
    double? currentAmount,
    double? minimumInvestment,
    String? category,
    String? unit,
    int? quantity,
    String? gestationPeriod,
    List<String>? tenureOptions,
    double? averageCostPerUnit,
    double? totalLoanIncludingFeePerUnit,
    List<String>? imageUrls,
    List<String>? documentUrls,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    List<CampaignMilestone>? milestones,
    RiskLevel? riskLevel,
    List<String>? riskFactors,
    String? riskAssessment,
    double? expectedROI,
    String? farmLocation,
    Map<String, String>? farmDetails,
    List<String>? certifications,
  }) {
    return EnhancedCampaign(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      type: type ?? this.type,
      status: status ?? this.status,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      minimumInvestment: minimumInvestment ?? this.minimumInvestment,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      gestationPeriod: gestationPeriod ?? this.gestationPeriod,
      tenureOptions: tenureOptions ?? this.tenureOptions,
      averageCostPerUnit: averageCostPerUnit ?? this.averageCostPerUnit,
      totalLoanIncludingFeePerUnit:
          totalLoanIncludingFeePerUnit ?? this.totalLoanIncludingFeePerUnit,
      imageUrls: imageUrls ?? this.imageUrls,
      documentUrls: documentUrls ?? this.documentUrls,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      milestones: milestones ?? this.milestones,
      riskLevel: riskLevel ?? this.riskLevel,
      riskFactors: riskFactors ?? this.riskFactors,
      riskAssessment: riskAssessment ?? this.riskAssessment,
      expectedROI: expectedROI ?? this.expectedROI,
      farmLocation: farmLocation ?? this.farmLocation,
      farmDetails: farmDetails ?? this.farmDetails,
      certifications: certifications ?? this.certifications,
    );
  }

  @override
  String toString() {
    return 'EnhancedCampaign(id: $id, title: $title, status: $status, progress: ${fundingProgress.toStringAsFixed(1)}%, risk: ${riskLevel.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EnhancedCampaign && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
