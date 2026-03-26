import 'package:flutter/material.dart';
import 'package:luminar_std/repository/forgot_pass/forgot_pass_service.dart';

class ForgotPasswordController extends ChangeNotifier {
  final ForgotPassService _forgotPassService = ForgotPassService();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  String? _email;
  bool _otpSent = false;
  bool _otpVerified = false;

  // Form field states
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get email => _email;
  bool get otpSent => _otpSent;
  bool get otpVerified => _otpVerified;

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear success message
  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  // Reset all states
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _successMessage = null;
    _email = null;
    _otpSent = false;
    _otpVerified = false;

    // Clear text controllers
    emailController.clear();
    otpController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();

    notifyListeners();
  }

  // Step 1: Send OTP to email
  Future<bool> sendOtp({
    required BuildContext context,
    required String email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      print('📧 ForgotPasswordController: Sending OTP to $email');

      final response = await _forgotPassService.sendOtp(
        context: context,
        email: email,
      );

      if (response.success!) {
        _otpSent = true;
        _email = response.email ?? email;
        _successMessage = response.message ?? 'OTP sent successfully';
        _isLoading = false;
        notifyListeners();

        print('✅ OTP sent successfully to ${response.email}');
        return true;
      } else {
        _errorMessage = response.message ?? 'Failed to send OTP';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      print('❌ Error sending OTP: $e');
      return false;
    }
  }

  // Step 2: Verify OTP (you'll need to implement this endpoint)
  Future<bool> verifyOtp({
    required BuildContext context,
    required String email,
    required String otp,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🔐 ForgotPasswordController: Verifying OTP for $email');

      // Implement this API call in your service
      final response = await _forgotPassService.verifyOtp(
        context: context,
        email: email,
        otp: otp,
      );

      if (response['success'] == true) {
        _otpVerified = true;
        _successMessage = response['message'] ?? 'OTP verified successfully';
        _isLoading = false;
        notifyListeners();

        print('✅ OTP verified successfully');
        return true;
      } else {
        // Handle error response
        String errorMsg = 'Invalid OTP';
        if (response['errors'] != null && response['errors']['otp'] != null) {
          errorMsg = (response['errors']['otp'] as List).first;
        }
        _errorMessage = errorMsg;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      print('❌ Error verifying OTP: $e');
      return false;
    }
  }

  // Step 3: Reset password (you'll need to implement this endpoint)
  Future<bool> resetPassword({
    required BuildContext context,
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    // Validate passwords match
    if (newPassword != confirmPassword) {
      _errorMessage = 'Passwords do not match';
      notifyListeners();
      return false;
    }

    // Validate password strength (optional)
    if (newPassword.length < 6) {
      _errorMessage = 'Password must be at least 6 characters';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🔑 ForgotPasswordController: Resetting password for $email');

      // Implement this API call in your service
      final response = await _forgotPassService.resetPassword(
        context: context,
        email: email,
        otp: otp,
        newPassword: newPassword,
        comPass: confirmPassword,
      );

      if (response['success'] == true) {
        _successMessage = response['message'] ?? 'Password reset successfully';
        _isLoading = false;

        // Reset all states after successful password reset
        _otpSent = false;
        _otpVerified = false;
        _email = null;

        // Clear controllers
        emailController.clear();
        otpController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();

        notifyListeners();

        print('✅ Password reset successfully');
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to reset password';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      print('❌ Error resetting password: $e');
      return false;
    }
  }

  // Convenience method to resend OTP
  Future<bool> resendOtp({required BuildContext context}) async {
    if (_email == null || _email!.isEmpty) {
      _errorMessage = 'Email not found';
      notifyListeners();
      return false;
    }

    return sendOtp(context: context, email: _email!);
  }

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
