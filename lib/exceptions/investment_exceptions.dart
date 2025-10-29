/// Base class for all investment-related exceptions
abstract class InvestmentException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? details;

  const InvestmentException(this.message, {this.statusCode, this.details});

  @override
  String toString() => 'InvestmentException: $message';
}

/// Exception thrown when investment creation fails
class InvestmentCreationException extends InvestmentException {
  const InvestmentCreationException(
    String message, {
    int? statusCode,
    Map<String, dynamic>? details,
  }) : super(message, statusCode: statusCode, details: details);

  @override
  String toString() => 'InvestmentCreationException: $message';
}

/// Exception thrown when investment fetching fails
class InvestmentFetchException extends InvestmentException {
  const InvestmentFetchException(
    String message, {
    int? statusCode,
  }) : super(message, statusCode: statusCode);

  @override
  String toString() => 'InvestmentFetchException: $message';
}

/// Exception thrown when investment is not found
class InvestmentNotFoundException extends InvestmentException {
  const InvestmentNotFoundException(String message) 
      : super(message, statusCode: 404);

  @override
  String toString() => 'InvestmentNotFoundException: $message';
}

/// Exception thrown when investment update fails
class InvestmentUpdateException extends InvestmentException {
  const InvestmentUpdateException(
    String message, {
    int? statusCode,
  }) : super(message, statusCode: statusCode);

  @override
  String toString() => 'InvestmentUpdateException: $message';
}

/// Exception thrown when investment processing fails
class InvestmentProcessingException extends InvestmentException {
  const InvestmentProcessingException(
    String message, {
    int? statusCode,
  }) : super(message, statusCode: statusCode);

  @override
  String toString() => 'InvestmentProcessingException: $message';
}

/// Exception thrown when investment validation fails
class InvestmentValidationException extends InvestmentException {
  const InvestmentValidationException(String message) 
      : super(message, statusCode: 400);

  @override
  String toString() => 'InvestmentValidationException: $message';
}

/// Exception thrown when insufficient funds for investment
class InsufficientFundsException extends InvestmentException {
  const InsufficientFundsException(String message) 
      : super(message, statusCode: 402);

  @override
  String toString() => 'InsufficientFundsException: $message';
}
