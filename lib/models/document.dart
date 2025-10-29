import 'dart:convert';

/// Document type enumeration
enum DocumentType {
  identity,
  farmTitle,
  businessRegistration,
  taxClearance,
  bankStatement,
  farmPlan,
  insurance,
  other;

  String get value => name;

  static DocumentType fromString(String type) {
    return DocumentType.values.firstWhere(
      (e) => e.value == type,
      orElse: () => DocumentType.other,
    );
  }

  String get displayName {
    switch (this) {
      case DocumentType.identity:
        return 'Government ID';
      case DocumentType.farmTitle:
        return 'Farm Title/Lease';
      case DocumentType.businessRegistration:
        return 'Business Registration';
      case DocumentType.taxClearance:
        return 'Tax Clearance';
      case DocumentType.bankStatement:
        return 'Bank Statement';
      case DocumentType.farmPlan:
        return 'Farm Plan';
      case DocumentType.insurance:
        return 'Insurance Document';
      case DocumentType.other:
        return 'Other Document';
    }
  }
}

/// Document verification status enumeration
enum DocumentStatus {
  pending,
  inReview,
  verified,
  rejected,
  expired;

  String get value => name;

  static DocumentStatus fromString(String status) {
    return DocumentStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => DocumentStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case DocumentStatus.pending:
        return 'Pending Upload';
      case DocumentStatus.inReview:
        return 'Under Review';
      case DocumentStatus.verified:
        return 'Verified';
      case DocumentStatus.rejected:
        return 'Rejected';
      case DocumentStatus.expired:
        return 'Expired';
    }
  }
}

/// Document model for handling user document uploads and verification
class Document {
  final String id;
  final String ownerId;
  final String ownerName;
  final String? campaignId;
  final DocumentType type;
  final String name;
  final String fileName;
  final String fileUrl;
  final String mimeType;
  final int fileSize;
  final DocumentStatus status;
  final String? rejectionReason;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final DateTime? expiryDate;
  final DateTime uploadedAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const Document({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.campaignId,
    required this.type,
    required this.name,
    required this.fileName,
    required this.fileUrl,
    required this.mimeType,
    required this.fileSize,
    required this.status,
    this.rejectionReason,
    this.verifiedBy,
    this.verifiedAt,
    this.expiryDate,
    required this.uploadedAt,
    required this.updatedAt,
    this.metadata,
  });

  /// Check if document is verified
  bool get isVerified => status == DocumentStatus.verified;

  /// Check if document is rejected
  bool get isRejected => status == DocumentStatus.rejected;

  /// Check if document is pending verification
  bool get isPending => status == DocumentStatus.pending || status == DocumentStatus.inReview;

  /// Check if document is expired
  bool get isExpired => 
      status == DocumentStatus.expired || 
      (expiryDate != null && DateTime.now().isAfter(expiryDate!));

  /// Get formatted file size
  String get formattedFileSize {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Get file extension
  String get fileExtension {
    final parts = fileName.split('.');
    return parts.isNotEmpty ? parts.last.toLowerCase() : '';
  }

  /// Check if document is an image
  bool get isImage => ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExtension);

  /// Check if document is a PDF
  bool get isPdf => fileExtension == 'pdf';

  /// Create Document from JSON
  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      ownerName: json['ownerName'] as String? ?? '',
      campaignId: json['campaignId'] as String?,
      type: DocumentType.fromString(json['type'] as String? ?? 'other'),
      name: json['name'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? '',
      fileSize: json['fileSize'] as int? ?? 0,
      status: DocumentStatus.fromString(json['status'] as String? ?? 'pending'),
      rejectionReason: json['rejectionReason'] as String?,
      verifiedBy: json['verifiedBy'] as String?,
      verifiedAt: json['verifiedAt'] != null 
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
      expiryDate: json['expiryDate'] != null 
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert Document to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'ownerName': ownerName,
      if (campaignId != null) 'campaignId': campaignId,
      'type': type.value,
      'name': name,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'status': status.value,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (verifiedBy != null) 'verifiedBy': verifiedBy,
      if (verifiedAt != null) 'verifiedAt': verifiedAt!.toIso8601String(),
      if (expiryDate != null) 'expiryDate': expiryDate!.toIso8601String(),
      'uploadedAt': uploadedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  Document copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    String? campaignId,
    DocumentType? type,
    String? name,
    String? fileName,
    String? fileUrl,
    String? mimeType,
    int? fileSize,
    DocumentStatus? status,
    String? rejectionReason,
    String? verifiedBy,
    DateTime? verifiedAt,
    DateTime? expiryDate,
    DateTime? uploadedAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Document(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      campaignId: campaignId ?? this.campaignId,
      type: type ?? this.type,
      name: name ?? this.name,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      expiryDate: expiryDate ?? this.expiryDate,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'Document(id: $id, type: ${type.displayName}, status: ${status.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Document && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
