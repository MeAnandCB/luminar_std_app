import 'package:flutter/material.dart';
import 'package:luminar_std/presentation/complete_your_profile/view/complete_your_profile.dart';
import 'package:luminar_std/presentation/profile_edit_screen/views/profile_edit_screen.dart';
import 'package:luminar_std/repository/home_screen/dashmoard_model.dart';
import 'package:luminar_std/repository/home_screen/service.dart';

class DashboardController extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  Dashboard? _dashboard;
  DashBoardModel? _dashboardModel;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Dashboard? get dashboard => _dashboard;
  DashBoardModel? get dashboardModel => _dashboardModel;

  Future<Dashboard?> getDashboardData({required BuildContext context}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetchedData = await DashboardService().GetDashboardData(
        context: context,
      );

      // Check if fetchedData is a DashBoardModel and has dashboard data
      _dashboardModel = fetchedData;
      _dashboard = fetchedData.dashboard;

      if (_dashboard != null) {
        print('✅ Dashboard data loaded successfully');
        if (_dashboard?.studentDetails?.basicInfo?.profileCompleted != true) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => ProfileCompletionScreen()),
            (route) => false,
          );
        }

        _error = null;
      } else {
        print('⚠️ Dashboard data is null in response');
        _error = 'No dashboard data available';
      }
    } catch (e) {
      print('❌ Error loading dashboard: $e');
      _error = e.toString();
      _dashboard = null;
      _dashboardModel = null;
    } finally {
      _isLoading = false;
      notifyListeners();
      print('📊 Loading state: $_isLoading, Error: $_error');
    }

    return _dashboard;
  }

  // Convenience method to refresh dashboard data
  Future<void> refreshDashboard({required BuildContext context}) async {
    await getDashboardData(context: context);
  }

  // Clear dashboard data (useful for logout)
  void clearDashboardData() {
    _dashboard = null;
    _dashboardModel = null;
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
}
