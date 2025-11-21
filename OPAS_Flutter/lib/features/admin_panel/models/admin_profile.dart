class AdminProfile {
  final int? id;
  final String firstName;
  final String lastName;
  final String? email;
  final String phoneNumber;
  final String adminRole;
  final String? address;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final String? profilePicture;

  AdminProfile({
    this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.phoneNumber,
    required this.adminRole,
    this.address,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.profilePicture,
  });

  /// Get full name
  String get fullName => '$firstName $lastName';

  /// Get display name
  String get displayName => fullName.isNotEmpty ? fullName : phoneNumber;

  /// Check if admin is super admin
  bool get isSystemAdmin => adminRole == 'SYSTEM_ADMIN';

  /// Check if admin is regular OPAS admin
  bool get isOPASAdmin => adminRole == 'OPAS_ADMIN';

  /// Create from JSON (from API response)
  factory AdminProfile.fromJson(Map<String, dynamic> json) {
    return AdminProfile(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'],
      phoneNumber: json['phone_number'] ?? '',
      adminRole: json['role'] ?? 'OPAS_ADMIN',
      address: json['address'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : null,
      isActive: json['is_active'] ?? true,
      profilePicture: json['profile_picture'],
    );
  }

  /// Create from SharedPreferences (stored locally)
  factory AdminProfile.fromLocalStorage({
    required String firstName,
    required String lastName,
    String? email,
    required String phoneNumber,
    required String adminRole,
    String? address,
    String? profilePicture,
  }) {
    return AdminProfile(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      adminRole: adminRole,
      address: address,
      createdAt: DateTime.now(),
      isActive: true,
      profilePicture: profilePicture,
    );
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'phone_number': phoneNumber,
    'role': adminRole,
    'address': address,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'is_active': isActive,
    'profile_picture': profilePicture,
  };

  /// Copy with modified fields
  AdminProfile copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? adminRole,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? profilePicture,
  }) {
    return AdminProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      adminRole: adminRole ?? this.adminRole,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }

  @override
  String toString() => 'AdminProfile(id: $id, name: $fullName, role: $adminRole, phone: $phoneNumber)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          phoneNumber == other.phoneNumber;

  @override
  int get hashCode => id.hashCode ^ phoneNumber.hashCode;
}
