import 'package:flutter/material.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/repository/enrollment_screen/model/enrollemnt_screen.dart';
import 'package:luminar_std/repository/enrollment_screen/service/enrollment_service.dart';
import 'package:luminar_std/repository/razorpay/model/emi_res_model.dart';
import 'package:luminar_std/repository/razorpay/model/razorpay_model.dart';
import 'package:luminar_std/repository/enrollment_screen/service/installment_service.dart';
import 'package:luminar_std/repository/razorpay/service/razorpay_service.dart';

import 'package:provider/provider.dart';

class EnrollmentProvider extends ChangeNotifier {
  RazorpayPaymentDetails? paymentDetails;
  EmiResponseData? emiResData;
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

  // Fetch enrollment data
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
      final response = await _enrollmentRepository.getEnrollmentData();

      if (response.success) {
        enrollmentDataRes = response.data;
        _errorMessage = null;
        debugPrint('======= ENROLLMENT API RESPONSE =======');
        debugPrint(response.data?.toString() ?? 'No Data');
        debugPrint('=======================================');
      } else {
        _errorMessage = response.message ?? 'Failed to fetch enrollment data';
        enrollmentDataRes = null;
        debugPrint('======= ENROLLMENT API ERROR =======');
        debugPrint(response.message ?? 'Unknown error');
        debugPrint('====================================');

        if (response.statusCode == 401) {
          AppUtils.clearUserSession();
          AppUtils.navigateToLogin(context);
        }
      }

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
            content: Text(AppUtils.friendlyError(e.toString())),
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

  // Refresh data
  Future<void> refreshData(BuildContext context) async {
    await fetchEnrollData(context: context, showLoading: true);
  }

  // Load data silently (without showing loader)
  Future<void> loadDataSilently(BuildContext context) async {
    await fetchEnrollData(context: context, showLoading: false);
  }

  // Check if data is stale and needs refresh
  bool isDataStale({Duration staleDuration = const Duration(minutes: 5)}) {
    if (enrollmentDataRes == null) return true;
    // You might want to add timestamp logic here
    return false;
  }

  Future<void> getPaymentDetails({required String id}) async {
    try {
      final response = await RazorpayScreenService().getPaymentDetails(id: id);

      if (response.success) {
        PaymentResModel resModel = response.data;
        paymentDetails = resModel.paymentDetails;
      } else {
        LoggerUtils.warning(response.message.toString(), tag: 'Enrollment');
      }
    } catch (e) {
      LoggerUtils.error(e.toString(), tag: 'Enrollment');
    }
  }

  // Confirm EMI plan — POST /api/student-enrollment/emi-confirm/
  String? emiConfirmError;

  Future<bool> confirmEmiPlan({
    required String emiPlanId,
    required String enrollmentId,
    required List<num> emiAmounts,
    required PaymentDetailsApiService apiService,
    String? firstEmiDate,
  }) async {
    _isLoading = true;
    emiConfirmError = null;
    notifyListeners();
    try {
      LoggerUtils.debug(
        'Confirming EMI plan: $emiPlanId\n'
        '  enrollment_id  : $enrollmentId\n'
        '  emi_amounts    : $emiAmounts\n'
        '  first_emi_date : ${firstEmiDate ?? "(default)"}',
        tag: 'Enrollment',
      );
      final response = await apiService.confirmEmiPlan(
        emiPlanId: emiPlanId,
        enrollmentId: enrollmentId,
        emiAmounts: emiAmounts,
        firstEmiDate: firstEmiDate,
      );
      if (response.success) {
        LoggerUtils.info('EMI plan confirmed successfully', tag: 'Enrollment');
        return true;
      } else {
        emiConfirmError = response.message ?? 'Failed to confirm EMI plan';
        LoggerUtils.warning(emiConfirmError!, tag: 'Enrollment');
        return false;
      }
    } catch (e) {
      emiConfirmError = e.toString();
      LoggerUtils.error(e.toString(), tag: 'Enrollment');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //get emi data
  Future<void> getEmiPaymentDetails({
    required String id,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      LoggerUtils.debug("Fetching EMI payment details for plan ID: $id", tag: 'Enrollment');
      final response = await RazorpayScreenService().getEmiPaymentDetails(
        id: id,
      );

      if (response.success) {
        LoggerUtils.info("EMI payment details fetched successfully", tag: 'Enrollment');
        EmiPaymentResModel resModel = response.data;
        emiResData = resModel.emiResData;
        _errorMessage = null;
      } else {
        _errorMessage = response.message ?? "Failed to get EMI payment details";
        LoggerUtils.warning("Error fetching EMI payment details: $_errorMessage", tag: 'Enrollment');
      }
    } catch (e) {
      _errorMessage = e.toString();
      LoggerUtils.error("Exception in getEmiPaymentDetails: $e", tag: 'Enrollment');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
