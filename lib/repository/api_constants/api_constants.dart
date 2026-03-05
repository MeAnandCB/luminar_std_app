class ApiConstants {
  // Base URL
  static const String baseUrl = 'https://api.crm.dev.luminartechnohub.com/api';

  // Auth Endpoints
  static const String studentLogin = '/auth/student/login/';
  static const String studentLogout = '/auth/student/logout/';
  static const String refreshToken = '/auth/refresh/';
  static const String forgotPassword = '/auth/forgot-password/';
  static const String resetPassword = '/auth/reset-password/';

  // Student Endpoints
  static const String studentProfile = '/student/profile/';
  static const String studentDashboard = '/student/dashboard/';
  static const String studentCourses = '/student/courses/';
  static const String studentAttendance = '/student/attendance/';
  static const String studentPayments = '/student/payments/';
  static const String studentNotifications = '/student/notifications/';
  static const String studentLiveClasses = '/student/live-classes/';
  static const String studentVideos = '/student/videos/';
  static const String updateProfile = '/student/update-profile/';

  // Headers
  static const String contentType = 'Content-Type';
  static const String applicationJson = 'application/json';
  static const String authorization = 'Authorization';
  static const String bearer = 'Bearer ';

  // Shared Preferences Keys
  static const String authToken = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userData = 'user_data';
  static const String isLoggedIn = 'is_logged_in';
}
