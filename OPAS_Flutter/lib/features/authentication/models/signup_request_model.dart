class SignupRequestModel {
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String password;
  final String phoneNumber;
  final String address;
  final String municipality;
  final String barangay;

  SignupRequestModel({
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.password,
    required this.phoneNumber,
    required this.address,
    required this.municipality,
    required this.barangay,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'password': password,
      'phone_number': phoneNumber,
      'address': address,
      'municipality': municipality,
      'barangay': barangay,
    };
  }
}