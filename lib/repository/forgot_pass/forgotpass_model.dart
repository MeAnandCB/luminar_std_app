class ForgotPassModel {
  bool? success;
  String? message;
  String? email;

  ForgotPassModel({this.success, this.message, this.email});

  factory ForgotPassModel.fromJson(Map<String, dynamic> json) =>
      ForgotPassModel(
        success: json["success"],
        message: json["message"],
        email: json["email"],
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "email": email,
  };
}
