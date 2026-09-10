class AppEndpoints {
  // Auth
  static const String login = '/api/auth/student/login/';
  static const String logout = '/api/auth/student/logout/';
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
  static const String publicCourses = '/api/public/courses/';
  static const String referralSubmit = '/api/hooks/referral-lead/';
  static const String referredStudentsHistory = '/api/lead/my-referred-leads/';
  static const String referredStudentsEnrolled =
      '/api/student/'; // Suffix with {student_id}/referred-students/
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
  static const String emiConfirm = '/api/student-enrollment/emi-confirm/';

  // Razorpay / Payments
  static const String razorpayFull =
      '/api/student-payments/full/'; // Suffix with {id}/
  static const String razorpayEmi = '/api/payments/emi/'; // Suffix with {id}/
  static const String iciciFull =
      '/api/student-payments/full/icici/'; // Suffix with {enrollment_id}/
  static const String iciciEmi =
      '/api/payments/emi/icici/'; // Suffix with {emi_id}/

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
  static const String chatUnreadCount = '/api/chats/unread-count/';
  static const String reportContent = '/api/chats/report/';

  // attandance

  static const String attandance = '/api/attendance/qr-scan/';
  static const String examSessions = '/api/student_portal/exams/sessions/';
  // Suffix with {session_uid}/visibility/
  static const String examSessionVisibility = '/api/evaluation/exam-sessions/';
  // Suffix with {attempt_uid}/
  static const String examResult = '/api/student_portal/exams/results/';

  // Locations / Branches
  static const String locations = '/api/locations/';

  // NACTET Certificates
  static const String certificatesCreate = '/api/certificates/create/';
  static const String certificatesCheckDisplay =
      '/api/certificates/check-display/';

  // Payment Gateways
  static const String paymentGateways = '/api/payment/gateways/';

  // Jobs
  static const String jobNotifications =
      '/api/student_portal/jobs/notifications/';
  static const String jobDetail =
      '/api/student_portal/jobs/'; // Suffix with {uid}/
  static const String jobApply =
      '/api/student_portal/jobs/'; // Suffix with {uid}/apply/
  static const String jobApplicationDetail =
      '/api/student_portal/jobs/applications/'; // Suffix with {application_uid}/

  // Student Tasks
  static const String studentTasksMy = '/api/student-tasks/my/';
  static const String studentTaskSubmit =
      '/api/student-tasks/assignments/'; // Suffix with {assignment_uid}/submissions/create/

  // Batch Student Feedback
  static const String feedbackOptions = '/api/feedback/batch/options/';
  static const String feedbackMyBatches = '/api/feedback/batch/my/';
  static const String feedbackSubmit =
      '/api/feedback/batch/'; // Suffix with {batch_uid}/submit/
}

class GlobalLinks {
  static const String baseUrl = 'https://api.crm.luminartechnohub.com';
  // static const String baseUrl = 'http://192.168.1.53:8000';
  // This DOES work on prod (confirmed with a real HTTP/1.1 WebSocket
  // handshake — a plain `curl` test without --http1.1 negotiates HTTP/2 by
  // default against this server, which silently breaks the Connection/
  // Upgrade handshake and returns a misleading 404; that is a curl/testing
  // artifact, not a real routing gap). Dart's WebSocket client only ever
  // uses HTTP/1.1, so the app is unaffected by that quirk. Do not switch
  // this back to the dev host based on a plain curl 404 — force HTTP/1.1
  // (`curl --http1.1 ...`) before concluding the route is missing.
  static const String websocketUrl =
      'wss://api.crm.luminartechnohub.com/ws/';
}

class LaptopApiConfig {
  // Base URL of the DAMS backend (the Next.js asset-management app)
  // static const String baseUrl = 'http://192.168.1.39:3001/api/mobile/laptops';

  // Shared API key — ask whoever manages the DAMS server for the value of
  // MOBILE_API_KEY in its .env.local. Do NOT commit the real value here.
  // static const String apiKey = '471961b68070cd99afa85d7f950f91351274dc12bd180047';

  static const String lookup = '/api/mobile/laptops/lookup';
  static const String checkout = '/api/mobile/laptops/checkout';
  static const String returnLaptop = '/api/mobile/laptops/return';
}
