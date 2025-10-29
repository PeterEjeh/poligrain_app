import 'dart:io';
import '../models/document.dart';
import '../services/document_service.dart';
import '../exceptions/document_exceptions.dart';

/// Handler for document operations with additional business logic
class DocumentHandler {
  final DocumentService _documentService;

  DocumentHandler({DocumentService? documentService})
    : _documentService = documentService ?? DocumentService();

  /// Upload a document with validation and progress tracking
  Future<DocumentUploadResult> uploadDocument({
    required String filePath,
    required DocumentType type,
    required String name,
    String? campaignId,
    DateTime? expiryDate,
    Map<String, dynamic>? metadata,
    Function(double)? onProgress,
  }) async {
    try {
      // Pre-upload validation
      _documentService.validateDocumentUpload(
        filePath: filePath,
        type: type,
        name: name,
      );

      // Simulate progress tracking during upload
      onProgress?.call(0.0);

      final document = await _documentService.uploadDocument(
        filePath: filePath,
        type: type,
        name: name,
        campaignId: campaignId,
        expiryDate: expiryDate,
        metadata: metadata,
      );

      onProgress?.call(1.0);

      return DocumentUploadResult(
        document: document,
        success: true,
        message: 'Document uploaded successfully',
      );
    } on DocumentException catch (e) {
      return DocumentUploadResult(success: false, message: e.message, error: e);
    } catch (e) {
      return DocumentUploadResult(
        success: false,
        message: 'An unexpected error occurred: $e',
        error: e,
      );
    }
  }

  /// Get documents with enhanced filtering and sorting
  /// Get documents with enhanced filtering and sorting
  Future<DocumentListResponse> getDocuments({
    int limit = 20,
    String? lastKey,
    DocumentType? type,
    DocumentStatus? status,
    String? campaignId,
    DocumentSortOption sortBy = DocumentSortOption.dateCreated,
    bool ascending = false,
  }) async {
    try {
      final result = await _documentService.listDocuments(
        limit: limit,
        lastKey: lastKey,
        type: type,
        status: status,
        campaignId: campaignId,
      );

      // Apply sorting if needed (this would be better done server-side)
      final sortedDocuments = _sortDocuments(
        result.documents,
        sortBy,
        ascending,
      );

      return DocumentListResponse(
        documents: sortedDocuments,
        hasMore: result.hasMore,
        nextPageKey: result.nextPageKey,
        totalCount:
            sortedDocuments
                .length, // Fixed: Use the actual count of returned documents
        success: true,
      );
    } on DocumentException catch (e) {
      return DocumentListResponse(
        documents: [],
        hasMore: false,
        totalCount: 0, // Fixed: Added required totalCount parameter
        success: false,
        message: e.message,
        error: e,
      );
    } catch (e) {
      return DocumentListResponse(
        documents: [],
        hasMore: false,
        totalCount: 0, // Fixed: Added required totalCount parameter
        success: false,
        message: 'Failed to fetch documents: $e',
        error: e,
      );
    }
  }

  /// Get document with additional metadata
  Future<DocumentResponse> getDocument(String documentId) async {
    try {
      final document = await _documentService.getDocumentStatus(documentId);

      return DocumentResponse(document: document, success: true);
    } on DocumentNotFoundException catch (e) {
      return DocumentResponse(
        success: false,
        message: 'Document not found',
        error: e,
      );
    } on DocumentException catch (e) {
      return DocumentResponse(success: false, message: e.message, error: e);
    } catch (e) {
      return DocumentResponse(
        success: false,
        message: 'Failed to fetch document: $e',
        error: e,
      );
    }
  }

  /// Delete document with confirmation
  Future<DocumentOperationResult> deleteDocument(
    String documentId, {
    bool confirm = false,
  }) async {
    if (!confirm) {
      return DocumentOperationResult(
        success: false,
        message: 'Deletion requires confirmation',
      );
    }

    try {
      await _documentService.deleteDocument(documentId);

      return DocumentOperationResult(
        success: true,
        message: 'Document deleted successfully',
      );
    } on DocumentNotFoundException catch (e) {
      return DocumentOperationResult(
        success: false,
        message: 'Document not found',
        error: e,
      );
    } on DocumentException catch (e) {
      return DocumentOperationResult(
        success: false,
        message: e.message,
        error: e,
      );
    } catch (e) {
      return DocumentOperationResult(
        success: false,
        message: 'Failed to delete document: $e',
        error: e,
      );
    }
  }

  /// Update document verification status (admin only)
  Future<DocumentResponse> updateVerificationStatus({
    required String documentId,
    required DocumentStatus status,
    String? rejectionReason,
  }) async {
    try {
      final document = await _documentService.updateDocumentVerification(
        documentId: documentId,
        status: status,
        rejectionReason: rejectionReason,
        verifiedAt: status == DocumentStatus.verified ? DateTime.now() : null,
      );

      return DocumentResponse(
        document: document,
        success: true,
        message: 'Document verification updated successfully',
      );
    } on DocumentException catch (e) {
      return DocumentResponse(success: false, message: e.message, error: e);
    } catch (e) {
      return DocumentResponse(
        success: false,
        message: 'Failed to update verification status: $e',
        error: e,
      );
    }
  }

  /// Get user's documents grouped by type
  Future<GroupedDocumentsResponse> getUserDocumentsGrouped() async {
    try {
      final documents = await _documentService.getUserDocuments();

      final groupedDocuments = <DocumentType, List<Document>>{};
      for (final document in documents) {
        groupedDocuments.putIfAbsent(document.type, () => []).add(document);
      }

      return GroupedDocumentsResponse(
        groupedDocuments: groupedDocuments,
        totalCount: documents.length,
        success: true,
      );
    } on DocumentException catch (e) {
      return GroupedDocumentsResponse(
        groupedDocuments: {},
        totalCount: 0,
        success: false,
        message: e.message,
        error: e,
      );
    } catch (e) {
      return GroupedDocumentsResponse(
        groupedDocuments: {},
        totalCount: 0,
        success: false,
        message: 'Failed to fetch user documents: $e',
        error: e,
      );
    }
  }

  /// Check document requirements for a campaign
  Future<DocumentRequirementsResponse> checkCampaignDocumentRequirements(
    String campaignId,
  ) async {
    try {
      final campaignDocuments = await _documentService.getCampaignDocuments(
        campaignId,
      );
      final userDocuments = await _documentService.getUserDocuments();

      final requiredTypes = [
        DocumentType.identity,
        DocumentType.farmTitle,
        DocumentType.businessRegistration,
      ];

      final missingDocuments = <DocumentType>[];
      final completedRequirements = <DocumentType, Document>{};

      for (final requiredType in requiredTypes) {
        final userDoc =
            userDocuments
                .where((doc) => doc.type == requiredType && doc.isVerified)
                .firstOrNull;

        if (userDoc != null) {
          completedRequirements[requiredType] = userDoc;
        } else {
          missingDocuments.add(requiredType);
        }
      }

      final isComplete = missingDocuments.isEmpty;

      return DocumentRequirementsResponse(
        isComplete: isComplete,
        completedRequirements: completedRequirements,
        missingDocuments: missingDocuments,
        campaignDocuments: campaignDocuments,
        success: true,
      );
    } catch (e) {
      return DocumentRequirementsResponse(
        isComplete: false,
        completedRequirements: {},
        missingDocuments: [],
        campaignDocuments: [],
        success: false,
        message: 'Failed to check document requirements: $e',
        error: e,
      );
    }
  }

  /// Get supported file formats for upload
  List<String> getSupportedFileFormats() {
    return [
      'PDF (.pdf)',
      'JPEG (.jpg, .jpeg)',
      'PNG (.png)',
      'GIF (.gif)',
      'WebP (.webp)',
      'Word Document (.doc, .docx)',
    ];
  }

  /// Validate file before upload
  Future<FileValidationResult> validateFile(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        return FileValidationResult(
          isValid: false,
          message: 'File does not exist',
        );
      }

      final fileSize = await file.length();
      const maxSizeBytes = 10 * 1024 * 1024; // 10MB

      if (fileSize > maxSizeBytes) {
        return FileValidationResult(
          isValid: false,
          message: 'File size exceeds 10MB limit',
          actualSize: fileSize,
          maxSize: maxSizeBytes,
        );
      }

      final fileName = file.path.split('/').last;
      final extension = fileName.split('.').last.toLowerCase();

      const supportedExtensions = [
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'gif',
        'webp',
        'doc',
        'docx',
      ];

      if (!supportedExtensions.contains(extension)) {
        return FileValidationResult(
          isValid: false,
          message: 'File format not supported',
          fileExtension: extension,
        );
      }

      return FileValidationResult(
        isValid: true,
        message: 'File is valid',
        fileSize: fileSize,
        fileExtension: extension,
      );
    } catch (e) {
      return FileValidationResult(
        isValid: false,
        message: 'Error validating file: $e',
      );
    }
  }

  /// Private helper method to sort documents
  List<Document> _sortDocuments(
    List<Document> documents,
    DocumentSortOption sortBy,
    bool ascending,
  ) {
    final sorted = List<Document>.from(documents);

    switch (sortBy) {
      case DocumentSortOption.dateCreated:
        sorted.sort(
          (a, b) =>
              ascending
                  ? a.uploadedAt.compareTo(
                    b.uploadedAt,
                  ) // Fixed: Changed from createdAt to uploadedAt
                  : b.uploadedAt.compareTo(a.uploadedAt),
        ); // Fixed: Changed from createdAt to uploadedAt
        break;
      case DocumentSortOption.name:
        sorted.sort(
          (a, b) =>
              ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name),
        );
        break;
      case DocumentSortOption.type:
        sorted.sort(
          (a, b) =>
              ascending
                  ? a.type.name.compareTo(b.type.name)
                  : b.type.name.compareTo(a.type.name),
        );
        break;
      case DocumentSortOption.status:
        sorted.sort(
          (a, b) =>
              ascending
                  ? a.status.name.compareTo(b.status.name)
                  : b.status.name.compareTo(a.status.name),
        );
        break;
      case DocumentSortOption.fileSize:
        sorted.sort(
          (a, b) =>
              ascending
                  ? a.fileSize.compareTo(b.fileSize)
                  : b.fileSize.compareTo(a.fileSize),
        );
        break;
    }

    return sorted;
  }
}

/// Enumeration for document sorting options
enum DocumentSortOption { dateCreated, name, type, status, fileSize }

/// Response classes for handler operations

class DocumentUploadResult {
  final Document? document;
  final bool success;
  final String? message;
  final dynamic error;

  const DocumentUploadResult({
    this.document,
    required this.success,
    this.message,
    this.error,
  });
}

class DocumentListResponse {
  final List<Document> documents;
  final bool hasMore;
  final String? nextPageKey;
  final int totalCount;
  final bool success;
  final String? message;
  final dynamic error;

  const DocumentListResponse({
    required this.documents,
    required this.hasMore,
    this.nextPageKey,
    required this.totalCount,
    required this.success,
    this.message,
    this.error,
  });
}

class DocumentResponse {
  final Document? document;
  final bool success;
  final String? message;
  final dynamic error;

  const DocumentResponse({
    this.document,
    required this.success,
    this.message,
    this.error,
  });
}

class DocumentOperationResult {
  final bool success;
  final String? message;
  final dynamic error;

  const DocumentOperationResult({
    required this.success,
    this.message,
    this.error,
  });
}

class GroupedDocumentsResponse {
  final Map<DocumentType, List<Document>> groupedDocuments;
  final int totalCount;
  final bool success;
  final String? message;
  final dynamic error;

  const GroupedDocumentsResponse({
    required this.groupedDocuments,
    required this.totalCount,
    required this.success,
    this.message,
    this.error,
  });
}

class DocumentRequirementsResponse {
  final bool isComplete;
  final Map<DocumentType, Document> completedRequirements;
  final List<DocumentType> missingDocuments;
  final List<Document> campaignDocuments;
  final bool success;
  final String? message;
  final dynamic error;

  const DocumentRequirementsResponse({
    required this.isComplete,
    required this.completedRequirements,
    required this.missingDocuments,
    required this.campaignDocuments,
    required this.success,
    this.message,
    this.error,
  });
}

class FileValidationResult {
  final bool isValid;
  final String message;
  final int? fileSize;
  final int? actualSize;
  final int? maxSize;
  final String? fileExtension;

  const FileValidationResult({
    required this.isValid,
    required this.message,
    this.fileSize,
    this.actualSize,
    this.maxSize,
    this.fileExtension,
  });
}

// Extension to check if Document is null in a list
extension ListDocumentExtension on List<Document> {
  Document? get firstOrNull => isEmpty ? null : first;
}
