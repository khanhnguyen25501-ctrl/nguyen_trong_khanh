class UserModel {
  final int userId;
  final String email;
  final String fullName;
  final String role;
  final String? token;

  UserModel({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      userId: json['userId'] ?? json['id'] ?? 0,
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? json['name'] ?? '',
      role: json['role'] ?? 'Parent',
      token: token ?? json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'fullName': fullName,
      'role': role,
      'token': token,
    };
  }
}
