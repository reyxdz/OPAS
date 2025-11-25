class SignupRequestModel {
  final String username;
  final String firstName;
  final String lastName;
  final String password;
  final String phoneNumber;
  final String address;
  final String municipality;
  final String barangay;
  final String? farmMunicipality;
  final String? farmBarangay;

  SignupRequestModel({
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.password,
    required this.phoneNumber,
    required this.address,
    required this.municipality,
    required this.barangay,
    this.farmMunicipality,
    this.farmBarangay,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'password': password,
      'phone_number': phoneNumber,
      'address': address,
      'municipality': municipality,
      'barangay': barangay,
      'farm_municipality': farmMunicipality,
      'farm_barangay': farmBarangay,
    };
  }
}