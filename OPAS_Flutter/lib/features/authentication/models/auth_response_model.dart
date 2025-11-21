class AuthResponseModel {
  final String? access;
  final String? refresh;
  final String? email;
  final String? role;

  AuthResponseModel({
    this.access,
    this.refresh,
    this.email,
    this.role,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      access: json['access'],
      refresh: json['refresh'],
      email: json['email'],
      role: json['role'],
    );
  }
}