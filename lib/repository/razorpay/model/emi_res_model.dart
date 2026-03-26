class EmiPaymentResModel {
  String? status;
  String? message;
  EmiResponseData? emiResData;

  EmiPaymentResModel({this.status, this.message, this.emiResData});

  factory EmiPaymentResModel.fromJson(Map<String, dynamic> json) =>
      EmiPaymentResModel(
        status: json["status"],
        message: json["message"],
        emiResData: json["data"] == null
            ? null
            : EmiResponseData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": emiResData?.toJson(),
  };
}

class EmiResponseData {
  String? orderId;
  num? amount;
  String? currency;
  String? key;
  String? name;
  String? description;
  Prefill? prefill;
  Notes? notes;
  EmiDetails? emiDetails;

  EmiResponseData({
    this.orderId,
    this.amount,
    this.currency,
    this.key,
    this.name,
    this.description,
    this.prefill,
    this.notes,
    this.emiDetails,
  });

  factory EmiResponseData.fromJson(Map<String, dynamic> json) =>
      EmiResponseData(
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
        emiDetails: json["emi_details"] == null
            ? null
            : EmiDetails.fromJson(json["emi_details"]),
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
    "emi_details": emiDetails?.toJson(),
  };
}

class EmiDetails {
  num? installmentNumber;
  DateTime? dueDate;
  bool? isOverdue;
  num? daysOverdue;

  EmiDetails({
    this.installmentNumber,
    this.dueDate,
    this.isOverdue,
    this.daysOverdue,
  });

  factory EmiDetails.fromJson(Map<String, dynamic> json) => EmiDetails(
    installmentNumber: json["installment_number"],
    dueDate: json["due_date"] == null ? null : DateTime.parse(json["due_date"]),
    isOverdue: json["is_overdue"],
    daysOverdue: json["days_overdue"],
  );

  Map<String, dynamic> toJson() => {
    "installment_number": installmentNumber,
    "due_date":
        "${dueDate!.year.toString().padLeft(4, '0')}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}",
    "is_overdue": isOverdue,
    "days_overdue": daysOverdue,
  };
}

class Notes {
  String? enrollmentId;
  String? studentId;
  String? paymentType;
  num? installmentNumber;
  DateTime? dueDate;
  String? enrollmentNumber;
  String? studentName;
  String? studentEmail;
  String? studentPhone;
  String? batchName;

  Notes({
    this.enrollmentId,
    this.studentId,
    this.paymentType,
    this.installmentNumber,
    this.dueDate,
    this.enrollmentNumber,
    this.studentName,
    this.studentEmail,
    this.studentPhone,
    this.batchName,
  });

  factory Notes.fromJson(Map<String, dynamic> json) => Notes(
    enrollmentId: json["enrollment_id"],
    studentId: json["student_id"],
    paymentType: json["payment_type"],
    installmentNumber: json["installment_number"],
    dueDate: json["due_date"] == null ? null : DateTime.parse(json["due_date"]),
    enrollmentNumber: json["enrollment_number"],
    studentName: json["student_name"],
    studentEmail: json["student_email"],
    studentPhone: json["student_phone"],
    batchName: json["batch_name"],
  );

  Map<String, dynamic> toJson() => {
    "enrollment_id": enrollmentId,
    "student_id": studentId,
    "payment_type": paymentType,
    "installment_number": installmentNumber,
    "due_date":
        "${dueDate!.year.toString().padLeft(4, '0')}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}",
    "enrollment_number": enrollmentNumber,
    "student_name": studentName,
    "student_email": studentEmail,
    "student_phone": studentPhone,
    "batch_name": batchName,
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
