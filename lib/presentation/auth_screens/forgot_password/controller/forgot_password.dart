import 'package:flutter/material.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';
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
    required String email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      LoggerUtils.info('📧 Sending OTP to $email', tag: 'ForgotPassword');

      final response = await _forgotPassService.sendOtp(
        email: email,
      );

      if (response.success) {
        _otpSent = true;
        _email = response.data?.email ?? email;
        _successMessage = response.message ?? 'OTP sent successfully';
        _isLoading = false;
        notifyListeners();

        LoggerUtils.info('✅ OTP sent successfully to ${response.data?.email}', tag: 'ForgotPassword');
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
      LoggerUtils.error('❌ Error sending OTP: $e', tag: 'ForgotPassword');
      return false;
    }
  }

  // Step 2: Verify OTP
  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      LoggerUtils.info('🔐 Verifying OTP for $email', tag: 'ForgotPassword');

      final response = await _forgotPassService.verifyOtp(
        email: email,
        otp: otp,
      );

      if (response.success) {
        _otpVerified = true;
        _successMessage = response.message ?? 'OTP verified successfully';
        _isLoading = false;
        notifyListeners();

        LoggerUtils.info('✅ OTP verified successfully', tag: 'ForgotPassword');
        return true;
      } else {
        _errorMessage = response.message ?? 'Invalid OTP';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      LoggerUtils.error('❌ Error verifying OTP: $e', tag: 'ForgotPassword');
      return false;
    }
  }

  // Step 3: Reset password
  Future<bool> resetPassword({
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
      LoggerUtils.info('🔑 Resetting password for $email', tag: 'ForgotPassword');

      final response = await _forgotPassService.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
        comPass: confirmPassword,
      );

      if (response.success) {
        _successMessage = response.message ?? 'Password reset successfully';
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

        LoggerUtils.info('✅ Password reset successfully', tag: 'ForgotPassword');
        return true;
      } else {
        _errorMessage = response.message ?? 'Failed to reset password';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      LoggerUtils.error('❌ Error resetting password: $e', tag: 'ForgotPassword');
      return false;
    }
  }

  // Convenience method to resend OTP
  Future<bool> resendOtp() async {
    if (_email == null || _email!.isEmpty) {
      _errorMessage = 'Email not found';
      notifyListeners();
      return false;
    }

    return sendOtp(email: _email!);
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
