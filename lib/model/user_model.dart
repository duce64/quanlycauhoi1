class UserModel {
  final String username;
  final String role;
  final String token;
  final String detail;
  final String department;

  UserModel({
    required this.username,
    required this.role,
    required this.token,
    required this.detail,
    required this.department,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'],
      role: json['role'],
      token: json['token'],
      detail: json['detail'],
      department: json['department'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'role': role,
      'token': token,
      'detail': detail,
      'department': department,
    };
  }
}
