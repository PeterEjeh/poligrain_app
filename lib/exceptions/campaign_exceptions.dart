import 'dart:io';
import 'dart:async';

/// Custom exception class for campaign-related errors
class CampaignException implements Exception {
  final String message;
  final String? code;
  final dynamic details;
  final StackTrace? stackTrace;

  const CampaignException(
    this.message, {
    this.code,
    this.details,
    this.stackTrace,
  });

  @override
  String toString() {
    if (code != null) {
      return 'CampaignException [$code]: $message';
    }
    return 'CampaignException: $message';
  }

  /// Create a validation error
  factory CampaignException.validation(String message, {dynamic details}) {
    return CampaignException(
      message,
      code: 'VALIDATION_ERROR',
      details: details,
    );
  }

  /// Create a network error
  factory CampaignException.network(String message, {dynamic details}) {
    return CampaignException(message, code: 'NETWORK_ERROR', details: details);
  }

  /// Create an authentication error
  factory CampaignException.auth(String message, {dynamic details}) {
    return CampaignException(message, code: 'AUTH_ERROR', details: details);
  }

  /// Create a permission error
  factory CampaignException.permission(String message, {dynamic details}) {
    return CampaignException(
      message,
      code: 'PERMISSION_ERROR',
      details: details,
    );
  }

  /// Create a not found error
  factory CampaignException.notFound(String message, {dynamic details}) {
    return CampaignException(message, code: 'NOT_FOUND', details: details);
  }

  /// Create a server error
  factory CampaignException.server(String message, {dynamic details}) {
    return CampaignException(message, code: 'SERVER_ERROR', details: details);
  }

  /// Create a timeout error
  factory CampaignException.timeout(String message, {dynamic details}) {
    return CampaignException(message, code: 'TIMEOUT_ERROR', details: details);
  }

  /// Create a data format error
  factory CampaignException.format(String message, {dynamic details}) {
    return CampaignException(message, code: 'FORMAT_ERROR', details: details);
  }

  /// Check if this is a specific type of error
  bool get isValidationError => code == 'VALIDATION_ERROR';
  bool get isNetworkError => code == 'NETWORK_ERROR';
  bool get isAuthError => code == 'AUTH_ERROR';
  bool get isPermissionError => code == 'PERMISSION_ERROR';
  bool get isNotFoundError => code == 'NOT_FOUND';
  bool get isServerError => code == 'SERVER_ERROR';
  bool get isTimeoutError => code == 'TIMEOUT_ERROR';
  bool get isFormatError => code == 'FORMAT_ERROR';

  /// Get user-friendly error message
  String get userFriendlyMessage {
    switch (code) {
      case 'NETWORK_ERROR':
        return 'Please check your internet connection and try again.';
      case 'AUTH_ERROR':
        return 'Please log in again to continue.';
      case 'PERMISSION_ERROR':
        return 'You don\'t have permission to perform this action.';
      case 'NOT_FOUND':
        return 'The requested campaign was not found.';
      case 'SERVER_ERROR':
        return 'Server error. Please try again later.';
      case 'TIMEOUT_ERROR':
        return 'Request timed out. Please try again.';
      case 'VALIDATION_ERROR':
        return message; // Validation messages are already user-friendly
      case 'FORMAT_ERROR':
        return 'Invalid data format received.';
      default:
        return message.isNotEmpty ? message : 'An unexpected error occurred.';
    }
  }

  /// Get suggested actions for the user
  List<String> get suggestedActions {
    switch (code) {
      case 'NETWORK_ERROR':
        return [
          'Check your internet connection',
          'Try again in a moment',
          'Switch to a different network if available',
        ];
      case 'AUTH_ERROR':
        return [
          'Log out and log back in',
          'Check if your session has expired',
          'Verify your account credentials',
        ];
      case 'PERMISSION_ERROR':
        return [
          'Contact support if you believe this is an error',
          'Check if you have the required permissions',
          'Try logging in with a different account',
        ];
      case 'NOT_FOUND':
        return [
          'Check if the campaign ID is correct',
          'Refresh the page to see updated campaigns',
          'The campaign may have been removed',
        ];
      case 'SERVER_ERROR':
        return [
          'Try again in a few minutes',
          'Contact support if the problem persists',
          'Check our status page for known issues',
        ];
      case 'TIMEOUT_ERROR':
        return [
          'Check your internet connection',
          'Try again with a better connection',
          'Contact support if timeouts persist',
        ];
      case 'VALIDATION_ERROR':
        if (details is List<String>) {
          return details as List<String>;
        }
        return ['Please check your input and try again'];
      default:
        return ['Try again later', 'Contact support if the problem persists'];
    }
  }
}

/// Exception handler utility class
class CampaignExceptionHandler {
  /// Handle exceptions and convert them to CampaignException
  static CampaignException handleException(
    dynamic error, {
    StackTrace? stackTrace,
  }) {
    if (error is CampaignException) {
      return error;
    }

    // Handle common Flutter/Dart exceptions
    if (error is FormatException) {
      return CampaignException.format(
        'Invalid data format: ${error.message}',
        details: error.source,
      );
    }

    if (error is TimeoutException) {
      return CampaignException.timeout(
        'Request timed out',
        details: error.message,
      );
    }

    if (error is SocketException) {
      return CampaignException.network(
        'Network connection failed',
        details: error.message,
      );
    }

    if (error is HttpException) {
      return CampaignException.network(
        'HTTP error: ${error.message}',
        details: error.uri?.toString(),
      );
    }

    // Handle Amplify exceptions
    if (error.toString().contains('AmplifyException')) {
      if (error.toString().contains('UserNotConfirmedException') ||
          error.toString().contains('NotAuthorizedException') ||
          error.toString().contains('UserNotFoundException')) {
        return CampaignException.auth(
          'Authentication failed: ${_extractAmplifyMessage(error)}',
          details: error.toString(),
        );
      }

      return CampaignException.server(
        'Service error: ${_extractAmplifyMessage(error)}',
        details: error.toString(),
      );
    }

    // Generic error handling
    return CampaignException(
      error.toString().isNotEmpty
          ? error.toString()
          : 'An unexpected error occurred',
      code: 'UNKNOWN_ERROR',
      details: error,
      stackTrace: stackTrace,
    );
  }

  static String _extractAmplifyMessage(dynamic error) {
    final errorString = error.toString();
    final messageStart = errorString.indexOf('message: ');
    if (messageStart != -1) {
      final messageEnd = errorString.indexOf(',', messageStart);
      if (messageEnd != -1) {
        return errorString.substring(messageStart + 9, messageEnd);
      }
    }
    return errorString;
  }

  /// Log exception for debugging
  static void logException(CampaignException exception, {String? context}) {
    final logMessage = StringBuffer();
    logMessage.writeln('=== Campaign Exception ===');
    if (context != null) logMessage.writeln('Context: $context');
    logMessage.writeln('Code: ${exception.code ?? 'UNKNOWN'}');
    logMessage.writeln('Message: ${exception.message}');
    if (exception.details != null) {
      logMessage.writeln('Details: ${exception.details}');
    }
    if (exception.stackTrace != null) {
      logMessage.writeln('Stack Trace:');
      logMessage.writeln(exception.stackTrace);
    }
    logMessage.writeln('========================');

    // In a real app, you might want to send this to a logging service
    print(logMessage.toString());
  }

  /// Create user-friendly error dialog data
  static Map<String, dynamic> createErrorDialogData(
    CampaignException exception,
  ) {
    return {
      'title': _getErrorTitle(exception.code),
      'message': exception.userFriendlyMessage,
      'actions': exception.suggestedActions,
      'canRetry': _canRetry(exception.code),
      'severity': _getErrorSeverity(exception.code),
    };
  }

  static String _getErrorTitle(String? code) {
    switch (code) {
      case 'NETWORK_ERROR':
        return 'Connection Error';
      case 'AUTH_ERROR':
        return 'Authentication Required';
      case 'PERMISSION_ERROR':
        return 'Access Denied';
      case 'NOT_FOUND':
        return 'Not Found';
      case 'SERVER_ERROR':
        return 'Server Error';
      case 'TIMEOUT_ERROR':
        return 'Request Timeout';
      case 'VALIDATION_ERROR':
        return 'Invalid Input';
      case 'FORMAT_ERROR':
        return 'Data Error';
      default:
        return 'Error';
    }
  }

  static bool _canRetry(String? code) {
    switch (code) {
      case 'NETWORK_ERROR':
      case 'SERVER_ERROR':
      case 'TIMEOUT_ERROR':
        return true;
      case 'AUTH_ERROR':
      case 'PERMISSION_ERROR':
      case 'NOT_FOUND':
      case 'VALIDATION_ERROR':
      case 'FORMAT_ERROR':
        return false;
      default:
        return true;
    }
  }

  static String _getErrorSeverity(String? code) {
    switch (code) {
      case 'VALIDATION_ERROR':
        return 'warning';
      case 'AUTH_ERROR':
      case 'PERMISSION_ERROR':
        return 'error';
      case 'SERVER_ERROR':
        return 'critical';
      default:
        return 'error';
    }
  }
}
