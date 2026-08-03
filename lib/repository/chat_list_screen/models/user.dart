import 'package:luminar_std/core/utils/app_utils.dart';

class User {
  final int id;
  final String fullName;
  final String? email;
  final String? profilePic;

  User({required this.id, required this.fullName, this.email, this.profilePic});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: json['full_name']?.toString() ?? '',
      email: json['email'],
      profilePic: AppUtils.getAbsoluteUrl(json['profile_pic'] ?? json['profile_picture']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'profile_pic': profilePic,
      'profile_picture': profilePic,
    };
  }
}
