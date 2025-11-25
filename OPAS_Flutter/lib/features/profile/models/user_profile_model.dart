class UserProfile {
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String address;
  final String? municipality;
  final String? barangay;
  final String? farmMunicipality;
  final String? farmBarangay;

  UserProfile({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.address,
    this.municipality,
    this.barangay,
    this.farmMunicipality,
    this.farmBarangay,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'] ?? '',
      municipality: json['municipality'],
      barangay: json['barangay'],
      farmMunicipality: json['farm_municipality'],
      farmBarangay: json['farm_barangay'],
    );
  }

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'phone_number': phoneNumber,
    'address': address,
    'municipality': municipality,
    'barangay': barangay,
    'farm_municipality': farmMunicipality,
    'farm_barangay': farmBarangay,
  };
}