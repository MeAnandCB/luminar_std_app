import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/presentation/complete_your_profile/view/complete_your_profile.dart';
import 'package:luminar_std/repository/enrollment_screen/model/enrollemnt_screen.dart' as enroll_model;
import 'package:luminar_std/repository/home_screen/dashmoard_model.dart';
import 'package:luminar_std/repository/home_screen/service.dart';
import 'package:luminar_std/repository/nactet_registration/model/nactet_check_display_model.dart';
import 'package:luminar_std/repository/nactet_registration/service/nactet_registration_service.dart';

class DashboardController extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  Dashboard? _dashboard;
  DashBoardModel? _dashboardModel;
  NactetCheckDisplayResponse? _nactetStatus;
  bool _skipProfileCompletionRedirect = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Dashboard? get dashboard => _dashboard;
  DashBoardModel? get dashboardModel => _dashboardModel;
  NactetCheckDisplayResponse? get nactetStatus => _nactetStatus;

  bool get shouldShowNactetBanner {
    return _nactetStatus?.displayForm ?? false;
  }

  String? get nactetStatusReason => _nactetStatus?.reason;

  int get pendingNactetCount {
    if (_nactetStatus == null) return 0;
    return _nactetStatus!.totalEligibleEnrollments - _nactetStatus!.enrollmentsWithCertificateData;
  }

  bool get isNactetFullySubmitted {
    if (_nactetStatus == null) return false;
    return _nactetStatus!.totalEligibleEnrollments > 0 &&
        _nactetStatus!.enrollmentsWithCertificateData >= _nactetStatus!.totalEligibleEnrollments;
  }

  Future<Dashboard?> getDashboardData({
    required BuildContext context,
    bool forceRefresh = false,
  }) async {
    // Return cached data unless a forced refresh is requested
    if (!forceRefresh && _dashboard != null) return _dashboard;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await DashboardService().getDashboardData();

      if (response.success && response.data != null) {
        _dashboardModel = response.data;
        _dashboard = _dashboardModel?.dashboard;

        if (_dashboard != null) {
          final d = _dashboard!;
          final student = d.studentDetails?.basicInfo;
          final enrollments = d.enrollmentDetails?.enrollments ?? [];
          final financial = d.financialSummary?.overview;
          final stats = d.quickStats;

          developer.log(
            '─── Dashboard Data ───\n'
            '  student        : ${student?.fullName} (${student?.studentId})\n'
            '  email          : ${student?.email}\n'
            '  phone          : ${student?.phone}\n'
            '  profileDone    : ${student?.profileCompleted}\n'
            '  enrollments    : ${enrollments.length}\n'
            '${enrollments.asMap().entries.map((e) => '  [${e.key + 1}] ${e.value.batchInfo?.batchName} | batch: ${e.value.batchInfo?.uid} | status: ${e.value.status?.name}').join('\n')}\n'
            '  totalFeesAmt   : ${financial?.totalFeesAmount}\n'
            '  totalFeesPaid  : ${financial?.totalFeesPaid}\n'
            '  totalFeesPend  : ${financial?.totalFeesPending}\n'
            '  paymentStatus  : ${financial?.paymentStatus}\n'
            '  payment%       : ${financial?.paymentCompletionPercentage}\n'
            '  totalCourses   : ${stats?.academic?.totalCourses}\n'
            '  activeCourses  : ${stats?.academic?.activeCourses}\n'
            '  completedCrs   : ${stats?.academic?.completedCourses}\n'
            '  completionRate : ${stats?.academic?.completionRate}',
            name: 'Dashboard',
          );

          if (!_skipProfileCompletionRedirect &&
              _dashboard?.studentDetails?.basicInfo?.profileCompleted != true) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => ProfileCompletionScreen()),
              (route) => false,
            );
          }
          _skipProfileCompletionRedirect = false;
          _error = null;
        } else {
          _error = 'No dashboard data available';
        }
      } else {
        _error = response.message;
        if (response.statusCode == 401) {
          await AppUtils.clearUserSession();
          if (context.mounted) AppUtils.navigateToLogin(context);
        }
      }
    } catch (e) {
      _error = e.toString();
      _dashboard = null;
      _dashboardModel = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _dashboard;
  }

  // Convenience method to force-refresh dashboard data (e.g. pull-to-refresh)
  Future<void> refreshDashboard({required BuildContext context}) async {
    await getDashboardData(context: context, forceRefresh: true);
    await getNactetStatus();
  }

  Future<void> getNactetStatus() async {
    try {
      final response = await NactetRegistrationService().fetchCheckDisplayStatus();
      if (response.success && response.data != null) {
        _nactetStatus = NactetCheckDisplayResponse.fromJson(response.data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching NACTET status: $e');
    }
  }

  void markProfileJustCompleted() {
    _skipProfileCompletionRedirect = true;
  }

  // Clear dashboard data (useful for logout)
  void clearDashboardData() {
    _dashboard = null;
    _dashboardModel = null;
    _nactetStatus = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // Get student name from dashboard data
  String getStudentName() {
    try {
      return _dashboard?.studentDetails?.basicInfo?.fullName?.toString() ??
          _dashboardModel?.dashboard?.studentDetails?.basicInfo?.fullName
              ?.toString() ??
          'Guest';
    } catch (e) {
      return 'Guest';
    }
  }

  // Get financial overview
  Overview? getFinancialOverview() {
    return _dashboard?.financialSummary?.overview ??
        _dashboardModel?.dashboard?.financialSummary?.overview;
  }

  // Get current enrollment
  Enrollment? getCurrentEnrollment() {
    final enrollments =
        _dashboard?.enrollmentDetails?.enrollments ??
        _dashboardModel?.dashboard?.enrollmentDetails?.enrollments;

    if (enrollments != null && enrollments.isNotEmpty) {
      return enrollments.first;
    }
    return null;
  }

  // Get recent activities
  List<EntActivity>? getRecentActivities() {
    return _dashboard?.recentActivities?.recentActivities ??
        _dashboardModel?.dashboard?.recentActivities?.recentActivities;
  }

  // Get notification summary
  NotificationsSummarySummary? getNotificationSummary() {
    return _dashboard?.notificationsSummary?.summary ??
        _dashboardModel?.dashboard?.notificationsSummary?.summary;
  }

  // Get quick stats
  QuickStats? getQuickStats() {
    return _dashboard?.quickStats ?? _dashboardModel?.dashboard?.quickStats;
  }

  // Check if has active enrollments
  bool get hasActiveEnrollments {
    final enrollments =
        _dashboard?.enrollmentDetails?.enrollments ??
        _dashboardModel?.dashboard?.enrollmentDetails?.enrollments;
    return enrollments != null && enrollments.isNotEmpty;
  }

  // Get completion rate
  int getCompletionRate() {
    final academic =
        _dashboard?.quickStats?.academic ??
        _dashboardModel?.dashboard?.quickStats?.academic;
    return academic?.completionRate ?? 0;
  }

  // Get pending fees amount
  int getPendingFees() {
    final overview =
        _dashboard?.financialSummary?.overview ??
        _dashboardModel?.dashboard?.financialSummary?.overview;
    return overview?.totalFeesPending ?? 0;
  }

  // Get paid fees amount
  int getPaidFees() {
    final overview =
        _dashboard?.financialSummary?.overview ??
        _dashboardModel?.dashboard?.financialSummary?.overview;
    return overview?.totalFeesPaid ?? 0;
  }

  // Get total fees amount
  int getTotalFees() {
    final overview =
        _dashboard?.financialSummary?.overview ??
        _dashboardModel?.dashboard?.financialSummary?.overview;
    return overview?.totalFeesAmount ?? 0;
  }

  /// Converts dashboard enrollments into the enrollment-screen model so
  /// EnrollmentScreen can display them without calling the enrollment API.
  List<enroll_model.Enrollment> get enrollmentsFromDashboard {
    final list = _dashboard?.enrollmentDetails?.enrollments ?? [];
    return list.map((e) => enroll_model.Enrollment(
      uid: e.basicInfo?.uid ?? '',
      enrollmentNumber: e.basicInfo?.enrollmentNumber ?? '',
      enrollmentDate: e.basicInfo?.enrollmentDate ?? DateTime.now(),
      originalCourseFeesDiscount:
          (e.paymentDetails?.financialBreakdown?.totalDiscount ?? 0).toDouble(),
      source: e.basicInfo?.source ?? '',
      status: enroll_model.Status(
        name: e.status?.name ?? '',
        value: e.status?.value ?? '',
        color: e.status?.color ?? '#000000',
      ),
      batch: enroll_model.Batch(
        uid: e.batchInfo?.uid ?? '',
        batchName: e.batchInfo?.batchName ?? '',
        startDate: e.batchInfo?.startDate ?? DateTime.now(),
        endDate: e.batchInfo?.endDate ?? DateTime.now(),
        joinUrl: '',
        time: e.batchInfo?.time ?? '',
        status: e.batchInfo?.status ?? '',
      ),
      course: enroll_model.Course(
        courseName: e.courseInfo?.courseName ?? '',
      ),
      attendanceMode: enroll_model.AttendanceMode(
        name: e.attendanceMode?.name ?? '',
        value: e.attendanceMode?.value ?? '',
      ),
      paymentInfo: enroll_model.PaymentInfo(
        grossAmount:
            (e.paymentDetails?.financialBreakdown?.grossAmount ?? 0).toDouble(),
        totalDiscount:
            (e.paymentDetails?.financialBreakdown?.totalDiscount ?? 0).toDouble(),
        netAmount:
            (e.paymentDetails?.financialBreakdown?.netAmount ?? 0).toDouble(),
        amountPaid:
            (e.paymentDetails?.financialBreakdown?.amountPaid ?? 0).toDouble(),
        pendingAmount:
            (e.paymentDetails?.financialBreakdown?.pendingAmount ?? 0).toDouble(),
        paymentCompletionPercentage:
            (e.paymentDetails?.financialBreakdown?.paymentCompletionPercentage ?? 0)
                .toDouble(),
        isFullyPaid:
            e.paymentDetails?.financialBreakdown?.isFullyPaid ?? false,
        hasOverpayment:
            e.paymentDetails?.financialBreakdown?.hasOverpayment ?? false,
      ),
      progress: enroll_model.Progress(
        attendancePercentage:
            (e.academicProgress?.attendancePercentage ?? 0).toDouble(),
        completionPercentage:
            (e.academicProgress?.completionPercentage ?? 0).toDouble(),
        finalGrade: e.academicProgress?.finalGrade ?? '',
        certificateIssued: e.academicProgress?.certificateIssued ?? false,
      ),
      specialNotes: e.additionalInfo?.specialNotes ?? '',
      tags: List<String>.from(
          e.additionalInfo?.tags?.map((t) => t.toString()) ?? []),
    )).toList();
  }

  // Get unread exams count
  int get unreadExamsCount =>
      _dashboard?.quickStats?.unreadExams ??
      _dashboardModel?.dashboard?.quickStats?.unreadExams ??
      0;

  // Get unviewed job notifications count
  int get unviewedJobNotificationsCount =>
      _dashboard?.quickStats?.unviewedJobNotifications ??
      _dashboardModel?.dashboard?.quickStats?.unviewedJobNotifications ??
      0;

  void decrementUnviewedJobNotifications() {
    final stats = _dashboard?.quickStats;
    if (stats != null && (stats.unviewedJobNotifications ?? 0) > 0) {
      stats.unviewedJobNotifications = stats.unviewedJobNotifications! - 1;
      notifyListeners();
    }
  }

  void decrementUnreadExams() {
    final stats = _dashboard?.quickStats;
    if (stats != null && (stats.unreadExams ?? 0) > 0) {
      stats.unreadExams = stats.unreadExams! - 1;
      notifyListeners();
    }
  }
}
