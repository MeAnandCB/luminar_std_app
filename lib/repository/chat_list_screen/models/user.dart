class User {
  final int id;
  final String fullName;
  final String? email;
  final String? profilePic;

  User({required this.id, required this.fullName, this.email, this.profilePic});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      profilePic: json['profile_pic'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'profile_pic': profilePic,
    };
  }
}
