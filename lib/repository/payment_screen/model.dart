// API Response Models
class EnrollmentDetailResponse {
  final String? uid;
  final String? enrollmentNumber;
  final String? statusName;
  final String? statusValue;
  final String? statusColor;
  final String? enrollmentDate;
  final String? studentName;
  final String? studentId;
  final String? studentEmail;
  final String? studentPhone;
  final BatchInfo? batch;
  final String? paymentType;
  final double? originalCourseFees;
  final double? totalAmountPaid;
  final double? totalPendingAmount;
  final double? netFees;
  final double? paymentCompletionPercentage;
  final String? nextEmiDueDate;
  final List<PaymentTransaction>? paymentTransactions;
  final List<EmiInstallmentModel>? emiInstallments;
  final bool? isPaymentOverdue;
  final String? attendanceMode;
  final double? attendancePercentage;
  final double? completionPercentage;

  EnrollmentDetailResponse({
    this.uid,
    this.enrollmentNumber,
    this.statusName,
    this.statusValue,
    this.statusColor,
    this.enrollmentDate,
    this.studentName,
    this.studentId,
    this.studentEmail,
    this.studentPhone,
    this.batch,
    this.paymentType,
    this.originalCourseFees,
    this.totalAmountPaid,
    this.totalPendingAmount,
    this.netFees,
    this.paymentCompletionPercentage,
    this.nextEmiDueDate,
    this.paymentTransactions,
    this.emiInstallments,
    this.isPaymentOverdue,
    this.attendanceMode,
    this.attendancePercentage,
    this.completionPercentage,
  });

  factory EnrollmentDetailResponse.fromJson(Map<String, dynamic> json) {
    return EnrollmentDetailResponse(
      uid: json['uid']?.toString(),
      enrollmentNumber: json['enrollment_number']?.toString(),
      statusName: json['status_name']?.toString(),
      statusValue: json['status_value']?.toString(),
      statusColor: json['status_color']?.toString(),
      enrollmentDate: json['enrollment_date']?.toString(),
      studentName: json['student_name']?.toString(),
      studentId: json['student_id']?.toString(),
      studentEmail: json['student_email']?.toString(),
      studentPhone: json['student_phone']?.toString(),
      batch: json['batch'] != null ? BatchInfo.fromJson(json['batch']) : null,
      paymentType: json['payment_type']?.toString(),
      originalCourseFees: _parseDouble(json['original_course_fees']),
      totalAmountPaid: _parseDouble(json['total_amount_paid']),
      totalPendingAmount: _parseDouble(json['total_pending_amount']),
      netFees: _parseDouble(json['net_fees']),
      paymentCompletionPercentage: _parseDouble(
        json['payment_completion_percentage'],
      ),
      nextEmiDueDate: json['next_emi_due_date']?.toString(),
      paymentTransactions: json['payment_transactions'] != null
          ? List<PaymentTransaction>.from(
              json['payment_transactions'].map(
                (x) => PaymentTransaction.fromJson(x),
              ),
            )
          : [],
      emiInstallments: json['emi_installments'] != null
          ? List<EmiInstallmentModel>.from(
              json['emi_installments'].map(
                (x) => EmiInstallmentModel.fromJson(x),
              ),
            )
          : [],
      isPaymentOverdue: json['is_payment_overdue'],
      attendanceMode: json['attendance_mode']?['name']?.toString(),
      attendancePercentage: _parseDouble(json['attendance_percentage']),
      completionPercentage: _parseDouble(json['completion_percentage']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class BatchInfo {
  final String? uid;
  final String? batchName;
  final String? courseName;
  final String? startDate;
  final String? endDate;
  final String? time;
  final String? status;
  final List<String>? counselorNames;
  final List<String>? trainerNames;

  BatchInfo({
    this.uid,
    this.batchName,
    this.courseName,
    this.startDate,
    this.endDate,
    this.time,
    this.status,
    this.counselorNames,
    this.trainerNames,
  });

  factory BatchInfo.fromJson(Map<String, dynamic> json) {
    return BatchInfo(
      uid: json['uid']?.toString(),
      batchName: json['batch_name']?.toString(),
      courseName: json['course_name']?.toString(),
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      time: json['time']?.toString(),
      status: json['status']?.toString(),
      counselorNames: json['counselor_names'] != null
          ? List<String>.from(json['counselor_names'].map((x) => x.toString()))
          : [],
      trainerNames: json['trainer_names'] != null
          ? List<String>.from(json['trainer_names'].map((x) => x.toString()))
          : [],
    );
  }
}

class PaymentTransaction {
  final String? uid;
  final String? transactionId;
  final double? amount;
  final String? paymentMethod;
  final String? paymentMethodDisplay;
  final String? status;
  final String? statusDisplay;
  final DateTime? paymentDate;

  PaymentTransaction({
    this.uid,
    this.transactionId,
    this.amount,
    this.paymentMethod,
    this.paymentMethodDisplay,
    this.status,
    this.statusDisplay,
    this.paymentDate,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      uid: json['uid']?.toString(),
      transactionId: json['transaction_id']?.toString(),
      amount: json['amount'] != null
          ? double.tryParse(json['amount'].toString())
          : null,
      paymentMethod: json['payment_method']?.toString(),
      paymentMethodDisplay: json['payment_method_display']?.toString(),
      status: json['status']?.toString(),
      statusDisplay: json['status_display']?.toString(),
      paymentDate: json['payment_date'] != null
          ? DateTime.tryParse(json['payment_date'].toString())
          : null,
    );
  }
}

class EmiInstallmentModel {
  final String? uid;
  final int? installmentNumber;
  final double? totalAmount;
  final double? paidAmount;
  final double? pendingAmount;
  final DateTime? dueDate;
  final String? status;
  final DateTime? paidDate;
  final bool? isOverdue;
  final int? daysOverdue;

  EmiInstallmentModel({
    this.uid,
    this.installmentNumber,
    this.totalAmount,
    this.paidAmount,
    this.pendingAmount,
    this.dueDate,
    this.status,
    this.paidDate,
    this.isOverdue,
    this.daysOverdue,
  });

  factory EmiInstallmentModel.fromJson(Map<String, dynamic> json) {
    return EmiInstallmentModel(
      uid: json['uid']?.toString(),
      installmentNumber: json['installment_number'] != null
          ? int.tryParse(json['installment_number'].toString())
          : null,
      totalAmount: json['total_amount'] != null
          ? double.tryParse(json['total_amount'].toString())
          : null,
      paidAmount: json['paid_amount'] != null
          ? double.tryParse(json['paid_amount'].toString())
          : null,
      pendingAmount: json['pending_amount'] != null
          ? double.tryParse(json['pending_amount'].toString())
          : null,
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'].toString())
          : null,
      status: json['status']?.toString(),
      paidDate: json['paid_date'] != null
          ? DateTime.tryParse(json['paid_date'].toString())
          : null,
      isOverdue: json['is_overdue'],
      daysOverdue: json['days_overdue'] != null
          ? int.tryParse(json['days_overdue'].toString())
          : null,
    );
  }
}

// UI Enums
enum TransactionStatus { completed, failed, pending }

enum EmiStatus { paid, pending, overdue }

// UI Models
class Transaction {
  final String id;
  final DateTime date;
  final String method;
  final double amount;
  final TransactionStatus status;

  Transaction({
    required this.id,
    required this.date,
    required this.method,
    required this.amount,
    required this.status,
  });
}

class EmiInstallment {
  final int number;
  final DateTime dueDate;
  final double amount;
  final EmiStatus status;

  EmiInstallment({
    required this.number,
    required this.dueDate,
    required this.amount,
    required this.status,
  });
}

class PaymentData {
  final String enrollmentId;
  final String enrollmentUid;
  final String courseName;
  final String batchName;
  final double totalFee;
  final double paidAmount;
  final double remainingAmount;
  final String paymentType;
  final double nextDueAmount;
  final DateTime nextDueDate;
  final double progress;
  final List<Transaction> transactions;
  final List<EmiInstallment> emiSchedule;
  final bool isOverdue;
  final String studentName;
  final String studentId;

  PaymentData({
    required this.enrollmentId,
    required this.enrollmentUid,
    required this.courseName,
    required this.batchName,
    required this.totalFee,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentType,
    required this.nextDueAmount,
    required this.nextDueDate,
    required this.progress,
    required this.transactions,
    required this.emiSchedule,
    required this.isOverdue,
    required this.studentName,
    required this.studentId,
  });
}
