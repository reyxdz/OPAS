import '../../../features/profile/models/registration_status_enum.dart';

/// Admin-focused registration list model
/// Lightweight version for displaying in list views
/// Optimized for admin panel UI with essential information only
class AdminRegistrationListItem {
  final int id;
  final int userId;
  final String buyerName;
  final String buyerPhone;
  final String farmName;
  final String storeName;
  final String status; // PENDING, APPROVED, REJECTED, REQUEST_MORE_INFO
  final String submittedAt;
  final int daysPending;
  final bool hasAllDocuments;

  const AdminRegistrationListItem({
    required this.id,
    required this.userId,
    required this.buyerName,
    required this.buyerPhone,
    required this.farmName,
    required this.storeName,
    required this.status,
    required this.submittedAt,
    required this.daysPending,
    required this.hasAllDocuments,
  });

  /// Factory constructor from API JSON response
  factory AdminRegistrationListItem.fromJson(Map<String, dynamic> json) {
    return AdminRegistrationListItem(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      buyerName: json['buyer_name'] as String? ?? 'Unknown',
      buyerPhone: json['buyer_phone'] as String? ?? 'N/A',
      farmName: json['farm_name'] as String? ?? 'N/A',
      storeName: json['store_name'] as String? ?? 'N/A',
      status: json['status'] as String? ?? 'PENDING',
      submittedAt: json['submitted_at'] as String? ?? '',
      daysPending: json['days_pending'] as int? ?? 0,
      hasAllDocuments: json['has_all_documents'] as bool? ?? false,
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'buyer_name': buyerName,
      'buyer_phone': buyerPhone,
      'farm_name': farmName,
      'store_name': storeName,
      'status': status,
      'submitted_at': submittedAt,
      'days_pending': daysPending,
      'has_all_documents': hasAllDocuments,
    };
  }

  /// Get registration status enum for UI display
  RegistrationStatus get registrationStatus {
    switch (status) {
      case 'APPROVED':
        return RegistrationStatus.approved;
      case 'REJECTED':
        return RegistrationStatus.rejected;
      case 'REQUEST_MORE_INFO':
        return RegistrationStatus.requestMoreInfo;
      default:
        return RegistrationStatus.pending;
    }
  }

  /// Check if registration is pending review
  bool get isPending => status == 'PENDING';

  /// Check if registration is approved
  bool get isApproved => status == 'APPROVED';

  /// Check if registration is rejected
  bool get isRejected => status == 'REJECTED';

  /// Check if more information is requested
  bool get isInfoRequested => status == 'REQUEST_MORE_INFO';

  /// Get user-friendly status display
  String getStatusDisplay() {
    return registrationStatus.getMessage();
  }
}

/// Admin-focused registration detail model
/// Extended version with full registration information
class AdminRegistrationDetail {
  final int id;
  final int userId;
  final String buyerName;
  final String buyerEmail;
  final String buyerPhone;
  final String farmName;
  final String farmLocation;
  final List<String> productsGrown;
  final String storeName;
  final String storeDescription;
  final String status;
  final String submittedAt;
  final String? approvedAt;
  final String? rejectedAt;
  final String? rejectionReason;
  final String? rejectionNotes;
  final int daysPending;
  final List<AdminDocumentVerification> documents;
  final List<AdminApprovalHistory>? approvalHistory;

  const AdminRegistrationDetail({
    required this.id,
    required this.userId,
    required this.buyerName,
    required this.buyerEmail,
    required this.buyerPhone,
    required this.farmName,
    required this.farmLocation,
    required this.productsGrown,
    required this.storeName,
    required this.storeDescription,
    required this.status,
    required this.submittedAt,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.rejectionNotes,
    required this.daysPending,
    required this.documents,
    this.approvalHistory,
  });

  /// Factory constructor from API JSON response
  factory AdminRegistrationDetail.fromJson(Map<String, dynamic> json) {
    final documentsList = json['document_verifications'] as List?;
    final historyList = json['approval_history'] as List?;

    return AdminRegistrationDetail(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      buyerName: json['buyer_name'] as String? ?? 'Unknown',
      buyerEmail: json['buyer_email'] as String? ?? 'N/A',
      buyerPhone: json['buyer_phone'] as String? ?? 'N/A',
      farmName: json['farm_name'] as String? ?? 'N/A',
      farmLocation: json['farm_location'] as String? ?? 'N/A',
      productsGrown: List<String>.from(
        json['products_grown'] as List? ?? [],
      ),
      storeName: json['store_name'] as String? ?? 'N/A',
      storeDescription: json['store_description'] as String? ?? 'N/A',
      status: json['status'] as String? ?? 'PENDING',
      submittedAt: json['submitted_at'] as String? ?? '',
      approvedAt: json['approved_at'] as String?,
      rejectedAt: json['rejected_at'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      rejectionNotes: json['rejection_notes'] as String?,
      daysPending: json['days_pending'] as int? ?? 0,
      documents: (documentsList ?? [])
          .map((doc) => AdminDocumentVerification.fromJson(
            doc as Map<String, dynamic>,
          ))
          .toList(),
      approvalHistory: (historyList ?? [])
          .map((hist) => AdminApprovalHistory.fromJson(
            hist as Map<String, dynamic>,
          ))
          .toList(),
    );
  }

  /// Get registration status enum for UI display
  RegistrationStatus get registrationStatus {
    switch (status) {
      case 'APPROVED':
        return RegistrationStatus.approved;
      case 'REJECTED':
        return RegistrationStatus.rejected;
      case 'REQUEST_MORE_INFO':
        return RegistrationStatus.requestMoreInfo;
      default:
        return RegistrationStatus.pending;
    }
  }

  /// Check if all required documents are verified
  bool get allDocumentsVerified =>
      documents.isNotEmpty && documents.every((doc) => doc.isVerified);

  /// Check if any documents are rejected
  bool get hasRejectedDocuments =>
      documents.any((doc) => doc.isRejected);

  /// Get verified documents
  List<AdminDocumentVerification> getVerifiedDocuments() {
    return documents.where((doc) => doc.isVerified).toList();
  }

  /// Get pending documents
  List<AdminDocumentVerification> getPendingDocuments() {
    return documents.where((doc) => doc.isPending).toList();
  }

  /// Get rejected documents
  List<AdminDocumentVerification> getRejectedDocuments() {
    return documents.where((doc) => doc.isRejected).toList();
  }

  /// Get document by type
  AdminDocumentVerification? getDocumentByType(String type) {
    try {
      return documents.firstWhere((doc) => doc.documentType == type);
    } catch (e) {
      return null;
    }
  }

  /// Get document verification counts
  Map<String, int> getDocumentStats() {
    return {
      'total': documents.length,
      'verified': getVerifiedDocuments().length,
      'pending': getPendingDocuments().length,
      'rejected': getRejectedDocuments().length,
    };
  }
}

/// Admin document verification tracking
class AdminDocumentVerification {
  final int id;
  final String documentType; // BUSINESS_PERMIT, VALID_GOVERNMENT_ID
  final String fileUrl;
  final String status; // PENDING, VERIFIED, REJECTED
  final String? verificationNotes;
  final String? verifiedBy;
  final String uploadedAt;
  final String? verifiedAt;
  final String? expiresAt;

  const AdminDocumentVerification({
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

  /// Factory constructor from API JSON
  factory AdminDocumentVerification.fromJson(Map<String, dynamic> json) {
    return AdminDocumentVerification(
      id: json['id'] as int? ?? 0,
      documentType: json['document_type'] as String? ?? 'UNKNOWN',
      fileUrl: json['file_url'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      verificationNotes: json['verification_notes'] as String?,
      verifiedBy: json['verified_by'] as String?,
      uploadedAt: json['uploaded_at'] as String? ?? '',
      verifiedAt: json['verified_at'] as String?,
      expiresAt: json['expires_at'] as String?,
    );
  }

  /// Check if document is verified
  bool get isVerified => status == 'VERIFIED';

  /// Check if document is pending
  bool get isPending => status == 'PENDING';

  /// Check if document is rejected
  bool get isRejected => status == 'REJECTED';

  /// Get user-friendly status display
  String getStatusDisplay() {
    switch (status) {
      case 'VERIFIED':
        return 'Verified';
      case 'REJECTED':
        return 'Rejected';
      case 'PENDING':
        return 'Pending Review';
      default:
        return 'Unknown';
    }
  }

  /// Get document type display name
  String getDocumentTypeDisplay() {
    switch (documentType) {
      case 'BUSINESS_PERMIT':
        return 'Business Permit';
      case 'VALID_GOVERNMENT_ID':
        return 'Valid Government ID';
      default:
        return 'Document';
    }
  }
}

/// Admin approval history tracking
class AdminApprovalHistory {
  final int id;
  final String adminName;
  final String decision; // APPROVED, REJECTED, REQUEST_MORE_INFO
  final String? decisionReason;
  final String? adminNotes;
  final String createdAt;
  final String? effectiveFrom;

  const AdminApprovalHistory({
    required this.id,
    required this.adminName,
    required this.decision,
    this.decisionReason,
    this.adminNotes,
    required this.createdAt,
    this.effectiveFrom,
  });

  /// Factory constructor from API JSON
  factory AdminApprovalHistory.fromJson(Map<String, dynamic> json) {
    return AdminApprovalHistory(
      id: json['id'] as int? ?? 0,
      adminName: json['admin_name'] as String? ?? 'System',
      decision: json['decision'] as String? ?? 'PENDING',
      decisionReason: json['decision_reason'] as String?,
      adminNotes: json['admin_notes'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      effectiveFrom: json['effective_from'] as String?,
    );
  }

  /// Get user-friendly decision display
  String getDecisionDisplay() {
    switch (decision) {
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      case 'REQUEST_MORE_INFO':
        return 'Requested More Information';
      default:
        return 'Unknown';
    }
  }
}
