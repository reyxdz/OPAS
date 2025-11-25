class UserProfile {
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String address;
  final String? municipality;
  final String? barangay;

  UserProfile({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.address,
    this.municipality,
    this.barangay,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'] ?? '',
      municipality: json['municipality'],
      barangay: json['barangay'],
    );
  }

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'phone_number': phoneNumber,
    'address': address,
    'municipality': municipality,
    'barangay': barangay,
  };
}