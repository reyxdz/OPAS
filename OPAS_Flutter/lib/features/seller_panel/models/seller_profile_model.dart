/// Seller Profile Model
/// Represents a seller's profile information including farm and store details
class SellerProfile {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String farmName;
  final String farmLocation;
  final String storeName;
  final String storeDescription;
  final String sellerStatus; // PENDING, APPROVED, REJECTED, SUSPENDED
  final bool isApproved;
  final bool documentsVerified;
  final String? suspensionReason;
  final DateTime? approvalDate;
  final DateTime? suspendedAt;

  SellerProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.farmName,
    required this.farmLocation,
    required this.storeName,
    required this.storeDescription,
    required this.sellerStatus,
    required this.isApproved,
    required this.documentsVerified,
    this.suspensionReason,
    this.approvalDate,
    this.suspendedAt,
  });

  factory SellerProfile.fromJson(Map<String, dynamic> json) {
    return SellerProfile(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      farmName: json['farm_name'] ?? '',
      farmLocation: json['farm_location'] ?? '',
      storeName: json['store_name'] ?? '',
      storeDescription: json['store_description'] ?? '',
      sellerStatus: json['seller_status'] ?? 'PENDING',
      isApproved: json['is_seller_approved'] ?? false,
      documentsVerified: json['seller_documents_verified'] ?? false,
      suspensionReason: json['suspension_reason'],
      approvalDate: json['seller_approval_date'] != null
          ? DateTime.parse(json['seller_approval_date'])
          : null,
      suspendedAt: json['suspended_at'] != null
          ? DateTime.parse(json['suspended_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'phone_number': phoneNumber,
    'farm_name': farmName,
    'farm_location': farmLocation,
    'store_name': storeName,
    'store_description': storeDescription,
    'seller_status': sellerStatus,
    'is_seller_approved': isApproved,
    'seller_documents_verified': documentsVerified,
    'suspension_reason': suspensionReason,
    'seller_approval_date': approvalDate?.toIso8601String(),
    'suspended_at': suspendedAt?.toIso8601String(),
  };

  String get fullName => '$firstName $lastName';
  bool get isPending => sellerStatus == 'PENDING';
  bool get isRejected => sellerStatus == 'REJECTED';
  bool get isSuspended => sellerStatus == 'SUSPENDED';
}
