// lib/models/user_model.dart

class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? avatar;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String? sanitizeUrl(String? url) {
      if (url == null || url.isEmpty) return null;
      if (url.contains('localhost')) {
        return url.replaceAll('localhost', '10.140.183.183');
      }
      if (url.contains('127.0.0.1')) {
        return url.replaceAll('127.0.0.1', '10.140.183.183');
      }
      if (!url.startsWith('http')) {
        return 'http://10.140.183.183:8000/storage/$url';
      }
      return url;
    }

    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'user',
      avatar: sanitizeUrl(json['avatar'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'avatar': avatar,
      };
}
