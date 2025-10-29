/// Base class for all product-related exceptions
abstract class ProductException implements Exception {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  ProductException(this.message, [this.error, this.stackTrace]);

  @override
  String toString() => 'ProductException: $message';
}

/// For network-related errors (API calls, uploads, etc)
class NetworkException extends ProductException {
  final int? statusCode;

  NetworkException(
    String message, {
    this.statusCode,
    dynamic error,
    StackTrace? stackTrace,
  }) : super(message, error, stackTrace);

  @override
  String toString() =>
      'NetworkException: $message (Status: ${statusCode ?? "unknown"})';
}

/// For validation errors
class ValidationException extends ProductException {
  final Map<String, dynamic> errorBody;
  final Map<String, List<String>>? errors;

  ValidationException(
    this.errorBody, {
    this.errors,
    dynamic error,
    StackTrace? stackTrace,
  }) : super(
         errorBody['message'] as String? ?? 'Invalid request',
         error,
         stackTrace,
       );

  @override
  String toString() {
    if (errors != null) {
      final details = errors!.entries
          .map((e) => '${e.key}: ${e.value.join(", ")}')
          .join('\n');
      return 'ValidationException: $message\nDetails:\n$details';
    }
    return 'ValidationException: $message';
  }
}

/// For rate limit errors
class RateLimitException extends ProductException {
  RateLimitException([
    String message = 'Too many requests. Please try again later.',
    dynamic error,
    StackTrace? stackTrace,
  ]) : super(message, error, stackTrace);
}

/// For permission/authentication related errors
class PermissionException extends ProductException {
  final String? requiredRole;

  PermissionException(
    String message, {
    this.requiredRole,
    dynamic error,
    StackTrace? stackTrace,
  }) : super(message, error, stackTrace);

  @override
  String toString() {
    if (requiredRole != null) {
      return 'PermissionException: $message (Required role: $requiredRole)';
    }
    return 'PermissionException: $message';
  }
}

/// For file-related errors (upload, processing, etc)
class FileException extends ProductException {
  final String? filePath;
  final String? operation;

  FileException(
    String message, {
    this.filePath,
    this.operation,
    dynamic error,
    StackTrace? stackTrace,
  }) : super(message, error, stackTrace);

  @override
  String toString() {
    final details = [
      if (filePath != null) 'File: $filePath',
      if (operation != null) 'Operation: $operation',
    ].join(', ');

    if (details.isNotEmpty) {
      return 'FileException: $message ($details)';
    }
    return 'FileException: $message';
  }
}

/// For not found errors
class NotFoundException extends ProductException {
  final String? resourceType;
  final String? identifier;

  NotFoundException(
    String message, {
    this.resourceType,
    this.identifier,
    dynamic error,
    StackTrace? stackTrace,
  }) : super(message, error, stackTrace);

  @override
  String toString() {
    final details = [
      if (resourceType != null) 'Type: $resourceType',
      if (identifier != null) 'ID: $identifier',
    ].join(', ');

    if (details.isNotEmpty) {
      return 'NotFoundException: $message ($details)';
    }
    return 'NotFoundException: $message';
  }
}

// For state errors
class StateException extends ProductException {
  final String? currentState;
  final String? expectedState;

  StateException(
    String message, {
    this.currentState,
    this.expectedState,
    dynamic error,
    StackTrace? stackTrace,
  }) : super(message, error, stackTrace);

  @override
  String toString() {
    final details = [
      if (currentState != null) 'Current: $currentState',
      if (expectedState != null) 'Expected: $expectedState',
    ].join(', ');

    if (details.isNotEmpty) {
      return 'StateException: $message ($details)';
    }
    return 'StateException: $message';
  }
}
