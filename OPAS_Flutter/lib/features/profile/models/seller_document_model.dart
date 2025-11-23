/// Document Type Enum
/// Represents different types of documents required for seller registration
enum DocumentType {
  businessPermit('BUSINESS_PERMIT', 'Business Permit'),
  governmentId('VALID_GOVERNMENT_ID', 'Government ID');

  final String value;
  final String displayName;

  const DocumentType(this.value, this.displayName);

  /// Convert string value to enum
  static DocumentType fromString(String value) {
    return DocumentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DocumentType.businessPermit,
    );
  }
}

/// Seller Document Model
/// Represents a document uploaded as part of seller registration
class SellerDocument {
  final int id;
  final String documentType;
  final String fileUrl;
  final String status; // PENDING, VERIFIED, REJECTED
  final String? verificationNotes;
  final String? verifiedBy;
  final DateTime uploadedAt;
  final DateTime? verifiedAt;
  final DateTime? expiresAt;

  SellerDocument({
    required this.id,
    required this.documentType,
    required this.fileUrl,
    required this.status,
    this.verificationNotes,
    this.verifiedBy,
    required this.uploadedAt,
    this.verifiedAt,
    this.expiresAt,
  });

  /// Factory constructor to create SellerDocument from JSON
  factory SellerDocument.fromJson(Map<String, dynamic> json) {
    return SellerDocument(
      id: json['id'] as int? ?? 0,
      documentType: json['document_type'] as String? ?? '',
      fileUrl: json['file_url'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      verificationNotes: json['verification_notes'] as String?,
      verifiedBy: json['verified_by'] as String?,
      uploadedAt: DateTime.tryParse(json['uploaded_at'] as String? ?? '') ??
          DateTime.now(),
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
    );
  }

  /// Convert SellerDocument to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'document_type': documentType,
        'file_url': fileUrl,
        'status': status,
        'verification_notes': verificationNotes,
        'verified_by': verifiedBy,
        'uploaded_at': uploadedAt.toIso8601String(),
        'verified_at': verifiedAt?.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
      };

  /// Check if document is verified
  bool get isVerified => status == 'VERIFIED';

  /// Check if document verification is pending
  bool get isPending => status == 'PENDING';

  /// Check if document was rejected
  bool get isRejected => status == 'REJECTED';

  /// Get user-friendly status
  String getStatusDisplay() {
    switch (status) {
      case 'VERIFIED':
        return 'Verified';
      case 'PENDING':
        return 'Pending Review';
      case 'REJECTED':
        return 'Rejected';
      default:
        return status;
    }
  }

  @override
  String toString() =>
      'SellerDocument(id: $id, type: $documentType, status: $status)';
}
