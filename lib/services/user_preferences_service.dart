import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../models/user_preferences.dart';

/// Service for managing user preferences
class UserPreferencesService {
  static const String _apiName = 'PoligrainAPI';
  static const String _cacheKey = 'user_preferences_cache';
  
  UserPreferences? _cachedPreferences;

  /// Get user preferences
  Future<UserPreferences> getUserPreferences([String? userId]) async {
    try {
      // Use cached preferences if available and no specific userId requested
      if (_cachedPreferences != null && userId == null) {
        return _cachedPreferences!;
      }

      final endpoint = userId != null 
          ? '/users/$userId/preferences'
          : '/user/preferences';

      final response = await Amplify.API
          .get(endpoint, apiName: _apiName)
          .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode == 404) {
        // Create default preferences if none exist
        final currentUser = await Amplify.Auth.getCurrentUser();
        final defaultPrefs = UserPreferences.defaultPreferences(
          userId ?? currentUser.userId,
        );
        return await createUserPreferences(defaultPrefs);
      }

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw Exception(
          'Failed to fetch user preferences: ${errorBody['error'] ?? 'Unknown error'}',
        );
      }

      final preferencesData = json.decode(responseBody) as Map<String, dynamic>;
      final preferences = UserPreferences.fromJson(preferencesData);
      
      // Cache preferences if it's for current user
      if (userId == null) {
        _cachedPreferences = preferences;
      }
      
      return preferences;
    } catch (e) {
      throw Exception('Failed to fetch user preferences: $e');
    }
  }

  /// Create new user preferences
  Future<UserPreferences> createUserPreferences(UserPreferences preferences) async {
    try {
      final requestBody = preferences.toJson();

      final response = await Amplify.API
          .post(
            '/user/preferences',
            apiName: _apiName,
            body: HttpPayload.json(requestBody),
          )
          .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw Exception(
          'Failed to create user preferences: ${errorBody['error'] ?? 'Unknown error'}',
        );
      }

      final preferencesData = json.decode(responseBody) as Map<String, dynamic>;
      final createdPreferences = UserPreferences.fromJson(preferencesData);
      
      // Cache the new preferences
      _cachedPreferences = createdPreferences;
      
      return createdPreferences;
    } catch (e) {
      throw Exception('Failed to create user preferences: $e');
    }
  }

  /// Update user preferences
  Future<UserPreferences> updateUserPreferences(UserPreferences preferences) async {
    try {
      final requestBody = preferences.toJson();
      requestBody['updatedAt'] = DateTime.now().toIso8601String();

      final response = await Amplify.API
          .put(
            '/user/preferences',
            apiName: _apiName,
            body: HttpPayload.json(requestBody),
          )
          .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw Exception(
          'Failed to update user preferences: ${errorBody['error'] ?? 'Unknown error'}',
        );
      }

      final preferencesData = json.decode(responseBody) as Map<String, dynamic>;
      final updatedPreferences = UserPreferences.fromJson(preferencesData);
      
      // Update cache
      _cachedPreferences = updatedPreferences;
      
      return updatedPreferences;
    } catch (e) {
      throw Exception('Failed to update user preferences: $e');
    }
  }

  /// Update specific preference sections
  Future<UserPreferences> updateThemePreference(ThemePreference theme) async {
    final currentPrefs = await getUserPreferences();
    final updatedPrefs = currentPrefs.copyWith(theme: theme);
    return await updateUserPreferences(updatedPrefs);
  }

  Future<UserPreferences> updateLanguagePreference(LanguagePreference language) async {
    final currentPrefs = await getUserPreferences();
    final updatedPrefs = currentPrefs.copyWith(language: language);
    return await updateUserPreferences(updatedPrefs);
  }

  Future<UserPreferences> updateCurrencyPreference(CurrencyPreference currency) async {
    final currentPrefs = await getUserPreferences();
    final updatedPrefs = currentPrefs.copyWith(currency: currency);
    return await updateUserPreferences(updatedPrefs);
  }

  Future<UserPreferences> updateNotificationPreference(NotificationPreference notifications) async {
    final currentPrefs = await getUserPreferences();
    final updatedPrefs = currentPrefs.copyWith(notifications: notifications);
    return await updateUserPreferences(updatedPrefs);
  }

  Future<UserPreferences> updateMilestoneNotifications(MilestoneNotificationSettings settings) async {
    final currentPrefs = await getUserPreferences();
    final updatedPrefs = currentPrefs.copyWith(milestoneNotifications: settings);
    return await updateUserPreferences(updatedPrefs);
  }

  Future<UserPreferences> updateInvestmentPreferences(InvestmentPreferences preferences) async {
    final currentPrefs = await getUserPreferences();
    final updatedPrefs = currentPrefs.copyWith(investmentPreferences: preferences);
    return await updateUserPreferences(updatedPrefs);
  }

  Future<UserPreferences> updateTrackingPreferences(CampaignTrackingPreferences preferences) async {
    final currentPrefs = await getUserPreferences();
    final updatedPrefs = currentPrefs.copyWith(trackingPreferences: preferences);
    return await updateUserPreferences(updatedPrefs);
  }

  /// Toggle specific settings
  Future<UserPreferences> toggleBiometricAuth() async {
    final currentPrefs = await getUserPreferences();
    final updatedPrefs = currentPrefs.copyWith(
      enableBiometricAuth: !currentPrefs.enableBiometricAuth,
    );
    return await updateUserPreferences(updatedPrefs);
  }

  Future<UserPreferences> toggleTwoFactorAuth() async {
    final currentPrefs = await getUserPreferences();
    final updatedPrefs = currentPrefs.copyWith(
      enableTwoFactorAuth: !currentPrefs.enableTwoFactorAuth,
    );
    return await updateUserPreferences(updatedPrefs);
  }

  Future<UserPreferences> toggleAnalyticsSharing() async {
    final currentPrefs = await getUserPreferences();
    final updatedPrefs = currentPrefs.copyWith(
      shareAnalytics: !currentPrefs.shareAnalytics,
    );
    return await updateUserPreferences(updatedPrefs);
  }

  Future<UserPreferences> toggleMarketingEmails() async {
    final currentPrefs = await getUserPreferences();
    final updatedPrefs = currentPrefs.copyWith(
      receiveMarketingEmails: !currentPrefs.receiveMarketingEmails,
    );
    return await updateUserPreferences(updatedPrefs);
  }

  /// Bulk update preferences
  Future<UserPreferences> updateMultiplePreferences({
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
  }) async {
    final currentPrefs = await getUserPreferences();
    final updatedPrefs = currentPrefs.copyWith(
      theme: theme,
      language: language,
      currency: currency,
      notifications: notifications,
      milestoneNotifications: milestoneNotifications,
      investmentPreferences: investmentPreferences,
      trackingPreferences: trackingPreferences,
      enableBiometricAuth: enableBiometricAuth,
      enableTwoFactorAuth: enableTwoFactorAuth,
      shareAnalytics: shareAnalytics,
      receiveMarketingEmails: receiveMarketingEmails,
      customSettings: customSettings,
    );
    return await updateUserPreferences(updatedPrefs);
  }

  /// Reset preferences to defaults
  Future<UserPreferences> resetToDefaults() async {
    final currentPrefs = await getUserPreferences();
    final defaultPrefs = UserPreferences.defaultPreferences(currentPrefs.userId);
    return await updateUserPreferences(defaultPrefs);
  }

  /// Clear cache
  void clearCache() {
    _cachedPreferences = null;
  }

  /// Check if preferences match investment criteria
  bool doesCampaignMatchPreferences(Map<String, dynamic> campaign, UserPreferences preferences) {
    final investmentPrefs = preferences.investmentPreferences;
    
    // Check minimum investment amount
    final minInvestment = campaign['minimumInvestment'] as double? ?? 0.0;
    if (minInvestment < investmentPrefs.minInvestmentAmount || 
        minInvestment > investmentPrefs.maxInvestmentAmount) {
      return false;
    }

    // Check preferred categories
    if (investmentPrefs.preferredCategories.isNotEmpty) {
      final category = campaign['category'] as String? ?? '';
      if (!investmentPrefs.preferredCategories.contains(category)) {
        return false;
      }
    }

    // Check expected ROI
    final expectedROI = campaign['expectedROI'] as double? ?? 0.0;
    if (expectedROI < investmentPrefs.minExpectedROI) {
      return false;
    }

    // Check campaign duration
    final startDate = DateTime.parse(campaign['startDate'] as String);
    final endDate = DateTime.parse(campaign['endDate'] as String);
    final duration = endDate.difference(startDate).inDays;
    
    if (duration < investmentPrefs.minCampaignDuration || 
        duration > investmentPrefs.maxCampaignDuration) {
      return false;
    }

    return true;
  }

  /// Get matching campaigns based on user preferences
  Future<List<Map<String, dynamic>>> getRecommendedCampaigns() async {
    try {
      final preferences = await getUserPreferences();
      
      final response = await Amplify.API
          .post(
            '/campaigns/recommendations',
            apiName: _apiName,
            body: HttpPayload.json({
              'investmentPreferences': preferences.investmentPreferences.toJson(),
              'riskTolerance': preferences.investmentPreferences.riskTolerance.value,
              'primaryFocus': preferences.investmentPreferences.primaryFocus.value,
            }),
          )
          .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw Exception(
          'Failed to get recommendations: ${errorBody['error'] ?? 'Unknown error'}',
        );
      }

      final responseData = json.decode(responseBody) as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(responseData['campaigns'] as List);
    } catch (e) {
      throw Exception('Failed to get recommended campaigns: $e');
    }
  }

  /// Update custom setting
  Future<UserPreferences> updateCustomSetting(String key, dynamic value) async {
    final currentPrefs = await getUserPreferences();
    final customSettings = Map<String, dynamic>.from(currentPrefs.customSettings ?? {});
    customSettings[key] = value;
    
    final updatedPrefs = currentPrefs.copyWith(customSettings: customSettings);
    return await updateUserPreferences(updatedPrefs);
  }

  /// Remove custom setting
  Future<UserPreferences> removeCustomSetting(String key) async {
    final currentPrefs = await getUserPreferences();
    final customSettings = Map<String, dynamic>.from(currentPrefs.customSettings ?? {});
    customSettings.remove(key);
    
    final updatedPrefs = currentPrefs.copyWith(customSettings: customSettings);
    return await updateUserPreferences(updatedPrefs);
  }

  /// Export preferences as JSON string
  Future<String> exportPreferences() async {
    final preferences = await getUserPreferences();
    return json.encode(preferences.toJson());
  }

  /// Import preferences from JSON string
  Future<UserPreferences> importPreferences(String jsonString) async {
    try {
      final preferencesData = json.decode(jsonString) as Map<String, dynamic>;
      final currentUser = await Amplify.Auth.getCurrentUser();
      
      // Ensure the userId matches current user
      preferencesData['userId'] = currentUser.userId;
      preferencesData['updatedAt'] = DateTime.now().toIso8601String();
      
      final preferences = UserPreferences.fromJson(preferencesData);
      return await updateUserPreferences(preferences);
    } catch (e) {
      throw Exception('Failed to import preferences: $e');
    }
  }
}
