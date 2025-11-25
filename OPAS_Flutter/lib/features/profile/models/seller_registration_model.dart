import 'seller_document_model.dart';
import 'registration_status_enum.dart';

/// Seller Registration Model
/// Represents the complete seller registration request with all details and documents
class SellerRegistration {
  final int id;
  final int userId;
  final String farmName;
  final String farmLocation;
  final List<String> productsGrown; // ['fruits', 'vegetables', 'livestock', 'others']
  final String storeName;
  final String storeDescription;
  final RegistrationStatus status;
  final String? rejectionReason;
  final String? rejectionNotes;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final List<SellerDocument> documents;

  SellerRegistration({
    required this.id,
    required this.userId,
    required this.farmName,
    required this.farmLocation,
    required this.productsGrown,
    required this.storeName,
    required this.storeDescription,
    required this.status,
    this.rejectionReason,
    this.rejectionNotes,
    required this.submittedAt,
    this.reviewedAt,
    this.approvedAt,
    this.rejectedAt,
    required this.documents,
  });

  /// Factory constructor to create SellerRegistration from JSON
  factory SellerRegistration.fromJson(Map<String, dynamic> json) {
    final documentsList = json['document_verifications'] as List<dynamic>? ?? [];
    final productsGrown = (json['products_grown'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return SellerRegistration(
      id: json['id'] as int? ?? 0,
      userId: json['seller'] as int? ?? 0,
      farmName: json['farm_name'] as String? ?? '',
      farmLocation: json['farm_location'] as String? ?? '',
      productsGrown: productsGrown,
      storeName: json['store_name'] as String? ?? '',
      storeDescription: json['store_description'] as String? ?? '',
      status: RegistrationStatus.fromString(
          json['status'] as String? ?? 'PENDING'),
      rejectionReason: json['rejection_reason'] as String?,
      rejectionNotes: json['rejection_notes'] as String?,
      submittedAt: DateTime.tryParse(json['submitted_at'] as String? ?? '') ??
          DateTime.now(),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'] as String)
          : null,
      approvedAt: json['approved_at'] != null
          ? DateTime.tryParse(json['approved_at'] as String)
          : null,
      rejectedAt: json['rejected_at'] != null
          ? DateTime.tryParse(json['rejected_at'] as String)
          : null,
      documents: documentsList
          .map((doc) => SellerDocument.fromJson(doc as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convert SellerRegistration to JSON for API submission
  Map<String, dynamic> toJson() => {
        'farm_name': farmName,
        'farm_location': farmLocation,
        'products_grown': productsGrown,
        'store_name': storeName,
        'store_description': storeDescription,
      };

  /// Check if all required documents are present
  bool hasAllRequiredDocuments() {
    final requiredTypes = ['BUSINESS_PERMIT', 'VALID_GOVERNMENT_ID'];
    final documentTypes = documents.map((doc) => doc.documentType).toList();
    return requiredTypes.every((type) => documentTypes.contains(type));
  }

  /// Check if all documents are verified
  bool allDocumentsVerified() {
    if (documents.isEmpty) return false;
    return documents.every((doc) => doc.isVerified);
  }

  /// Get number of days since submission
  int getDaysPending() {
    final now = DateTime.now();
    return now.difference(submittedAt).inDays;
  }

  /// Get list of verified documents
  List<SellerDocument> getVerifiedDocuments() {
    return documents.where((doc) => doc.isVerified).toList();
  }

  /// Get list of pending documents
  List<SellerDocument> getPendingDocuments() {
    return documents.where((doc) => doc.isPending).toList();
  }

  /// Get list of rejected documents
  List<SellerDocument> getRejectedDocuments() {
    return documents.where((doc) => doc.isRejected).toList();
  }

  /// Get document by type
  SellerDocument? getDocumentByType(String documentType) {
    try {
      return documents.firstWhere((doc) => doc.documentType == documentType);
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() =>
      'SellerRegistration(id: $id, farmName: $farmName, status: ${status.displayName})';
}
