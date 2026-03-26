import 'package:flutter/material.dart';
import 'package:luminar_std/repository/forgot_pass/forgotpass_model.dart';
import 'package:luminar_std/repository/global/helper.dart';

class ForgotPassService {
  final ApiHelper _apiHelper = ApiHelper();

  Future<ForgotPassModel> sendOtp({
    required BuildContext context,
    required String email,
  }) async {
    try {
      final response = await _apiHelper.post(
        context,
        '/api/auth/forgot-password/send-otp/',
        body: {'email': email},
        requiresAuth: false,
        showErrorSnackbar: false,
      );

      print('📤 Send OTP Response: $response'); // Debug print

      if (response['success'] == true) {
        return ForgotPassModel.fromJson(response);
      } else {
        // Handle error response
        String errorMessage = 'Failed to send OTP';

        if (response['errors'] != null) {
          final errors = response['errors'] as Map<String, dynamic>;

          // Check for email errors
          if (errors.containsKey('email')) {
            final emailErrors = errors['email'];
            if (emailErrors is List && emailErrors.isNotEmpty) {
              errorMessage = emailErrors.first;
            } else if (emailErrors is String) {
              errorMessage = emailErrors;
            }
          }
          // Check for non_field_errors
          else if (errors.containsKey('non_field_errors')) {
            final nonFieldErrors = errors['non_field_errors'];
            if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
              errorMessage = nonFieldErrors.first;
            } else if (nonFieldErrors is String) {
              errorMessage = nonFieldErrors;
            }
          }
          // Check for message
          else if (errors.containsKey('message')) {
            errorMessage = errors['message'].toString();
          }
        } else if (response['message'] != null) {
          errorMessage = response['message'].toString();
        } else if (response['error'] != null) {
          errorMessage = response['error'].toString();
        }

        throw ApiException(errorMessage, response);
      }
    } on ApiException catch (e) {
      // Re-throw with clean message
      throw ApiException(_getCleanErrorMessage(e.message, 'send_otp'));
    } catch (e) {
      print('❌ Unexpected error in sendOtp: $e');
      throw ApiException('An unexpected error occurred. Please try again.');
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required BuildContext context,
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _apiHelper.post(
        context,
        '/api/auth/forgot-password/verify-otp/',
        body: {'email': email, 'otp': otp},
        requiresAuth: false,
        showErrorSnackbar: false,
      );

      print('📤 Verify OTP Response: $response'); // Debug print

      // Check if response contains error
      if (response['success'] == false) {
        String errorMessage = 'OTP verification failed';

        // Extract error message from various possible formats
        if (response['errors'] != null) {
          final errors = response['errors'] as Map<String, dynamic>;

          if (errors.containsKey('otp')) {
            final otpErrors = errors['otp'];
            if (otpErrors is List && otpErrors.isNotEmpty) {
              errorMessage = otpErrors.first;
            } else if (otpErrors is String) {
              errorMessage = otpErrors;
            }
          } else if (errors.containsKey('non_field_errors')) {
            final nonFieldErrors = errors['non_field_errors'];
            if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
              errorMessage = nonFieldErrors.first;
            } else if (nonFieldErrors is String) {
              errorMessage = nonFieldErrors;
            }
          } else if (errors.containsKey('message')) {
            errorMessage = errors['message'].toString();
          }
        } else if (response['message'] != null) {
          errorMessage = response['message'].toString();
        } else if (response['error'] != null) {
          errorMessage = response['error'].toString();
        }

        throw ApiException(errorMessage, response);
      }

      return response;
    } on ApiException catch (e) {
      rethrow;
    } catch (e) {
      print('❌ Unexpected error in verifyOtp: $e');
      throw ApiException('An unexpected error occurred. Please try again.');
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required BuildContext context,
    required String email,
    required String otp,
    required String newPassword,
    required String comPass,
  }) async {
    try {
      // Client-side validation for password match
      if (newPassword != comPass) {
        throw ApiException('Passwords do not match');
      }

      final response = await _apiHelper.post(
        context,
        '/api/auth/forgot-password/reset-password/',
        body: {
          "email": email,
          "otp": otp,
          "new_password": newPassword,
          "confirm_password": comPass,
        },
        requiresAuth: false,
        showErrorSnackbar: false,
      );

      print('📤 Reset Password Response: $response'); // Debug print

      // Check if response contains error
      if (response['success'] == false) {
        String errorMessage = 'Password reset failed';

        // Extract error message from various possible formats
        if (response['errors'] != null) {
          final errors = response['errors'] as Map<String, dynamic>;

          // Check for password errors
          if (errors.containsKey('new_password')) {
            final passwordErrors = errors['new_password'];
            if (passwordErrors is List && passwordErrors.isNotEmpty) {
              errorMessage = passwordErrors.first;
            } else if (passwordErrors is String) {
              errorMessage = passwordErrors;
            }
          }
          // Check for confirm password errors
          else if (errors.containsKey('confirm_password')) {
            final confirmErrors = errors['confirm_password'];
            if (confirmErrors is List && confirmErrors.isNotEmpty) {
              errorMessage = confirmErrors.first;
            } else if (confirmErrors is String) {
              errorMessage = confirmErrors;
            }
          }
          // Check for OTP errors
          else if (errors.containsKey('otp')) {
            final otpErrors = errors['otp'];
            if (otpErrors is List && otpErrors.isNotEmpty) {
              errorMessage = otpErrors.first;
            } else if (otpErrors is String) {
              errorMessage = otpErrors;
            }
          }
          // Check for non_field_errors
          else if (errors.containsKey('non_field_errors')) {
            final nonFieldErrors = errors['non_field_errors'];
            if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
              errorMessage = nonFieldErrors.first;
            } else if (nonFieldErrors is String) {
              errorMessage = nonFieldErrors;
            }
          }
          // Check for message
          else if (errors.containsKey('message')) {
            errorMessage = errors['message'].toString();
          }
        } else if (response['message'] != null) {
          errorMessage = response['message'].toString();
        } else if (response['error'] != null) {
          errorMessage = response['error'].toString();
        }

        throw ApiException(errorMessage, response);
      }

      return response;
    } on ApiException catch (e) {
      rethrow;
    } catch (e) {
      print('❌ Unexpected error in resetPassword: $e');
      throw ApiException('An unexpected error occurred. Please try again.');
    }
  }

  String _getCleanErrorMessage(String message, [String? context]) {
    // Send OTP specific errors
    if (context == 'send_otp') {
      if (message.contains('User with this email does not exist') ||
          message.contains('not found') ||
          message.contains('no account')) {
        return 'No account found with this email address. Please check and try again.';
      } else if (message.contains('invalid email') ||
          message.contains('email format')) {
        return 'Please enter a valid email address.';
      } else if (message.contains('already') && message.contains('reset')) {
        return 'A password reset request is already pending for this email.';
      }
    }

    // Verify OTP specific errors
    if (context == 'verify_otp') {
      if (message.contains('Invalid OTP') ||
          message.contains('incorrect otp') ||
          message.contains('wrong otp')) {
        return 'The OTP you entered is incorrect. Please try again.';
      } else if (message.contains('expired')) {
        return 'OTP has expired. Please request a new one.';
      } else if (message.contains('max attempts') ||
          message.contains('too many attempts')) {
        return 'Too many failed attempts. Please request a new OTP.';
      }
    }

    // Reset password specific errors
    if (context == 'reset_password') {
      if (message.contains('Password must be at least')) {
        return 'Password must be at least 8 characters long.';
      } else if (message.contains('Password must contain')) {
        return 'Password must contain at least one letter and one number.';
      } else if (message.contains('passwords do not match') ||
          message.contains('password mismatch')) {
        return 'Passwords do not match. Please check and try again.';
      } else if (message.contains('weak password')) {
        return 'Please choose a stronger password.';
      } else if (message.contains('Invalid OTP') ||
          message.contains('incorrect otp')) {
        return 'Invalid OTP. Please go back and verify your OTP again.';
      } else if (message.contains('expired')) {
        return 'Your session has expired. Please start the password reset process again.';
      }
    }

    // General errors
    if (message.contains('rate limit') || message.contains('too many')) {
      return 'Too many attempts. Please try again later.';
    } else if (message.contains('timeout')) {
      return 'Connection timeout. Please check your internet and try again.';
    } else if (message.contains('Network') ||
        message.contains('internet') ||
        message.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    } else if (message.contains('server error') || message.contains('500')) {
      return 'Server error. Please try again later.';
    } else if (message.contains('Bad Request') && message.length > 20) {
      // If it's a bad request with a specific message, return the specific message
      return message;
    }

    return message;
  }
}
