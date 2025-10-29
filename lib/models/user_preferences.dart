import 'dart:convert';

/// Notification preferences enumeration
enum NotificationPreference {
  all('All'),
  important('Important Only'),
  none('None');

  const NotificationPreference(this.value);
  final String value;

  static NotificationPreference fromString(String preference) {
    return NotificationPreference.values.firstWhere(
      (e) => e.value == preference,
      orElse: () => NotificationPreference.important,
    );
  }
}

/// Risk tolerance enumeration
enum RiskTolerance {
  conservative('Conservative'),
  moderate('Moderate'),
  aggressive('Aggressive');

  const RiskTolerance(this.value);
  final String value;

  static RiskTolerance fromString(String tolerance) {
    return RiskTolerance.values.firstWhere(
      (e) => e.value == tolerance,
      orElse: () => RiskTolerance.moderate,
    );
  }
}

/// Investment focus enumeration
enum InvestmentFocus {
  returns('Maximum Returns'),
  sustainability('Sustainability'),
  community('Community Impact'),
  diversification('Diversification');

  const InvestmentFocus(this.value);
  final String value;

  static InvestmentFocus fromString(String focus) {
    return InvestmentFocus.values.firstWhere(
      (e) => e.value == focus,
      orElse: () => InvestmentFocus.returns,
    );
  }
}

/// Theme preference enumeration
enum ThemePreference {
  light('Light'),
  dark('Dark'),
  system('System');

  const ThemePreference(this.value);
  final String value;

  static ThemePreference fromString(String theme) {
    return ThemePreference.values.firstWhere(
      (e) => e.value == theme,
      orElse: () => ThemePreference.system,
    );
  }
}

/// Language preference enumeration
enum LanguagePreference {
  english('English'),
  french('French'),
  spanish('Spanish'),
  portuguese('Portuguese');

  const LanguagePreference(this.value);
  final String value;

  static LanguagePreference fromString(String language) {
    return LanguagePreference.values.firstWhere(
      (e) => e.value == language,
      orElse: () => LanguagePreference.english,
    );
  }
}

/// Currency preference enumeration
enum CurrencyPreference {
  usd('USD'),
  eur('EUR'),
  gbp('GBP'),
  cad('CAD'),
  ngn('NGN'),
  ghs('GHS'),
  kes('KES');

  const CurrencyPreference(this.value);
  final String value;

  static CurrencyPreference fromString(String currency) {
    return CurrencyPreference.values.firstWhere(
      (e) => e.value == currency,
      orElse: () => CurrencyPreference.usd,
    );
  }
}

/// Milestone notification settings
class MilestoneNotificationSettings {
  final bool campaignStarted;
  final bool milestoneCompleted;
  final bool milestoneOverdue;
  final bool payoutReceived;
  final bool campaignUpdates;
  final bool riskAlerts;
  final int daysBeforeReminder; // Days before milestone due date to send reminder

  const MilestoneNotificationSettings({
    this.campaignStarted = true,
    this.milestoneCompleted = true,
    this.milestoneOverdue = true,
    this.payoutReceived = true,
    this.campaignUpdates = true,
    this.riskAlerts = true,
    this.daysBeforeReminder = 3,
  });

  factory MilestoneNotificationSettings.fromJson(Map<String, dynamic> json) {
    return MilestoneNotificationSettings(
      campaignStarted: json['campaignStarted'] as bool? ?? true,
      milestoneCompleted: json['milestoneCompleted'] as bool? ?? true,
      milestoneOverdue: json['milestoneOverdue'] as bool? ?? true,
      payoutReceived: json['payoutReceived'] as bool? ?? true,
      campaignUpdates: json['campaignUpdates'] as bool? ?? true,
      riskAlerts: json['riskAlerts'] as bool? ?? true,
      daysBeforeReminder: json['daysBeforeReminder'] as int? ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'campaignStarted': campaignStarted,
      'milestoneCompleted': milestoneCompleted,
      'milestoneOverdue': milestoneOverdue,
      'payoutReceived': payoutReceived,
      'campaignUpdates': campaignUpdates,
      'riskAlerts': riskAlerts,
      'daysBeforeReminder': daysBeforeReminder,
    };
  }

  MilestoneNotificationSettings copyWith({
    bool? campaignStarted,
    bool? milestoneCompleted,
    bool? milestoneOverdue,
    bool? payoutReceived,
    bool? campaignUpdates,
    bool? riskAlerts,
    int? daysBeforeReminder,
  }) {
    return MilestoneNotificationSettings(
      campaignStarted: campaignStarted ?? this.campaignStarted,
      milestoneCompleted: milestoneCompleted ?? this.milestoneCompleted,
      milestoneOverdue: milestoneOverdue ?? this.milestoneOverdue,
      payoutReceived: payoutReceived ?? this.payoutReceived,
      campaignUpdates: campaignUpdates ?? this.campaignUpdates,
      riskAlerts: riskAlerts ?? this.riskAlerts,
      daysBeforeReminder: daysBeforeReminder ?? this.daysBeforeReminder,
    );
  }
}

/// Investment preferences and criteria
class InvestmentPreferences {
  final double minInvestmentAmount;
  final double maxInvestmentAmount;
  final List<String> preferredCategories;
  final List<String> preferredRegions;
  final RiskTolerance riskTolerance;
  final InvestmentFocus primaryFocus;
  final int minCampaignDuration; // in days
  final int maxCampaignDuration; // in days
  final double minExpectedROI; // percentage
  final bool requireCertifications;
  final List<String> requiredCertifications;
  final bool autoInvestEnabled;
  final double autoInvestAmount;

  const InvestmentPreferences({
    this.minInvestmentAmount = 0.0,
    this.maxInvestmentAmount = double.infinity,
    this.preferredCategories = const [],
    this.preferredRegions = const [],
    this.riskTolerance = RiskTolerance.moderate,
    this.primaryFocus = InvestmentFocus.returns,
    this.minCampaignDuration = 30,
    this.maxCampaignDuration = 365,
    this.minExpectedROI = 0.0,
    this.requireCertifications = false,
    this.requiredCertifications = const [],
    this.autoInvestEnabled = false,
    this.autoInvestAmount = 0.0,
  });

  factory InvestmentPreferences.fromJson(Map<String, dynamic> json) {
    return InvestmentPreferences(
      minInvestmentAmount: (json['minInvestmentAmount'] as num?)?.toDouble() ?? 0.0,
      maxInvestmentAmount: (json['maxInvestmentAmount'] as num?)?.toDouble() ?? double.infinity,
      preferredCategories: List<String>.from(json['preferredCategories'] as List? ?? []),
      preferredRegions: List<String>.from(json['preferredRegions'] as List? ?? []),
      riskTolerance: RiskTolerance.fromString(json['riskTolerance'] as String? ?? 'Moderate'),
      primaryFocus: InvestmentFocus.fromString(json['primaryFocus'] as String? ?? 'Maximum Returns'),
      minCampaignDuration: json['minCampaignDuration'] as int? ?? 30,
      maxCampaignDuration: json['maxCampaignDuration'] as int? ?? 365,
      minExpectedROI: (json['minExpectedROI'] as num?)?.toDouble() ?? 0.0,
      requireCertifications: json['requireCertifications'] as bool? ?? false,
      requiredCertifications: List<String>.from(json['requiredCertifications'] as List? ?? []),
      autoInvestEnabled: json['autoInvestEnabled'] as bool? ?? false,
      autoInvestAmount: (json['autoInvestAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minInvestmentAmount': minInvestmentAmount,
      'maxInvestmentAmount': maxInvestmentAmount == double.infinity ? null : maxInvestmentAmount,
      'preferredCategories': preferredCategories,
      'preferredRegions': preferredRegions,
      'riskTolerance': riskTolerance.value,
      'primaryFocus': primaryFocus.value,
      'minCampaignDuration': minCampaignDuration,
      'maxCampaignDuration': maxCampaignDuration,
      'minExpectedROI': minExpectedROI,
      'requireCertifications': requireCertifications,
      'requiredCertifications': requiredCertifications,
      'autoInvestEnabled': autoInvestEnabled,
      'autoInvestAmount': autoInvestAmount,
    };
  }

  InvestmentPreferences copyWith({
    double? minInvestmentAmount,
    double? maxInvestmentAmount,
    List<String>? preferredCategories,
    List<String>? preferredRegions,
    RiskTolerance? riskTolerance,
    InvestmentFocus? primaryFocus,
    int? minCampaignDuration,
    int? maxCampaignDuration,
    double? minExpectedROI,
    bool? requireCertifications,
    List<String>? requiredCertifications,
    bool? autoInvestEnabled,
    double? autoInvestAmount,
  }) {
    return InvestmentPreferences(
      minInvestmentAmount: minInvestmentAmount ?? this.minInvestmentAmount,
      maxInvestmentAmount: maxInvestmentAmount ?? this.maxInvestmentAmount,
      preferredCategories: preferredCategories ?? this.preferredCategories,
      preferredRegions: preferredRegions ?? this.preferredRegions,
      riskTolerance: riskTolerance ?? this.riskTolerance,
      primaryFocus: primaryFocus ?? this.primaryFocus,
      minCampaignDuration: minCampaignDuration ?? this.minCampaignDuration,
      maxCampaignDuration: maxCampaignDuration ?? this.maxCampaignDuration,
      minExpectedROI: minExpectedROI ?? this.minExpectedROI,
      requireCertifications: requireCertifications ?? this.requireCertifications,
      requiredCertifications: requiredCertifications ?? this.requiredCertifications,
      autoInvestEnabled: autoInvestEnabled ?? this.autoInvestEnabled,
      autoInvestAmount: autoInvestAmount ?? this.autoInvestAmount,
    );
  }
}

/// Campaign tracking preferences
class CampaignTrackingPreferences {
  final bool trackMilestones;
  final bool trackROI;
  final bool trackRiskChanges;
  final bool trackPayouts;
  final bool receiveWeeklyReports;
  final bool receiveMonthlyReports;
  final bool receiveQuarterlyReports;
  final bool enablePushNotifications;
  final bool enableEmailNotifications;
  final bool enableSMSNotifications;

  const CampaignTrackingPreferences({
    this.trackMilestones = true,
    this.trackROI = true,
    this.trackRiskChanges = true,
    this.trackPayouts = true,
    this.receiveWeeklyReports = false,
    this.receiveMonthlyReports = true,
    this.receiveQuarterlyReports = false,
    this.enablePushNotifications = true,
    this.enableEmailNotifications = true,
    this.enableSMSNotifications = false,
  });

  factory CampaignTrackingPreferences.fromJson(Map<String, dynamic> json) {
    return CampaignTrackingPreferences(
      trackMilestones: json['trackMilestones'] as bool? ?? true,
      trackROI: json['trackROI'] as bool? ?? true,
      trackRiskChanges: json['trackRiskChanges'] as bool? ?? true,
      trackPayouts: json['trackPayouts'] as bool? ?? true,
      receiveWeeklyReports: json['receiveWeeklyReports'] as bool? ?? false,
      receiveMonthlyReports: json['receiveMonthlyReports'] as bool? ?? true,
      receiveQuarterlyReports: json['receiveQuarterlyReports'] as bool? ?? false,
      enablePushNotifications: json['enablePushNotifications'] as bool? ?? true,
      enableEmailNotifications: json['enableEmailNotifications'] as bool? ?? true,
      enableSMSNotifications: json['enableSMSNotifications'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trackMilestones': trackMilestones,
      'trackROI': trackROI,
      'trackRiskChanges': trackRiskChanges,
      'trackPayouts': trackPayouts,
      'receiveWeeklyReports': receiveWeeklyReports,
      'receiveMonthlyReports': receiveMonthlyReports,
      'receiveQuarterlyReports': receiveQuarterlyReports,
      'enablePushNotifications': enablePushNotifications,
      'enableEmailNotifications': enableEmailNotifications,
      'enableSMSNotifications': enableSMSNotifications,
    };
  }

  CampaignTrackingPreferences copyWith({
    bool? trackMilestones,
    bool? trackROI,
    bool? trackRiskChanges,
    bool? trackPayouts,
    bool? receiveWeeklyReports,
    bool? receiveMonthlyReports,
    bool? receiveQuarterlyReports,
    bool? enablePushNotifications,
    bool? enableEmailNotifications,
    bool? enableSMSNotifications,
  }) {
    return CampaignTrackingPreferences(
      trackMilestones: trackMilestones ?? this.trackMilestones,
      trackROI: trackROI ?? this.trackROI,
      trackRiskChanges: trackRiskChanges ?? this.trackRiskChanges,
      trackPayouts: trackPayouts ?? this.trackPayouts,
      receiveWeeklyReports: receiveWeeklyReports ?? this.receiveWeeklyReports,
      receiveMonthlyReports: receiveMonthlyReports ?? this.receiveMonthlyReports,
      receiveQuarterlyReports: receiveQuarterlyReports ?? this.receiveQuarterlyReports,
      enablePushNotifications: enablePushNotifications ?? this.enablePushNotifications,
      enableEmailNotifications: enableEmailNotifications ?? this.enableEmailNotifications,
      enableSMSNotifications: enableSMSNotifications ?? this.enableSMSNotifications,
    );
  }
}

/// User preferences model for the Poligrain app
class UserPreferences {
  final String userId;
  final ThemePreference theme;
  final LanguagePreference language;
  final CurrencyPreference currency;
  final NotificationPreference notifications;
  final MilestoneNotificationSettings milestoneNotifications;
  final InvestmentPreferences investmentPreferences;
  final CampaignTrackingPreferences trackingPreferences;
  final bool enableBiometricAuth;
  final bool enableTwoFactorAuth;
  final bool shareAnalytics;
  final bool receiveMarketingEmails;
  final Map<String, dynamic>? customSettings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserPreferences({
    required this.userId,
    this.theme = ThemePreference.system,
    this.language = LanguagePreference.english,
    this.currency = CurrencyPreference.usd,
    this.notifications = NotificationPreference.important,
    this.milestoneNotifications = const MilestoneNotificationSettings(),
    this.investmentPreferences = const InvestmentPreferences(),
    this.trackingPreferences = const CampaignTrackingPreferences(),
    this.enableBiometricAuth = false,
    this.enableTwoFactorAuth = false,
    this.shareAnalytics = true,
    this.receiveMarketingEmails = false,
    this.customSettings,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create UserPreferences from JSON
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userId: json['userId'] as String,
      theme: ThemePreference.fromString(json['theme'] as String? ?? 'System'),
      language: LanguagePreference.fromString(json['language'] as String? ?? 'English'),
      currency: CurrencyPreference.fromString(json['currency'] as String? ?? 'USD'),
      notifications: NotificationPreference.fromString(json['notifications'] as String? ?? 'Important Only'),
      milestoneNotifications: json['milestoneNotifications'] != null
          ? MilestoneNotificationSettings.fromJson(json['milestoneNotifications'] as Map<String, dynamic>)
          : const MilestoneNotificationSettings(),
      investmentPreferences: json['investmentPreferences'] != null
          ? InvestmentPreferences.fromJson(json['investmentPreferences'] as Map<String, dynamic>)
          : const InvestmentPreferences(),
      trackingPreferences: json['trackingPreferences'] != null
          ? CampaignTrackingPreferences.fromJson(json['trackingPreferences'] as Map<String, dynamic>)
          : const CampaignTrackingPreferences(),
      enableBiometricAuth: json['enableBiometricAuth'] as bool? ?? false,
      enableTwoFactorAuth: json['enableTwoFactorAuth'] as bool? ?? false,
      shareAnalytics: json['shareAnalytics'] as bool? ?? true,
      receiveMarketingEmails: json['receiveMarketingEmails'] as bool? ?? false,
      customSettings: json['customSettings'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert UserPreferences to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'theme': theme.value,
      'language': language.value,
      'currency': currency.value,
      'notifications': notifications.value,
      'milestoneNotifications': milestoneNotifications.toJson(),
      'investmentPreferences': investmentPreferences.toJson(),
      'trackingPreferences': trackingPreferences.toJson(),
      'enableBiometricAuth': enableBiometricAuth,
      'enableTwoFactorAuth': enableTwoFactorAuth,
      'shareAnalytics': shareAnalytics,
      'receiveMarketingEmails': receiveMarketingEmails,
      if (customSettings != null) 'customSettings': customSettings,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  UserPreferences copyWith({
    String? userId,
    ThemePreference? theme,
    LanguagePreference? language,
    CurrencyPreference? currency,
    NotificationPreference? notifications,
    MilestoneNotificationSettings? milestoneNotifications,
    InvestmentPreferences? investmentPreferences,
    CampaignTrackingPreferences? trackingPreferences,
    bool? enableBiometricAuth,
    bool? enableTwoFactorAuth,
    bool? shareAnalytics,
    bool? receiveMarketingEmails,
    Map<String, dynamic>? customSettings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPreferences(
      userId: userId ?? this.userId,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      currency: currency ?? this.currency,
      notifications: notifications ?? this.notifications,
      milestoneNotifications: milestoneNotifications ?? this.milestoneNotifications,
      investmentPreferences: investmentPreferences ?? this.investmentPreferences,
      trackingPreferences: trackingPreferences ?? this.trackingPreferences,
      enableBiometricAuth: enableBiometricAuth ?? this.enableBiometricAuth,
      enableTwoFactorAuth: enableTwoFactorAuth ?? this.enableTwoFactorAuth,
      shareAnalytics: shareAnalytics ?? this.shareAnalytics,
      receiveMarketingEmails: receiveMarketingEmails ?? this.receiveMarketingEmails,
      customSettings: customSettings ?? this.customSettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get default preferences for new users
  static UserPreferences defaultPreferences(String userId) {
    final now = DateTime.now();
    return UserPreferences(
      userId: userId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Check if user wants milestone notifications
  bool shouldReceiveMilestoneNotifications() {
    return notifications != NotificationPreference.none &&
           trackingPreferences.trackMilestones;
  }

  /// Check if user wants campaign update notifications
  bool shouldReceiveCampaignUpdates() {
    return notifications != NotificationPreference.none &&
           milestoneNotifications.campaignUpdates;
  }

  /// Check if user wants payout notifications
  bool shouldReceivePayoutNotifications() {
    return notifications != NotificationPreference.none &&
           milestoneNotifications.payoutReceived;
  }

  /// Check if user wants risk alert notifications
  bool shouldReceiveRiskAlerts() {
    return notifications != NotificationPreference.none &&
           milestoneNotifications.riskAlerts;
  }

  /// Get enabled notification channels
  List<String> getEnabledNotificationChannels() {
    final channels = <String>[];
    
    if (trackingPreferences.enablePushNotifications) {
      channels.add('push');
    }
    if (trackingPreferences.enableEmailNotifications) {
      channels.add('email');
    }
    if (trackingPreferences.enableSMSNotifications) {
      channels.add('sms');
    }
    
    return channels;
  }

  @override
  String toString() {
    return 'UserPreferences(userId: $userId, theme: ${theme.value}, notifications: ${notifications.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserPreferences && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
