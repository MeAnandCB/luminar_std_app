class AppEndpoints {
  // Auth
  static const String login = '/api/auth/student/login/';
  static const String forgotPasswordSendOtp =
      '/api/auth/forgot-password/send-otp/';
  static const String forgotPasswordVerifyOtp =
      '/api/auth/forgot-password/verify-otp/';
  static const String forgotPasswordResetPassword =
      '/api/auth/forgot-password/reset-password/';
  static const String forgotPasswordResendOtp =
      '/api/auth/forgot-password/resend-otp/';

  // Student Portal / Dashboard / Profile
  static const String dashboard = '/api/student_portal/dashboard/';
  static const String profile = '/api/student_portal/profile/';
  static const String liveClassEnrollments =
      '/api/student_portal/enrollments/for-class/';
  static const String liveClassUrl =
      '/api/student_portal/enrollments/for-class/url/';
  static const String studentPortalEnrollments =
      '/api/student_portal/enrollments/';
  static const String enrollmentDetail =
      '/api/enrollment/'; //     Suffix with {uid}/

  // Profile (Legacy/Update)
  static const String profileUpdate =
      '/api/student/profile/'; // Suffix with {id}/update/.
  // Academic & Misc
  static const String qualifications = '/api/public/lead/qualifications/';
  static const String specializations = '/api/specializations/list/';
  static const String pincode =
      '/api/postal-pincode/'; // Suffix with {pincode}/
  static const String galleries = '/api/galleries/';
  static const String folders = '/api/folders/';
  static const String videos = '/api/videos/';

  // Enrollment & Activity
  static const String enrollment = '/api/student-enrollment/';
  static const String attendance = '/api/attendance/my-batch-attendance/';
  static const String payments = '/api/student/payments/';
  static const String emiPlans = '/api/emi-plans/';
  static const String emiPreview = '/api/student-enrollment/emi-preview/';

  // Razorpay / Payments
  static const String razorpayFull =
      '/api/student-payments/full/'; // Suffix with {id}/
  static const String razorpayEmi = '/api/payments/emi/'; // Suffix with {id}/

  // Chat
  static const String chats = '/api/chats/';
  static const String chatMessages =
      '/api/chats/'; // Suffix with {chatUid}/messages/
  static const String sendMessage =
      '/api/chats/'; // Suffix with {chatUid}/messages/send/
  static const String editMessage =
      '/api/chats/'; // Suffix with {chatUid}/messages/{messageUid}/edit/
  static const String deleteMessage =
      '/api/chats/'; // Suffix with {chatUid}/messages/{messageUid}/delete/
  static const String reactions =
      '/api/chats/'; // Suffix with {chatUid}/messages/{messageUid}/reactions/
  static const String markRead =
      '/api/chats/'; // Suffix with {chatUid}/messages/mark-read/
  static const String bulkMessage = '/api/chats/messages/bulk/';

  // attandance

  static const String attandance = '/api/attendance/qr-scan/';

  // NACTET Certificates
  static const String certificatesCreate = '/api/certificates/create/';
  static const String certificatesCheckDisplay =
      '/api/certificates/check-display/';
}

class GlobalLinks {
  static const String baseUrl = 'https://api.crm.dev.luminartechnohub.com';
  static const String websocketUrl =
      'wss://api.crm.dev.luminartechnohub.com/ws/';
}
