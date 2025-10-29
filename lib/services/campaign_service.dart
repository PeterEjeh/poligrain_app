import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poligrain_app/models/campaign.dart';
import 'package:poligrain_app/models/campaign_enum.dart';
import 'package:poligrain_app/exceptions/campaign_exceptions.dart';

/// Service class for handling campaign-related operations
class CampaignService {
  static const String _apiBaseUrl = 'https://22913m3uxj.execute-api.us-east-1.amazonaws.com/dev';
  static const Duration _timeout = Duration(seconds: 30);
  static const String _cachePrefix = 'campaign_cache_';

  static final CampaignService _instance = CampaignService._internal();
  factory CampaignService() => _instance;
  CampaignService._internal();

  /// Get authentication headers for API requests
  Future<Map<String, String>> _getAuthHeaders() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        throw CampaignException.auth('User not authenticated');
      }
      
      final cognitoSession = session as CognitoAuthSession;
      final token = cognitoSession.userPoolTokensResult.value.idToken.raw;

      return {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
    } on AmplifyException catch (e) {
      throw CampaignException.auth('Authentication failed: ${e.message}');
    } catch (e) {
      throw CampaignException.auth('Failed to get authentication token: $e');
    }
  }

  /// Check network connectivity
  Future<bool> _isConnected() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Cache data locally with TTL
  Future<void> _cacheData(String key, Map<String, dynamic> data, {int ttlMinutes = 15}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'ttl': ttlMinutes * 60 * 1000, // Convert to milliseconds
      };
      await prefs.setString('$_cachePrefix$key', jsonEncode(cacheData));
    } catch (e) {
      safePrint('Failed to cache data: $e');
    }
  }

  /// Get cached data if still valid
  Future<Map<String, dynamic>?> _getCachedData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedDataString = prefs.getString('$_cachePrefix$key');

      if (cachedDataString == null) return null;

      final cacheData = jsonDecode(cachedDataString) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final ttl = cacheData['ttl'] as int;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // Check if cache is still valid
      if (currentTime - timestamp > ttl) {
        await prefs.remove('$_cachePrefix$key');
        return null;
      }

      return cacheData['data'] as Map<String, dynamic>;
    } catch (e) {
      safePrint('Failed to get cached data: $e');
      return null;
    }
  }

  /// Cache campaigns list with TTL
  Future<void> _cacheCampaignsList(String key, List<Campaign> campaigns, {int ttlMinutes = 15}) async {
    try {
      final campaignData = campaigns.map((c) => c.toJson()).toList();
      await _cacheData(key, {'campaigns': campaignData}, ttlMinutes: ttlMinutes);
    } catch (e) {
      safePrint('Failed to cache campaigns: $e');
    }
  }

  /// Get cached campaigns list
  Future<List<Campaign>?> _getCachedCampaignsList(String key) async {
    try {
      final cachedData = await _getCachedData(key);
      if (cachedData == null) return null;

      final campaignsList = cachedData['campaigns'] as List<dynamic>;
      return campaignsList
          .map((data) => Campaign.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      safePrint('Failed to get cached campaigns: $e');
      return null;
    }
  }

  /// Make authenticated API request using Amplify.API
  Future<Map<String, dynamic>> _makeApiRequest(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    int maxRetries = 3,
  }) async {
    if (!await _isConnected()) {
      throw CampaignException.network('No internet connection');
    }

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        AWSHttpResponse response;
        
        // Build query string if parameters provided
        String fullPath = path;
        if (queryParameters != null && queryParameters.isNotEmpty) {
          final queryString = queryParameters.entries
              .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
              .join('&');
          fullPath = '$path?$queryString';
        }

        switch (method.toUpperCase()) {
          case 'GET':
            response = await Amplify.API.get(fullPath).response;
            break;
          case 'POST':
            response = await Amplify.API
                .post(fullPath, body: body != null ? HttpPayload.json(body) : null)
                .response;
            break;
          case 'PUT':
            response = await Amplify.API
                .put(fullPath, body: body != null ? HttpPayload.json(body) : null)
                .response;
            break;
          case 'DELETE':
            response = await Amplify.API.delete(fullPath).response;
            break;
          default:
            throw CampaignException('Unsupported HTTP method: $method');
        }

        // Check response status
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final responseBody = await response.decodeBody();
          if (responseBody.isEmpty) {
            return {}; // Return empty map for successful requests with no body
          }
          return jsonDecode(responseBody) as Map<String, dynamic>;
        }

        // Handle specific error status codes
        await _handleErrorResponse(response, attempt, maxRetries);

      } on TimeoutException {
        if (attempt >= maxRetries) {
          throw CampaignException.timeout('Request timed out after $maxRetries attempts');
        }
        await _delayForRetry(attempt);
      } on SocketException {
        if (attempt >= maxRetries) {
          throw CampaignException.network('Network connection failed after $maxRetries attempts');
        }
        await _delayForRetry(attempt);
      } on AmplifyException catch (e) {
        if (e.message.contains('Authorization') || e.message.contains('Unauthorized')) {
          throw CampaignException.auth('Authentication failed: ${e.message}');
        }
        if (attempt >= maxRetries) {
          throw CampaignException.server('API error: ${e.message}');
        }
        await _delayForRetry(attempt);
      } catch (e) {
        if (attempt >= maxRetries) {
          throw CampaignException('Request failed: $e');
        }
        await _delayForRetry(attempt);
      }
    }

    throw CampaignException('Max retries exceeded');
  }

  /// Handle error responses from API
  Future<void> _handleErrorResponse(AWSHttpResponse response, int attempt, int maxRetries) async {
    final statusCode = response.statusCode;
    
    try {
      final responseBody = await response.decodeBody();
      final errorData = responseBody.isNotEmpty 
          ? jsonDecode(responseBody) as Map<String, dynamic>? 
          : null;
      final errorMessage = errorData?['message'] ?? 'Request failed';

      switch (statusCode) {
        case 401:
          throw CampaignException.auth('Authentication failed: $errorMessage');
        case 403:
          throw CampaignException.permission('Access denied: $errorMessage');
        case 404:
          throw CampaignException.notFound('Resource not found: $errorMessage');
        case 400:
          throw CampaignException.validation(errorMessage);
        case 429:
          if (attempt < maxRetries) {
            await _delayForRetry(attempt * 2); // Longer delay for rate limiting
            return; // Continue retry loop
          }
          throw CampaignException.server('Rate limit exceeded');
        default:
          if (statusCode >= 500) {
            if (attempt < maxRetries) {
              await _delayForRetry(attempt);
              return; // Continue retry loop
            }
            throw CampaignException.server('Server error: $errorMessage');
          }
          throw CampaignException('HTTP error $statusCode: $errorMessage');
      }
    } catch (CampaignException) {
      rethrow;
    } catch (e) {
      throw CampaignException('Error processing response: $e');
    }
  }

  /// Delay for retry with exponential backoff
  Future<void> _delayForRetry(int attempt) async {
    await Future.delayed(Duration(seconds: attempt * 2));
  }

  /// Create a new campaign
  Future<Campaign> createCampaign(Campaign campaign) async {
    try {
      // Validate campaign data before sending
      final validationErrors = campaign.validate();
      if (validationErrors.isNotEmpty) {
        throw CampaignException.validation(
          'Validation failed: ${validationErrors.join(', ')}',
          details: validationErrors,
        );
      }

      final responseData = await _makeApiRequest(
        '/campaigns',
        method: 'POST',
        body: campaign.toJson(),
      );

      final createdCampaign = Campaign.fromJson(responseData);
      
      // Cache the created campaign
      await _cacheData('campaign_${createdCampaign.id}', responseData);
      
      // Invalidate campaigns list cache
      await _invalidateListCache();

      return createdCampaign;
    } catch (e) {
      throw CampaignExceptionHandler.handleException(e);
    }
  }

  /// Get campaigns with filtering and caching
  Future<List<Campaign>> getCampaigns({
    CampaignStatus? status,
    CampaignType? type,
    String? category,
    int? limit,
    String? cursor,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'campaigns_${status}_${type}_${category}_${limit}_$cursor';

    // Try cache first if not forcing refresh
    if (!forceRefresh) {
      final cached = await _getCachedCampaignsList(cacheKey);
      if (cached != null) {
        return cached;
      }
    }

    // If offline, try cache regardless of forceRefresh
    if (!await _isConnected()) {
      final cached = await _getCachedCampaignsList(cacheKey);
      if (cached != null) {
        return cached;
      }
      throw CampaignException.network('No internet connection and no cached data available');
    }

    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status.toString().split('.').last;
      if (type != null) queryParams['type'] = type.toString().split('.').last;
      if (category != null) queryParams['category'] = category;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (cursor != null) queryParams['cursor'] = cursor;

      final responseData = await _makeApiRequest(
        '/campaigns',
        queryParameters: queryParams,
      );

      final campaignsList = responseData['campaigns'] as List<dynamic>? ?? 
          responseData['items'] as List<dynamic>? ?? [];

      final campaigns = campaignsList
          .map((campaignJson) => Campaign.fromJson(campaignJson as Map<String, dynamic>))
          .toList();

      // Cache the results
      await _cacheCampaignsList(cacheKey, campaigns);

      return campaigns;
    } catch (e) {
      throw CampaignExceptionHandler.handleException(e);
    }
  }

  /// Get a single campaign by ID
  Future<Campaign> getCampaign(String id, {bool forceRefresh = false}) async {
    if (id.isEmpty) {
      throw CampaignException.validation('Campaign ID cannot be empty');
    }

    final cacheKey = 'campaign_$id';

    // Try cache first
    if (!forceRefresh) {
      final cached = await _getCachedData(cacheKey);
      if (cached != null) {
        return Campaign.fromJson(cached);
      }
    }

    // If offline, try cache
    if (!await _isConnected()) {
      final cached = await _getCachedData(cacheKey);
      if (cached != null) {
        return Campaign.fromJson(cached);
      }
      throw CampaignException.network('No internet connection and no cached data available');
    }

    try {
      final responseData = await _makeApiRequest('/campaigns/$id');
      final campaign = Campaign.fromJson(responseData);

      // Cache the campaign
      await _cacheData(cacheKey, responseData);

      return campaign;
    } catch (e) {
      throw CampaignExceptionHandler.handleException(e);
    }
  }

  /// Update an existing campaign
  Future<Campaign> updateCampaign(String id, Campaign campaign) async {
    if (id.isEmpty) {
      throw CampaignException.validation('Campaign ID cannot be empty');
    }

    try {
      // Validate campaign data
      final validationErrors = campaign.validate();
      if (validationErrors.isNotEmpty) {
        throw CampaignException.validation(
          'Validation failed: ${validationErrors.join(', ')}',
          details: validationErrors,
        );
      }

      final responseData = await _makeApiRequest(
        '/campaigns/$id',
        method: 'PUT',
        body: campaign.toJson(),
      );

      final updatedCampaign = Campaign.fromJson(responseData);

      // Update cache
      await _cacheData('campaign_$id', responseData);
      
      // Invalidate campaigns list cache
      await _invalidateListCache();

      return updatedCampaign;
    } catch (e) {
      throw CampaignExceptionHandler.handleException(e);
    }
  }

  /// Delete a campaign
  Future<void> deleteCampaign(String id) async {
    if (id.isEmpty) {
      throw CampaignException.validation('Campaign ID cannot be empty');
    }

    try {
      await _makeApiRequest('/campaigns/$id', method: 'DELETE');

      // Remove from cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_cachePrefix}campaign_$id');
      
      // Invalidate campaigns list cache
      await _invalidateListCache();
    } catch (e) {
      throw CampaignExceptionHandler.handleException(e);
    }
  }

  /// Search campaigns with advanced filtering
  Future<List<Campaign>> searchCampaigns({
    String? query,
    List<String>? categories,
    double? minAmount,
    double? maxAmount,
    CampaignStatus? status,
    String? sortBy = 'created_at',
    String? sortOrder = 'desc',
    int? limit = 20,
    String? cursor,
  }) async {
    try {
      final searchParams = <String, dynamic>{};
      if (query != null && query.isNotEmpty) searchParams['q'] = query;
      if (categories != null && categories.isNotEmpty) searchParams['categories'] = categories;
      if (minAmount != null) searchParams['min_amount'] = minAmount;
      if (maxAmount != null) searchParams['max_amount'] = maxAmount;
      if (status != null) searchParams['status'] = status.toString().split('.').last;
      if (sortBy != null) searchParams['sort_by'] = sortBy;
      if (sortOrder != null) searchParams['sort_order'] = sortOrder;
      if (limit != null) searchParams['limit'] = limit;
      if (cursor != null) searchParams['cursor'] = cursor;

      final responseData = await _makeApiRequest(
        '/campaigns/search',
        method: 'POST',
        body: searchParams,
      );

      final campaignsList = responseData['campaigns'] as List<dynamic>? ?? 
          responseData['items'] as List<dynamic>? ?? [];

      return campaignsList
          .map((campaignJson) => Campaign.fromJson(campaignJson as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw CampaignExceptionHandler.handleException(e);
    }
  }

  /// Get trending campaigns
  Future<List<Campaign>> getTrendingCampaigns({int limit = 10}) async {
    final cacheKey = 'trending_campaigns_$limit';

    // Try cache with shorter TTL for trending data
    final cached = await _getCachedCampaignsList(cacheKey);
    if (cached != null) {
      return cached;
    }

    // If offline, try cache
    if (!await _isConnected()) {
      final cachedData = await _getCachedData(cacheKey);
      if (cachedData != null) {
        final campaignsList = cachedData['campaigns'] as List<dynamic>;
        return campaignsList
            .map((data) => Campaign.fromJson(data as Map<String, dynamic>))
            .toList();
      }
      throw CampaignException.network('No internet connection and no cached data available');
    }

    try {
      final responseData = await _makeApiRequest(
        '/campaigns/trending',
        queryParameters: {'limit': limit.toString()},
      );

      final campaignsList = responseData['campaigns'] as List<dynamic>? ?? 
          responseData['items'] as List<dynamic>? ?? [];

      final campaigns = campaignsList
          .map((campaignJson) => Campaign.fromJson(campaignJson as Map<String, dynamic>))
          .toList();

      // Cache with shorter TTL for trending data (5 minutes)
      await _cacheCampaignsList(cacheKey, campaigns, ttlMinutes: 5);

      return campaigns;
    } catch (e) {
      throw CampaignExceptionHandler.handleException(e);
    }
  }

  /// Get user dashboard data
  Future<Map<String, dynamic>> getUserDashboardData() async {
    const cacheKey = 'user_dashboard';

    // Try cache first
    final cached = await _getCachedData(cacheKey);
    if (cached != null) {
      return cached;
    }

    try {
      final responseData = await _makeApiRequest('/user/dashboard');
      
      // Cache dashboard data for 10 minutes
      await _cacheData(cacheKey, responseData, ttlMinutes: 10);
      
      return responseData;
    } catch (e) {
      throw CampaignExceptionHandler.handleException(e);
    }
  }

  /// Get campaigns by owner (filtered by authenticated user on backend)
  Future<List<Campaign>> getCampaignsByOwner(String ownerId) async {
    if (ownerId.isEmpty) {
      throw CampaignException.validation('Owner ID cannot be empty');
    }

    try {
      final responseData = await _makeApiRequest(
        '/campaigns/by-owner',
        queryParameters: {'ownerId': ownerId},
      );

      final campaignsList = responseData['campaigns'] as List<dynamic>? ?? 
          responseData['items'] as List<dynamic>? ?? [];

      return campaignsList
          .map((campaignJson) => Campaign.fromJson(campaignJson as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw CampaignExceptionHandler.handleException(e);
    }
  }

  /// Get campaign analytics
  Future<Map<String, dynamic>> getCampaignAnalytics(String campaignId) async {
    if (campaignId.isEmpty) {
      throw CampaignException.validation('Campaign ID cannot be empty');
    }

    try {
      return await _makeApiRequest('/campaigns/$campaignId/analytics');
    } catch (e) {
      throw CampaignExceptionHandler.handleException(e);
    }
  }

  /// Clear all cached data
  Future<void> _invalidateCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final cacheKeys = keys.where((key) => key.startsWith(_cachePrefix));

      for (final key in cacheKeys) {
        await prefs.remove(key);
      }
    } catch (e) {
      safePrint('Failed to invalidate cache: $e');
    }
  }

  /// Clear campaigns list cache (when data changes)
  Future<void> _invalidateListCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final listCacheKeys = keys.where((key) => 
          key.startsWith(_cachePrefix) && 
          (key.contains('campaigns_') || key.contains('trending_') || key.contains('user_dashboard')));

      for (final key in listCacheKeys) {
        await prefs.remove(key);
      }
    } catch (e) {
      safePrint('Failed to invalidate list cache: $e');
    }
  }

  /// Clear specific cache entry
  Future<void> clearCache({String? specificKey}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (specificKey != null) {
        await prefs.remove('$_cachePrefix$specificKey');
      } else {
        await _invalidateCache();
      }
    } catch (e) {
      safePrint('Failed to clear cache: $e');
    }
  }

  /// Get cache statistics for debugging
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final cacheKeys = keys.where((key) => key.startsWith(_cachePrefix)).toList();

      int totalEntries = cacheKeys.length;
      int expiredEntries = 0;
      int totalSize = 0;

      for (final key in cacheKeys) {
        final data = prefs.getString(key);
        if (data != null) {
          totalSize += data.length;
          try {
            final cacheData = jsonDecode(data) as Map<String, dynamic>;
            final timestamp = cacheData['timestamp'] as int;
            final ttl = cacheData['ttl'] as int;
            final currentTime = DateTime.now().millisecondsSinceEpoch;

            if (currentTime - timestamp > ttl) {
              expiredEntries++;
            }
          } catch (e) {
            expiredEntries++;
          }
        }
      }

      return {
        'totalEntries': totalEntries,
        'expiredEntries': expiredEntries,
        'activeEntries': totalEntries - expiredEntries,
        'totalSizeBytes': totalSize,
        'totalSizeKB': (totalSize / 1024).round(),
      };
    } catch (e) {
      return {
        'totalEntries': 0,
        'expiredEntries': 0,
        'activeEntries': 0,
        'totalSizeBytes': 0,
        'totalSizeKB': 0,
        'error': e.toString(),
      };
    }
  }

  /// Clean up expired cache entries
  Future<void> cleanupExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final cacheKeys = keys.where((key) => key.startsWith(_cachePrefix)).toList();
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      for (final key in cacheKeys) {
        final data = prefs.getString(key);
        if (data != null) {
          try {
            final cacheData = jsonDecode(data) as Map<String, dynamic>;
            final timestamp = cacheData['timestamp'] as int;
            final ttl = cacheData['ttl'] as int;

            if (currentTime - timestamp > ttl) {
              await prefs.remove(key);
            }
          } catch (e) {
            // If we can't parse the cache data, remove it
            await prefs.remove(key);
          }
        }
      }
    } catch (e) {
      safePrint('Failed to cleanup expired cache: $e');
    }
  }

  /// Preload common data for better UX
  Future<void> preloadCommonData() async {
    if (!await _isConnected()) {
      return; // Skip preloading if offline
    }

    try {
      // Preload trending campaigns and user dashboard in parallel
      await Future.wait([
        getTrendingCampaigns(limit: 5),
        getUserDashboardData(),
      ]);
    } catch (e) {
      // Preloading failures shouldn't break the app
      safePrint('Failed to preload common data: $e');
    }
  }

  /// Refresh user-specific data
  Future<void> refreshUserData() async {
    try {
      // Clear user-specific caches and reload
      await clearCache(specificKey: 'user_dashboard');
      
      // Get campaigns for current user (force refresh)
      await getCampaigns(forceRefresh: true);
      await getUserDashboardData();
    } catch (e) {
      throw CampaignExceptionHandler.handleException(e);
    }
  }

  /// Get offline capabilities status
  Map<String, dynamic> getOfflineCapabilities() {
    return {
      'canViewCachedCampaigns': true,
      'canCreateCampaigns': false,
      'canUpdateCampaigns': false,
      'canDeleteCampaigns': false,
      'canSearchCampaigns': false,
      'canViewAnalytics': false,
      'cacheTtlMinutes': 15,
      'supportedOperations': [
        'getCampaigns (cached)',
        'getCampaign (cached)',
        'getTrendingCampaigns (cached)',
        'getUserDashboardData (cached)',
      ],
    };
  }

  /// Health check for the service
  Future<Map<String, dynamic>> healthCheck() async {
    final result = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'connectivity': await _isConnected(),
      'authentication': false,
      'apiReachable': false,
      'cacheStats': await getCacheStats(),
    };

    try {
      // Check authentication
      await _getAuthHeaders();
      result['authentication'] = true;
    } catch (e) {
      result['authError'] = e.toString();
    }

    try {
      // Check API reachability with a simple request
      if (result['connectivity'] && result['authentication']) {
        await _makeApiRequest('/health', method: 'GET');
        result['apiReachable'] = true;
      }
    } catch (e) {
      result['apiError'] = e.toString();
    }

    return result;
  }

  /// Initialize service (call this when app starts)
  Future<void> initialize() async {
    try {
      // Clean up expired cache on startup
      await cleanupExpiredCache();
      
      // Preload common data if connected
      if (await _isConnected()) {
        unawaited(preloadCommonData());
      }
    } catch (e) {
      safePrint('Failed to initialize CampaignService: $e');
    }
  }

  /// Dispose resources (call when app shuts down)
  void dispose() {
    // Nothing to dispose in this implementation
    // The singleton pattern means this instance will persist
  }
}

/// Extension for unawaited futures (fire and forget)
extension Unawaited on Future {
  void get unawaited => {};
}
