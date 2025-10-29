/// Base class for all document-related exceptions
abstract class DocumentException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? details;

  const DocumentException(this.message, {this.statusCode, this.details});

  @override
  String toString() => 'DocumentException: $message';
}

/// Exception thrown when document upload fails
class DocumentUploadException extends DocumentException {
  const DocumentUploadException(
    String message, {
    int? statusCode,
    Map<String, dynamic>? details,
  }) : super(message, statusCode: statusCode, details: details);

  @override
  String toString() => 'DocumentUploadException: $message';
}

/// Exception thrown when document fetching fails
class DocumentFetchException extends DocumentException {
  const DocumentFetchException(
    String message, {
    int? statusCode,
  }) : super(message, statusCode: statusCode);

  @override
  String toString() => 'DocumentFetchException: $message';
}

/// Exception thrown when document is not found
class DocumentNotFoundException extends DocumentException {
  const DocumentNotFoundException(String message) 
      : super(message, statusCode: 404);

  @override
  String toString() => 'DocumentNotFoundException: $message';
}

/// Exception thrown when document update fails
class DocumentUpdateException extends DocumentException {
  const DocumentUpdateException(
    String message, {
    int? statusCode,
  }) : super(message, statusCode: statusCode);

  @override
  String toString() => 'DocumentUpdateException: $message';
}

/// Exception thrown when document validation fails
class DocumentValidationException extends DocumentException {
  const DocumentValidationException(String message) 
      : super(message, statusCode: 400);

  @override
  String toString() => 'DocumentValidationException: $message';
}

/// Exception thrown when document verification fails
class DocumentVerificationException extends DocumentException {
  const DocumentVerificationException(
    String message, {
    int? statusCode,
  }) : super(message, statusCode: statusCode);

  @override
  String toString() => 'DocumentVerificationException: $message';
}

/// Exception thrown when document file size exceeds limit
class DocumentSizeException extends DocumentException {
  final int maxSize;
  final int actualSize;

  const DocumentSizeException(
    String message, {
    required this.maxSize,
    required this.actualSize,
  }) : super(message, statusCode: 413);

  @override
  String toString() => 'DocumentSizeException: $message (Max: ${maxSize}MB, Actual: ${actualSize}MB)';
}

/// Exception thrown when document format is not supported
class UnsupportedDocumentFormatException extends DocumentException {
  final String format;

  const UnsupportedDocumentFormatException(
    String message, {
    required this.format,
  }) : super(message, statusCode: 415);

  @override
  String toString() => 'UnsupportedDocumentFormatException: $message (Format: $format)';
}
