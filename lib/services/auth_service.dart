import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      return session.isSignedIn;
    } catch (e) {
      safePrint('Error checking authentication status: $e');
      return false;
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
    } catch (e) {
      safePrint('Error signing out: $e');
      rethrow;
    }
  }

  /// Get current user information
  Future<AuthUser?> getCurrentUser() async {
    try {
      return await Amplify.Auth.getCurrentUser();
    } catch (e) {
      safePrint('Error getting current user: $e');
      return null;
    }
  }

  /// Get access token for API calls
  Future<String?> getAccessToken() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session.isSignedIn) {
        final cognitoSession = session as CognitoAuthSession;
        return cognitoSession.userPoolTokensResult.value.accessToken.raw;
      }
      return null;
    } catch (e) {
      safePrint('Error getting access token: $e');
      return null;
    }
  }

  /// Get ID token for API calls
  Future<String?> getIdToken() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session.isSignedIn) {
        final cognitoSession = session as CognitoAuthSession;
        return cognitoSession.userPoolTokensResult.value.idToken.raw;
      }
      return null;
    } catch (e) {
      safePrint('Error getting ID token: $e');
      return null;
    }
  }

  /// Listen to authentication state changes
  /// Note: This method is not available in current Amplify version
  /// Use periodic checks or manual state management instead
  Stream<AuthSession> get authStateChanges {
    // Return an empty stream for now - we'll handle auth state changes manually
    return Stream.empty();
  }

  /// Fetch user attributes (e.g., name, email, custom fields)
  Future<Map<String, String>> fetchUserAttributes() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      return {
        for (final attr in attributes) attr.userAttributeKey.key: attr.value,
      };
    } catch (e) {
      safePrint('Error fetching user attributes: $e');
      return {};
    }
  }

  /// Utility: Check for internet connectivity
  Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Change the user's password
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await Amplify.Auth.updatePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
    } on AuthException catch (e) {
      safePrint('Error changing password: \\${e.message}');
      rethrow;
    } catch (e) {
      safePrint('Unexpected error changing password: \\${e.toString()}');
      rethrow;
    }
  }

  /// Fetch user profile from API with enhanced debugging
  Future<Map<String, dynamic>?> fetchUserProfile() async {
    try {
      safePrint('🔍 AuthService: Starting fetchUserProfile()');

      // Step 1: Check authentication status
      safePrint('🔐 AuthService: Checking authentication status...');
      final isAuthenticated = await this.isAuthenticated();
      safePrint('🔐 AuthService: isAuthenticated: $isAuthenticated');

      if (!isAuthenticated) {
        safePrint('❌ AuthService: User is not authenticated');
        return null;
      }

      // Step 2: Get current user
      safePrint('👤 AuthService: Getting current user...');
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        safePrint(
          '❌ AuthService: No current user found (getCurrentUser returned null)',
        );
        return null;
      }

      safePrint('✅ AuthService: Current user found: ${currentUser.username}');
      safePrint('🆔 AuthService: User ID: ${currentUser.userId}');

      // Step 3: Get user email from attributes (this is what the backend uses as username)
      safePrint('📧 AuthService: Getting user email from attributes...');
      final userAttributes = await fetchUserAttributes();
      final userEmail = userAttributes['email'];

      if (userEmail == null || userEmail.isEmpty) {
        safePrint('❌ AuthService: User email not found in attributes');
        safePrint(
          '📋 AuthService: Available attributes: ${userAttributes.keys.toList()}',
        );
        return null;
      }

      safePrint('✅ AuthService: User email found: $userEmail');

      // Step 4: Prepare API call
      safePrint('🌐 AuthService: Preparing API call to /profile endpoint');
      final queryParams = {'username': userEmail};
      safePrint('📋 AuthService: Query parameters: $queryParams');

      // Step 4: Make API call
      safePrint('📡 AuthService: Making API GET request...');
      final response =
          await Amplify.API
              .get(
                '/profile',
                apiName: 'PoligrainAPI',
                queryParameters: queryParams,
              )
              .response;

      safePrint('📡 AuthService: API response received');
      safePrint('📊 AuthService: Response status code: ${response.statusCode}');

      // Step 5: Process response
      final bodyString = response.decodeBody();
      safePrint('📄 AuthService: Raw response body: $bodyString');

      final responseBody = jsonDecode(bodyString);
      safePrint('🔄 AuthService: Parsed response body: $responseBody');

      if (response.statusCode == 200) {
        safePrint(
          '✅ AuthService: Profile found successfully for user: $userEmail',
        );
        safePrint(
          '📋 AuthService: Profile data keys: ${responseBody.keys.toList()}',
        );
        return responseBody as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        // Profile not found - this is expected for new users
        safePrint(
          '🔍 AuthService: Profile not found (404) for user: $userEmail',
        );
        safePrint(
          'ℹ️ AuthService: This is normal for new users who haven\'t completed their profile yet',
        );
        return null;
      } else {
        safePrint(
          '❌ AuthService: Unexpected status code: ${response.statusCode}',
        );
        safePrint('📋 AuthService: Response body: $responseBody');
        safePrint('👤 AuthService: For user: $userEmail');
        return null;
      }
    } on ApiException catch (e) {
      safePrint('🚨 AuthService: API Exception caught');
      safePrint('📋 AuthService: Exception message: ${e.message}');
      safePrint('📋 AuthService: Exception details: ${e.toString()}');

      if (e.message.contains('404') ||
          e.message.contains('Profile not found')) {
        // Profile not found - this is expected for new users
        safePrint('🔍 AuthService: Profile not found via API exception');
        safePrint('ℹ️ AuthService: This is normal for new users');
        return null;
      } else {
        // Other API errors - rethrow to be handled by caller
        safePrint('❌ AuthService: Unexpected API error: ${e.message}');
        safePrint('🔄 AuthService: Rethrowing exception for caller to handle');
        rethrow;
      }
    } catch (e) {
      safePrint('💥 AuthService: Unexpected error in fetchUserProfile');
      safePrint('📋 AuthService: Error type: ${e.runtimeType}');
      safePrint('📋 AuthService: Error message: $e');
      safePrint('📋 AuthService: Error stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Check if user profile is complete with comprehensive debugging
  Future<bool> isProfileComplete() async {
    try {
      safePrint('🔍 AuthService: Starting profile completion check');

      final profile = await fetchUserProfile();

      if (profile == null) {
        safePrint('❌ AuthService: Profile is null, returning false');
        return false;
      }

      // Log the entire profile for debugging
      safePrint('📋 AuthService: Raw profile data: $profile');

      // Check if profile_complete field exists
      if (!profile.containsKey('profile_complete')) {
        safePrint('❌ AuthService: profile_complete field not found in profile');
        safePrint('📋 AuthService: Available fields: ${profile.keys.toList()}');
        return false;
      }

      final profileCompleteValue = profile['profile_complete'];
      safePrint(
        '🔍 AuthService: profile_complete value: $profileCompleteValue (type: ${profileCompleteValue.runtimeType})',
      );

      // Handle different data types (boolean vs string)
      bool isComplete = false;

      if (profileCompleteValue is bool) {
        isComplete = profileCompleteValue;
        safePrint('✅ AuthService: profile_complete is boolean: $isComplete');
      } else if (profileCompleteValue is String) {
        // Handle string values
        if (profileCompleteValue.toLowerCase() == 'true') {
          isComplete = true;
          safePrint(
            '✅ AuthService: profile_complete is string "true", converted to: $isComplete',
          );
        } else if (profileCompleteValue.toLowerCase() == 'false') {
          isComplete = false;
          safePrint(
            '❌ AuthService: profile_complete is string "false", converted to: $isComplete',
          );
        } else {
          safePrint(
            '⚠️ AuthService: profile_complete is string but not "true" or "false": "$profileCompleteValue"',
          );
          isComplete = false;
        }
      } else {
        safePrint(
          '⚠️ AuthService: profile_complete is unexpected type: ${profileCompleteValue.runtimeType}',
        );
        // Try to convert to boolean as fallback
        try {
          isComplete = profileCompleteValue.toString().toLowerCase() == 'true';
          safePrint(
            '🔄 AuthService: Converted to boolean as fallback: $isComplete',
          );
        } catch (e) {
          safePrint(
            '❌ AuthService: Failed to convert profile_complete to boolean: $e',
          );
          isComplete = false;
        }
      }

      safePrint(
        '🎯 AuthService: Final result - isProfileComplete: $isComplete',
      );
      return isComplete;
    } catch (e) {
      // If there's an error (other than 404), assume profile might exist
      // This prevents users from being stuck in profile setup due to network issues
      safePrint('❌ AuthService: Error checking profile completion: $e');
      safePrint('🔄 AuthService: Assuming incomplete due to error');
      return false;
    }
  }

  /// Test method to verify profile completion scenarios
  Future<Map<String, dynamic>> testProfileCompletionScenarios() async {
    try {
      safePrint('🧪 AuthService: Starting profile completion test scenarios');

      final profile = await fetchUserProfile();
      final isComplete = await isProfileComplete();

      final testResults = {
        'profile_exists': profile != null,
        'profile_data': profile,
        'is_complete': isComplete,
        'profile_complete_field_exists':
            profile?.containsKey('profile_complete') ?? false,
        'profile_complete_value': profile?['profile_complete'],
        'profile_complete_type':
            profile?['profile_complete']?.runtimeType.toString(),
        'available_fields': profile?.keys.toList(),
        'test_timestamp': DateTime.now().toIso8601String(),
      };

      safePrint('🧪 AuthService: Test results: $testResults');
      return testResults;
    } catch (e) {
      safePrint('❌ AuthService: Error during test scenarios: $e');
      return {
        'error': e.toString(),
        'test_timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Comprehensive diagnostic method to debug profile fetching issues
  Future<Map<String, dynamic>> debugProfileFetching() async {
    safePrint(
      '🔧 AuthService: Starting comprehensive profile fetching diagnostics',
    );

    final Map<String, dynamic> diagnostics = {
      'timestamp': DateTime.now().toIso8601String(),
      'steps': <String, dynamic>{},
      'final_result': null,
      'recommendations': <String>[],
    };

    try {
      // Step 1: Check if Amplify is configured
      safePrint('🔧 Step 1: Checking Amplify configuration...');
      (diagnostics['steps'] as Map<String, dynamic>)['amplify_config'] =
          'Checking Amplify configuration';

      try {
        final session = await Amplify.Auth.fetchAuthSession();
        (diagnostics['steps'] as Map<String, dynamic>)['amplify_config'] = {
          'status': 'success',
          'is_signed_in': session.isSignedIn,
        };
        safePrint(
          '✅ Amplify configured successfully, signed in: ${session.isSignedIn}',
        );
      } catch (e) {
        (diagnostics['steps'] as Map<String, dynamic>)['amplify_config'] = {
          'status': 'error',
          'error': e.toString(),
        };
        (diagnostics['recommendations'] as List<String>).add(
          'Amplify not properly configured',
        );
        safePrint('❌ Amplify configuration error: $e');
      }

      // Step 2: Check authentication status
      safePrint('🔧 Step 2: Checking authentication status...');
      final isAuthenticated = await this.isAuthenticated();
      (diagnostics['steps'] as Map<String, dynamic>)['authentication'] = {
        'is_authenticated': isAuthenticated,
      };
      safePrint('🔐 Authentication status: $isAuthenticated');

      if (!isAuthenticated) {
        (diagnostics['recommendations'] as List<String>).add(
          'User is not authenticated - login required',
        );
        diagnostics['final_result'] = 'authentication_failed';
        return diagnostics;
      }

      // Step 3: Get current user details
      safePrint('🔧 Step 3: Getting current user details...');
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        (diagnostics['steps'] as Map<String, dynamic>)['current_user'] = {
          'status': 'error',
          'error': 'getCurrentUser() returned null',
        };
        (diagnostics['recommendations'] as List<String>).add(
          'Unable to get current user - authentication issue',
        );
        diagnostics['final_result'] = 'user_fetch_failed';
        return diagnostics;
      }

      (diagnostics['steps'] as Map<String, dynamic>)['current_user'] = {
        'status': 'success',
        'username': currentUser.username,
        'user_id': currentUser.userId,
      };
      safePrint('👤 Current user: ${currentUser.username}');

      // Step 4: Test API connectivity
      safePrint('🔧 Step 4: Testing API connectivity...');
      try {
        // Try a simple API call to test connectivity
        final testResponse =
            await Amplify.API
                .get(
                  '/profile',
                  apiName: 'PoligrainAPI',
                  queryParameters: {'username': currentUser.username},
                )
                .response;

        (diagnostics['steps'] as Map<String, dynamic>)['api_connectivity'] = {
          'status': 'success',
          'status_code': testResponse.statusCode,
          'response_length': testResponse.decodeBody().length,
        };
        safePrint(
          '🌐 API connectivity test: Status ${testResponse.statusCode}',
        );

        // Step 5: Parse response
        safePrint('🔧 Step 5: Parsing API response...');
        final bodyString = testResponse.decodeBody();
        final responseBody = jsonDecode(bodyString);

        (diagnostics['steps'] as Map<String, dynamic>)['response_parsing'] = {
          'status': 'success',
          'response_type': responseBody.runtimeType.toString(),
          'is_map': responseBody is Map,
        };

        if (responseBody is Map<String, dynamic>) {
          (diagnostics['steps'] as Map<String, dynamic>)['profile_data'] = {
            'status': 'success',
            'keys': responseBody.keys.toList(),
            'has_profile_complete': responseBody.containsKey(
              'profile_complete',
            ),
            'profile_complete_value': responseBody['profile_complete'],
          };
          diagnostics['final_result'] = 'profile_found';
        } else {
          (diagnostics['steps'] as Map<String, dynamic>)['profile_data'] = {
            'status': 'error',
            'error': 'Response is not a Map',
            'response_type': responseBody.runtimeType.toString(),
          };
          (diagnostics['recommendations'] as List<String>).add(
            'API response format is unexpected',
          );
          diagnostics['final_result'] = 'invalid_response_format';
        }
      } catch (e) {
        (diagnostics['steps'] as Map<String, dynamic>)['api_connectivity'] = {
          'status': 'error',
          'error': e.toString(),
          'error_type': e.runtimeType.toString(),
        };
        (diagnostics['recommendations'] as List<String>).add(
          'API call failed - check network and endpoint configuration',
        );
        diagnostics['final_result'] = 'api_call_failed';
        safePrint('❌ API connectivity error: $e');
      }
    } catch (e) {
      (diagnostics['steps'] as Map<String, dynamic>)['unexpected_error'] = {
        'error': e.toString(),
        'error_type': e.runtimeType.toString(),
      };
      (diagnostics['recommendations'] as List<String>).add(
        'Unexpected error occurred during diagnostics',
      );
      diagnostics['final_result'] = 'unexpected_error';
      safePrint('💥 Unexpected error during diagnostics: $e');
    }

    safePrint('🔧 Diagnostics completed');
    safePrint('📋 Final result: ${diagnostics['final_result']}');
    safePrint('💡 Recommendations: ${diagnostics['recommendations']}');

    return diagnostics;
  }
}
