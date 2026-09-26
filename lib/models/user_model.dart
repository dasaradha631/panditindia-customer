/// Customer / devotee account (PDF section 7 - models/user_model.dart).
class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    this.mobile,
    this.email,
    this.role = 'customer',
    this.avatarUrl,
    this.city,
  });

  final String id;
  final String fullName;
  final String? mobile;
  final String? email;
  final String role;
  final String? avatarUrl;
  final String? city;

  String get initials {
    final List<String> parts =
        fullName.trim().split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  String get displayName => fullName.isEmpty ? 'Devotee' : fullName;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: '${json['id'] ?? ''}',
        fullName: '${json['full_name'] ?? json['name'] ?? ''}',
        mobile: json['mobile'] as String?,
        email: json['email'] as String?,
        role: '${json['role'] ?? 'customer'}',
        avatarUrl: json['avatar_url'] as String?,
        city: json['city'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'full_name': fullName,
        'mobile': mobile,
        'email': email,
        'role': role,
        'avatar_url': avatarUrl,
        'city': city,
      };
}
