class LoginResponseModel {
  final String status;
  final String message;
  final Tokens tokens;
  final StudentData student;

  LoginResponseModel({
    required this.status,
    required this.message,
    required this.tokens,
    required this.student,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      tokens: Tokens.fromJson(json['tokens'] ?? {}),
      student: StudentData.fromJson(json['student'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'tokens': tokens.toJson(),
      'student': student.toJson(),
    };
  }
}

class Tokens {
  final String refresh;
  final String access;

  Tokens({required this.refresh, required this.access});

  factory Tokens.fromJson(Map<String, dynamic> json) {
    return Tokens(refresh: json['refresh'] ?? '', access: json['access'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'refresh': refresh, 'access': access};
  }
}

class StudentData {
  final StudentProfile profile;
  final GuardianInfo guardianInfo;
  final Counselor counselor;
  final EnrollmentSummary enrollmentSummary;
  final List<dynamic> currentEnrollments;
  final FinancialSummary financialSummary;
  final dynamic placementInfo;
  final List<Activity> recentActivities;
  final List<dynamic> upcomingPayments;
  final ReferralInfo referralInfo;
  final PortalSettings portalSettings;
  final QuickStats quickStats;

  StudentData({
    required this.profile,
    required this.guardianInfo,
    required this.counselor,
    required this.enrollmentSummary,
    required this.currentEnrollments,
    required this.financialSummary,
    this.placementInfo,
    required this.recentActivities,
    required this.upcomingPayments,
    required this.referralInfo,
    required this.portalSettings,
    required this.quickStats,
  });

  factory StudentData.fromJson(Map<String, dynamic> json) {
    return StudentData(
      profile: StudentProfile.fromJson(json['profile'] ?? {}),
      guardianInfo: GuardianInfo.fromJson(json['guardian_info'] ?? {}),
      counselor: Counselor.fromJson(json['counselor'] ?? {}),
      enrollmentSummary: EnrollmentSummary.fromJson(
        json['enrollment_summary'] ?? {},
      ),
      currentEnrollments: json['current_enrollments'] ?? [],
      financialSummary: FinancialSummary.fromJson(
        json['financial_summary'] ?? {},
      ),
      placementInfo: json['placement_info'],
      recentActivities: (json['recent_activities'] as List? ?? [])
          .map((item) => Activity.fromJson(item ?? {}))
          .toList(),
      upcomingPayments: json['upcoming_payments'] ?? [],
      referralInfo: ReferralInfo.fromJson(json['referral_info'] ?? {}),
      portalSettings: PortalSettings.fromJson(json['portal_settings'] ?? {}),
      quickStats: QuickStats.fromJson(json['quick_stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile': profile.toJson(),
      'guardian_info': guardianInfo.toJson(),
      'counselor': counselor.toJson(),
      'enrollment_summary': enrollmentSummary.toJson(),
      'current_enrollments': currentEnrollments,
      'financial_summary': financialSummary.toJson(),
      'placement_info': placementInfo,
      'recent_activities': recentActivities.map((a) => a.toJson()).toList(),
      'upcoming_payments': upcomingPayments,
      'referral_info': referralInfo.toJson(),
      'portal_settings': portalSettings.toJson(),
      'quick_stats': quickStats.toJson(),
    };
  }
}

class StudentProfile {
  final String studentId;
  final String fullName;
  final String email;
  final String phone;
  final String whatsappNumber;
  final String profilePicture;
  final String dateOfBirth;
  final int age;
  final Qualification qualification;
  final String college;
  final int passOutYear;
  final String specialization;
  final double cgpa;
  final bool anyArrears;
  final PreferredLocation preferredLocation;
  final String address;
  final String pincode;
  final String district;
  final String studentOrWorkingProfessional;
  final bool placementAssistance;
  final String preferredJobLocation;
  final String admissionDate;
  final Status status;
  final bool isAlumni;
  final bool isPlaced;

  StudentProfile({
    required this.studentId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.whatsappNumber,
    required this.profilePicture,
    required this.dateOfBirth,
    required this.age,
    required this.qualification,
    required this.college,
    required this.passOutYear,
    required this.specialization,
    required this.cgpa,
    required this.anyArrears,
    required this.preferredLocation,
    required this.address,
    required this.pincode,
    required this.district,
    required this.studentOrWorkingProfessional,
    required this.placementAssistance,
    required this.preferredJobLocation,
    required this.admissionDate,
    required this.status,
    required this.isAlumni,
    required this.isPlaced,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      studentId: json['student_id'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      whatsappNumber: json['whatsapp_number'] ?? '',
      profilePicture: json['profile_picture'] ?? '',
      dateOfBirth: json['date_of_birth'] ?? '',
      age: json['age'] ?? 0,
      qualification: Qualification.fromJson(json['qualification'] ?? {}),
      college: json['college'] ?? '',
      passOutYear: json['pass_out_year'] ?? 0,
      specialization: json['specialization'] ?? '',
      cgpa: (json['cgpa'] ?? 0.0).toDouble(),
      anyArrears: json['any_arrears'] ?? false,
      preferredLocation: PreferredLocation.fromJson(
        json['preferred_location'] ?? {},
      ),
      address: json['address'] ?? '',
      pincode: json['pincode'] ?? '',
      district: json['district'] ?? '',
      studentOrWorkingProfessional:
          json['student_or_working_professional'] ?? '',
      placementAssistance: json['placement_assistance'] ?? false,
      preferredJobLocation: json['preferred_job_location'] ?? '',
      admissionDate: json['admission_date'] ?? '',
      status: Status.fromJson(json['status'] ?? {}),
      isAlumni: json['is_alumni'] ?? false,
      isPlaced: json['is_placed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'whatsapp_number': whatsappNumber,
      'profile_picture': profilePicture,
      'date_of_birth': dateOfBirth,
      'age': age,
      'qualification': qualification.toJson(),
      'college': college,
      'pass_out_year': passOutYear,
      'specialization': specialization,
      'cgpa': cgpa,
      'any_arrears': anyArrears,
      'preferred_location': preferredLocation.toJson(),
      'address': address,
      'pincode': pincode,
      'district': district,
      'student_or_working_professional': studentOrWorkingProfessional,
      'placement_assistance': placementAssistance,
      'preferred_job_location': preferredJobLocation,
      'admission_date': admissionDate,
      'status': status.toJson(),
      'is_alumni': isAlumni,
      'is_placed': isPlaced,
    };
  }
}

class Qualification {
  final String name;

  Qualification({required this.name});

  factory Qualification.fromJson(Map<String, dynamic> json) {
    return Qualification(name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}

class PreferredLocation {
  final String name;

  PreferredLocation({required this.name});

  factory PreferredLocation.fromJson(Map<String, dynamic> json) {
    return PreferredLocation(name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}

class Status {
  final String name;
  final String value;
  final String color;

  Status({required this.name, required this.value, required this.color});

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(
      name: json['name'] ?? '',
      value: json['value'] ?? '',
      color: json['color'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'value': value, 'color': color};
  }
}

class GuardianInfo {
  final String parentName;
  final String parentPhone;

  GuardianInfo({required this.parentName, required this.parentPhone});

  factory GuardianInfo.fromJson(Map<String, dynamic> json) {
    return GuardianInfo(
      parentName: json['parent_name'] ?? '',
      parentPhone: json['parent_phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'parent_name': parentName, 'parent_phone': parentPhone};
  }
}

class Counselor {
  final String name;
  final String email;
  final String phone;
  final String whatsapp;

  Counselor({
    required this.name,
    required this.email,
    required this.phone,
    required this.whatsapp,
  });

  factory Counselor.fromJson(Map<String, dynamic> json) {
    return Counselor(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'email': email, 'phone': phone, 'whatsapp': whatsapp};
  }
}

class EnrollmentSummary {
  final int totalEnrollments;
  final int activeEnrollments;
  final int completedEnrollments;

  EnrollmentSummary({
    required this.totalEnrollments,
    required this.activeEnrollments,
    required this.completedEnrollments,
  });

  factory EnrollmentSummary.fromJson(Map<String, dynamic> json) {
    return EnrollmentSummary(
      totalEnrollments: json['total_enrollments'] ?? 0,
      activeEnrollments: json['active_enrollments'] ?? 0,
      completedEnrollments: json['completed_enrollments'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_enrollments': totalEnrollments,
      'active_enrollments': activeEnrollments,
      'completed_enrollments': completedEnrollments,
    };
  }
}

class FinancialSummary {
  final double totalFeesPaid;
  final double totalFeesPending;
  final String paymentStatus;
  final bool hasPendingPayments;

  FinancialSummary({
    required this.totalFeesPaid,
    required this.totalFeesPending,
    required this.paymentStatus,
    required this.hasPendingPayments,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      totalFeesPaid: (json['total_fees_paid'] ?? 0.0).toDouble(),
      totalFeesPending: (json['total_fees_pending'] ?? 0.0).toDouble(),
      paymentStatus: json['payment_status'] ?? '',
      hasPendingPayments: json['has_pending_payments'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_fees_paid': totalFeesPaid,
      'total_fees_pending': totalFeesPending,
      'payment_status': paymentStatus,
      'has_pending_payments': hasPendingPayments,
    };
  }
}

class Activity {
  final String uid;
  final String activityType;
  final String title;
  final String description;
  final double? amount;
  final String createdAt;
  final String performedBy;
  final String priority;

  Activity({
    required this.uid,
    required this.activityType,
    required this.title,
    required this.description,
    this.amount,
    required this.createdAt,
    required this.performedBy,
    required this.priority,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      uid: json['uid'] ?? '',
      activityType: json['activity_type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      amount: json['amount']?.toDouble(),
      createdAt: json['created_at'] ?? '',
      performedBy: json['performed_by'] ?? '',
      priority: json['priority'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'activity_type': activityType,
      'title': title,
      'description': description,
      'amount': amount,
      'created_at': createdAt,
      'performed_by': performedBy,
      'priority': priority,
    };
  }
}

class ReferralInfo {
  final int totalReferrals;
  final int totalRewardsEarned;
  final int pendingRewardsCount;
  final int paidRewardsCount;
  final bool canRefer;

  ReferralInfo({
    required this.totalReferrals,
    required this.totalRewardsEarned,
    required this.pendingRewardsCount,
    required this.paidRewardsCount,
    required this.canRefer,
  });

  factory ReferralInfo.fromJson(Map<String, dynamic> json) {
    return ReferralInfo(
      totalReferrals: json['total_referrals'] ?? 0,
      totalRewardsEarned: json['total_rewards_earned'] ?? 0,
      pendingRewardsCount: json['pending_rewards_count'] ?? 0,
      paidRewardsCount: json['paid_rewards_count'] ?? 0,
      canRefer: json['can_refer'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_referrals': totalReferrals,
      'total_rewards_earned': totalRewardsEarned,
      'pending_rewards_count': pendingRewardsCount,
      'paid_rewards_count': paidRewardsCount,
      'can_refer': canRefer,
    };
  }
}

class PortalSettings {
  final bool accessEnabled;
  final bool canViewPayments;
  final bool canViewCertificates;
  final bool canDownloadReceipts;

  PortalSettings({
    required this.accessEnabled,
    required this.canViewPayments,
    required this.canViewCertificates,
    required this.canDownloadReceipts,
  });

  factory PortalSettings.fromJson(Map<String, dynamic> json) {
    return PortalSettings(
      accessEnabled: json['access_enabled'] ?? false,
      canViewPayments: json['can_view_payments'] ?? false,
      canViewCertificates: json['can_view_certificates'] ?? false,
      canDownloadReceipts: json['can_download_receipts'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_enabled': accessEnabled,
      'can_view_payments': canViewPayments,
      'can_view_certificates': canViewCertificates,
      'can_download_receipts': canDownloadReceipts,
    };
  }
}

class QuickStats {
  final int daysSinceAdmission;
  final int activeBatchesCount;
  final int pendingEmiCount;
  final int completedCoursesCount;

  QuickStats({
    required this.daysSinceAdmission,
    required this.activeBatchesCount,
    required this.pendingEmiCount,
    required this.completedCoursesCount,
  });

  factory QuickStats.fromJson(Map<String, dynamic> json) {
    return QuickStats(
      daysSinceAdmission: json['days_since_admission'] ?? 0,
      activeBatchesCount: json['active_batches_count'] ?? 0,
      pendingEmiCount: json['pending_emi_count'] ?? 0,
      completedCoursesCount: json['completed_courses_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'days_since_admission': daysSinceAdmission,
      'active_batches_count': activeBatchesCount,
      'pending_emi_count': pendingEmiCount,
      'completed_courses_count': completedCoursesCount,
    };
  }
}
