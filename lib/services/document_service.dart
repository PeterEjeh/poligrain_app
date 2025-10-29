import 'dart:convert';
import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import '../models/document.dart';
import '../exceptions/document_exceptions.dart';

/// Service for managing document uploads and verification
class DocumentService {
  static const String _apiName = 'PoligrainAPI';
  static const int _maxFileSizeMB = 10;
  static const int _maxFileSizeBytes = _maxFileSizeMB * 1024 * 1024;

  static const List<String> _supportedMimeTypes = [
    'application/pdf',
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/gif',
    'image/webp',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  ];

  /// Upload a document
  Future<Document> uploadDocument({
    required String filePath,
    required DocumentType type,
    required String name,
    String? campaignId,
    DateTime? expiryDate,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Validate file
      final file = File(filePath);
      await _validateFile(file);

      // Get file info
      final fileName = file.path.split('/').last;
      final fileSize = await file.length();
      final mimeType = _getMimeType(fileName);

      // Upload to S3
      final uploadKey = await _uploadToS3(file, type, fileName);

      // Create document record in database
      final requestBody = {
        'type': type.value,
        'name': name,
        'fileName': fileName,
        'fileUrl': uploadKey,
        'mimeType': mimeType,
        'fileSize': fileSize,
        if (campaignId != null) 'campaignId': campaignId,
        if (expiryDate != null) 'expiryDate': expiryDate.toIso8601String(),
        if (metadata != null) 'metadata': metadata,
      };

      final response =
          await Amplify.API
              .post(
                '/documents',
                apiName: _apiName,
                body: HttpPayload.json(requestBody),
              )
              .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw DocumentUploadException(
          'Failed to create document record: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
          details: errorBody,
        );
      }

      final documentData = json.decode(responseBody) as Map<String, dynamic>;
      return Document.fromJson(documentData);
    } catch (e) {
      if (e is DocumentException) {
        rethrow;
      }
      throw DocumentUploadException('Failed to upload document: $e');
    }
  }

  /// Get document status by ID
  Future<Document> getDocumentStatus(String documentId) async {
    try {
      final response =
          await Amplify.API
              .get('/documents/$documentId', apiName: _apiName)
              .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode == 404) {
        throw DocumentNotFoundException('Document not found: $documentId');
      }

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw DocumentFetchException(
          'Failed to fetch document: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
        );
      }

      final documentData = json.decode(responseBody) as Map<String, dynamic>;
      return Document.fromJson(documentData);
    } catch (e) {
      if (e is DocumentException) {
        rethrow;
      }
      throw DocumentFetchException('Failed to fetch document status: $e');
    }
  }

  /// List documents with filters and pagination
  Future<DocumentListResult> listDocuments({
    int limit = 20,
    String? lastKey,
    DocumentType? type,
    DocumentStatus? status,
    String? campaignId,
    String? ownerId,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (lastKey != null) 'lastKey': lastKey,
        if (type != null) 'type': type.value,
        if (status != null) 'status': status.value,
        if (campaignId != null) 'campaignId': campaignId,
        if (ownerId != null) 'ownerId': ownerId,
      };

      final response =
          await Amplify.API
              .get(
                '/documents',
                apiName: _apiName,
                queryParameters: queryParams,
              )
              .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw DocumentFetchException(
          'Failed to fetch documents: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
        );
      }

      final responseData = json.decode(responseBody) as Map<String, dynamic>;
      final documents =
          (responseData['documents'] as List<dynamic>)
              .map(
                (documentData) =>
                    Document.fromJson(documentData as Map<String, dynamic>),
              )
              .toList();

      final pagination = responseData['pagination'] as Map<String, dynamic>;

      return DocumentListResult(
        documents: documents,
        hasMore: pagination['hasMore'] as bool,
        nextPageKey: pagination['lastKey'] as String?,
      );
    } catch (e) {
      if (e is DocumentException) {
        rethrow;
      }
      throw DocumentFetchException('Failed to fetch documents: $e');
    }
  }

  /// Update document verification status (admin function)
  Future<Document> updateDocumentVerification({
    required String documentId,
    required DocumentStatus status,
    String? rejectionReason,
    DateTime? verifiedAt,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'status': status.value,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
        if (verifiedAt != null) 'verifiedAt': verifiedAt.toIso8601String(),
      };

      final response =
          await Amplify.API
              .put(
                '/documents/$documentId/verification',
                apiName: _apiName,
                body: HttpPayload.json(requestBody),
              )
              .response;

      final responseBody = response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode == 404) {
        throw DocumentNotFoundException('Document not found: $documentId');
      }

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw DocumentVerificationException(
          'Failed to update document verification: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
        );
      }

      final documentData = json.decode(responseBody) as Map<String, dynamic>;
      return Document.fromJson(documentData);
    } catch (e) {
      if (e is DocumentException) {
        rethrow;
      }
      throw DocumentVerificationException(
        'Failed to update document verification: $e',
      );
    }
  }

  /// Get user's documents
  Future<List<Document>> getUserDocuments() async {
    try {
      final result = await listDocuments(ownerId: 'current_user', limit: 100);
      return result.documents;
    } catch (e) {
      throw DocumentFetchException('Failed to fetch user documents: $e');
    }
  }

  /// Get documents by campaign
  Future<List<Document>> getCampaignDocuments(String campaignId) async {
    try {
      final result = await listDocuments(campaignId: campaignId, limit: 100);
      return result.documents;
    } catch (e) {
      throw DocumentFetchException('Failed to fetch campaign documents: $e');
    }
  }

  /// Get documents by type
  Future<List<Document>> getDocumentsByType(DocumentType type) async {
    try {
      final result = await listDocuments(type: type, limit: 100);
      return result.documents;
    } catch (e) {
      throw DocumentFetchException('Failed to fetch documents by type: $e');
    }
  }

  /// Get documents pending verification
  Future<List<Document>> getPendingDocuments() async {
    try {
      final result = await listDocuments(
        status: DocumentStatus.pending,
        limit: 100,
      );
      return result.documents;
    } catch (e) {
      throw DocumentFetchException('Failed to fetch pending documents: $e');
    }
  }

  /// Delete document
  Future<void> deleteDocument(String documentId) async {
    try {
      final response =
          await Amplify.API
              .delete('/documents/$documentId', apiName: _apiName)
              .response;

      final statusCode = response.statusCode;

      if (statusCode == 404) {
        throw DocumentNotFoundException('Document not found: $documentId');
      }

      if (statusCode >= 400) {
        final responseBody = response.decodeBody();
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw DocumentUpdateException(
          'Failed to delete document: ${errorBody['error'] ?? 'Unknown error'}',
          statusCode: statusCode,
        );
      }
    } catch (e) {
      if (e is DocumentException) {
        rethrow;
      }
      throw DocumentUpdateException('Failed to delete document: $e');
    }
  }

  /// Private method to upload file to S3
  Future<String> _uploadToS3(
    File file,
    DocumentType type,
    String fileName,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uploadKey = 'documents/${type.value}/$timestamp-$fileName';

      final uploadResult =
          await Amplify.Storage.uploadFile(
            localFile: AWSFile.fromPath(file.path),
            path: StoragePath.fromString(uploadKey),
            options: StorageUploadFileOptions(),
          ).result;

      return uploadResult.uploadedItem.path;
    } catch (e) {
      throw DocumentUploadException('Failed to upload file to storage: $e');
    }
  }

  /// Private method to validate file
  Future<void> _validateFile(File file) async {
    if (!await file.exists()) {
      throw DocumentValidationException('File does not exist');
    }

    final fileSize = await file.length();
    if (fileSize > _maxFileSizeBytes) {
      throw DocumentSizeException(
        'File size exceeds maximum limit',
        maxSize: _maxFileSizeMB,
        actualSize: (fileSize / (1024 * 1024)).ceil(),
      );
    }

    final fileName = file.path.split('/').last;
    final mimeType = _getMimeType(fileName);

    if (!_supportedMimeTypes.contains(mimeType)) {
      throw UnsupportedDocumentFormatException(
        'File format not supported',
        format: mimeType,
      );
    }
  }

  /// Private method to get MIME type from file extension
  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  /// Validate document upload requirements
  void validateDocumentUpload({
    required String filePath,
    required DocumentType type,
    required String name,
  }) {
    if (name.trim().isEmpty) {
      throw DocumentValidationException('Document name is required');
    }

    if (filePath.trim().isEmpty) {
      throw DocumentValidationException('File path is required');
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      throw DocumentValidationException('Selected file does not exist');
    }
  }
}

/// Result object for document list pagination
class DocumentListResult {
  final List<Document> documents;
  final bool hasMore;
  final String? nextPageKey;

  const DocumentListResult({
    required this.documents,
    required this.hasMore,
    this.nextPageKey,
  });

  /// Check if there are more documents to load
  bool get canLoadMore => hasMore && nextPageKey != null;

  /// Get total number of documents in current page
  int get count => documents.length;

  /// Get verified documents count
  int get verifiedDocumentsCount {
    return documents.where((d) => d.isVerified).length;
  }

  /// Get pending documents count
  int get pendingDocumentsCount {
    return documents.where((d) => d.isPending).length;
  }

  /// Get total file size for current page documents
  int get totalFileSize {
    return documents.fold(0, (sum, document) => sum + document.fileSize);
  }
}
