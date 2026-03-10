import 'package:flutter/material.dart';
import 'package:luminar_std/repository/enrollment_screen/model/enrollemnt_screen.dart';
import 'package:luminar_std/repository/enrollment_screen/service/enrollment_service.dart';

import 'package:provider/provider.dart';

class EnrollmentProvider extends ChangeNotifier {
  final EnrollmentService _enrollmentRepository = EnrollmentService();

  // State variables - FIX: Change type to EnrollmentResponse
  EnrollmentResponse? enrollmentDataRes;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters - FIX: Update return type
  EnrollmentResponse? get enrollmentData => enrollmentDataRes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasData => enrollmentDataRes != null;

  // Reset state
  void resetState() {
    enrollmentDataRes = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Fetch enrollment data - FIX: Fixed method name and assignment
  Future<void> fetchEnrollData({
    required BuildContext context,
    bool showLoading = true,
  }) async {
    // Set loading state
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final data = await _enrollmentRepository.getEnrollmentData(
        context: context,
      );

      // FIX: Assign the data correctly (not to itself)
      enrollmentDataRes = data;
      _errorMessage = null;

      if (showLoading) {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      enrollmentDataRes = null;

      // Show error in UI if needed
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      if (showLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // Refresh data - FIX: Update method name
  Future<void> refreshData(BuildContext context) async {
    await fetchEnrollData(context: context, showLoading: true);
  }

  // Load data silently (without showing loader) - FIX: Update method name
  Future<void> loadDataSilently(BuildContext context) async {
    await fetchEnrollData(context: context, showLoading: false);
  }

  // Check if data is stale and needs refresh
  bool isDataStale({Duration staleDuration = const Duration(minutes: 5)}) {
    if (enrollmentDataRes == null) return true;
    // You might want to add timestamp logic here
    return false;
  }
}

// Optional: Create a mixin for easier provider usage in widgets
mixin EnrollmentProviderMixin<T extends StatefulWidget> on State<T> {
  late EnrollmentProvider enrollmentProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    enrollmentProvider = Provider.of<EnrollmentProvider>(context);
  }

  void loadEnrollmentData() {
    if (!enrollmentProvider.hasData && !enrollmentProvider.isLoading) {
      // FIX: Update method name
      enrollmentProvider.fetchEnrollData(context: context);
    }
  }
}
