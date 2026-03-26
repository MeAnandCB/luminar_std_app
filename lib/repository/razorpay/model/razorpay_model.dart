class PaymentResModel {
  String? status;
  String? message;
  RazorpayPaymentDetails? paymentDetails;

  PaymentResModel({this.status, this.message, this.paymentDetails});

  factory PaymentResModel.fromJson(Map<String, dynamic> json) =>
      PaymentResModel(
        status: json["status"],
        message: json["message"],
        paymentDetails: json["data"] == null
            ? null
            : RazorpayPaymentDetails.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": paymentDetails?.toJson(),
  };
}

class RazorpayPaymentDetails {
  String? orderId;
  num? amount;
  String? currency;
  String? key;
  String? name;
  String? description;
  Prefill? prefill;
  Notes? notes;
  String? userType;
  DiscountInfo? discountInfo;

  RazorpayPaymentDetails({
    this.orderId,
    this.amount,
    this.currency,
    this.key,
    this.name,
    this.description,
    this.prefill,
    this.notes,
    this.userType,
    this.discountInfo,
  });

  factory RazorpayPaymentDetails.fromJson(Map<String, dynamic> json) =>
      RazorpayPaymentDetails(
        orderId: json["order_id"],
        amount: json["amount"],
        currency: json["currency"],
        key: json["key"],
        name: json["name"],
        description: json["description"],
        prefill: json["prefill"] == null
            ? null
            : Prefill.fromJson(json["prefill"]),
        notes: json["notes"] == null ? null : Notes.fromJson(json["notes"]),
        userType: json["user_type"],
        discountInfo: json["discount_info"] == null
            ? null
            : DiscountInfo.fromJson(json["discount_info"]),
      );

  Map<String, dynamic> toJson() => {
    "order_id": orderId,
    "amount": amount,
    "currency": currency,
    "key": key,
    "name": name,
    "description": description,
    "prefill": prefill?.toJson(),
    "notes": notes?.toJson(),
    "user_type": userType,
    "discount_info": discountInfo?.toJson(),
  };
}

class DiscountInfo {
  num? courseFeesDiscount;
  num? basePendingAmount;
  num? discountedPendingAmount;
  bool? discountApplied;

  DiscountInfo({
    this.courseFeesDiscount,
    this.basePendingAmount,
    this.discountedPendingAmount,
    this.discountApplied,
  });

  factory DiscountInfo.fromJson(Map<String, dynamic> json) => DiscountInfo(
    courseFeesDiscount: json["course_fees_discount"],
    basePendingAmount: json["base_pending_amount"],
    discountedPendingAmount: json["discounted_pending_amount"],
    discountApplied: json["discount_applied"],
  );

  Map<String, dynamic> toJson() => {
    "course_fees_discount": courseFeesDiscount,
    "base_pending_amount": basePendingAmount,
    "discounted_pending_amount": discountedPendingAmount,
    "discount_applied": discountApplied,
  };
}

class Notes {
  String? enrollmentId;
  String? studentId;
  String? paymentType;
  String? enrollmentNumber;
  String? studentName;
  String? studentEmail;
  String? studentPhone;
  String? userType;
  String? courseFeesDiscount;
  String? basePendingAmount;
  String? discountedPendingAmount;

  Notes({
    this.enrollmentId,
    this.studentId,
    this.paymentType,
    this.enrollmentNumber,
    this.studentName,
    this.studentEmail,
    this.studentPhone,
    this.userType,
    this.courseFeesDiscount,
    this.basePendingAmount,
    this.discountedPendingAmount,
  });

  factory Notes.fromJson(Map<String, dynamic> json) => Notes(
    enrollmentId: json["enrollment_id"],
    studentId: json["student_id"],
    paymentType: json["payment_type"],
    enrollmentNumber: json["enrollment_number"],
    studentName: json["student_name"],
    studentEmail: json["student_email"],
    studentPhone: json["student_phone"],
    userType: json["user_type"],
    courseFeesDiscount: json["course_fees_discount"],
    basePendingAmount: json["base_pending_amount"],
    discountedPendingAmount: json["discounted_pending_amount"],
  );

  Map<String, dynamic> toJson() => {
    "enrollment_id": enrollmentId,
    "student_id": studentId,
    "payment_type": paymentType,
    "enrollment_number": enrollmentNumber,
    "student_name": studentName,
    "student_email": studentEmail,
    "student_phone": studentPhone,
    "user_type": userType,
    "course_fees_discount": courseFeesDiscount,
    "base_pending_amount": basePendingAmount,
    "discounted_pending_amount": discountedPendingAmount,
  };
}

class Prefill {
  String? name;
  String? email;
  String? contact;

  Prefill({this.name, this.email, this.contact});

  factory Prefill.fromJson(Map<String, dynamic> json) => Prefill(
    name: json["name"],
    email: json["email"],
    contact: json["contact"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "email": email,
    "contact": contact,
  };
}
