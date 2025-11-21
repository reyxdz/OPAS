class UserModel {
  final String firstName;
  final String lastName;
  final String address;
  final String phoneNumber;
  final String password;

  UserModel({
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.phoneNumber,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'address': address,
      'phone_number': phoneNumber,
      'password': password,
    };
  }
}