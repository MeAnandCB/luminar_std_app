import 'package:flutter/material.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/presentation/auth_screens/forgot_password/controller/forgot_password.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentStep = 1; // 1: Email, 2: OTP, 3: New Password
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  int _timerSeconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _timerSeconds = 60;
    });

    Future.delayed(const Duration(seconds: 1), _timerTick);
  }

  void _timerTick() {
    if (_timerSeconds > 0) {
      setState(() {
        _timerSeconds--;
      });
      Future.delayed(const Duration(seconds: 1), _timerTick);
    } else {
      setState(() {
        _canResend = true;
      });
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'OTP must contain only numbers';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$').hasMatch(value)) {
      return 'Password must contain at least one letter and one number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value, String newPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != newPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleSendOtp(BuildContext context) async {
    final controller = Provider.of<ForgotPasswordController>(context, listen: false);

    final emailError = _validateEmail(controller.emailController.text);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailError),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await controller.sendOtp(email: controller.emailController.text);

    if (success && mounted) {
      setState(() {
        _currentStep = 2;
      });
      _startResendTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.successMessage ?? 'OTP sent to your email'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.statsGreen,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppUtils.friendlyError(controller.errorMessage ?? 'Failed to send OTP')),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleVerifyOtp(BuildContext context) async {
    final controller = Provider.of<ForgotPasswordController>(context, listen: false);

    final otpError = _validateOtp(controller.otpController.text);
    if (otpError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(otpError),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await controller.verifyOtp(
      email: controller.emailController.text,
      otp: controller.otpController.text,
    );

    if (success && mounted) {
      setState(() {
        _currentStep = 3;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.successMessage ?? 'OTP verified successfully'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.statsGreen,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppUtils.friendlyError(controller.errorMessage ?? 'Invalid OTP')),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleResendOtp(BuildContext context) async {
    if (!_canResend) return;

    final controller = Provider.of<ForgotPasswordController>(context, listen: false);

    final success = await controller.resendOtp();

    if (success && mounted) {
      setState(() {
        _canResend = false;
        _timerSeconds = 60;
      });
      _startResendTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.successMessage ?? 'New OTP sent to your email'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.statsGreen,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppUtils.friendlyError(controller.errorMessage ?? 'Failed to resend OTP')),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleResetPassword(BuildContext context) async {
    final controller = Provider.of<ForgotPasswordController>(context, listen: false);

    // Simplified validation - only check if password is at least 8 characters
    if (controller.newPasswordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password must be at least 8 characters'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if passwords match
    if (controller.newPasswordController.text != controller.confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Passwords do not match'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await controller.resetPassword(
      email: controller.emailController.text,
      otp: controller.otpController.text,
      newPassword: controller.newPasswordController.text,
      confirmPassword: controller.confirmPasswordController.text,
    );

    if (success && mounted) {
      _showSuccessDialog(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppUtils.friendlyError(controller.errorMessage ?? 'Failed to reset password')),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(32)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.statsGreen.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.check_circle_rounded, color: AppColors.statsGreen, size: 50),
              ),
              SizedBox(height: 20),
              Text(
                'Password Reset Successfully!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              SizedBox(height: 8),
              Text(
                'You can now login with your new password',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to login
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Go to Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return ChangeNotifierProvider(
      create: (_) => ForgotPasswordController(),
      child: Consumer<ForgotPasswordController>(
        builder: (context, controller, child) {
          return Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.splashGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // Header with back button
                          Padding(
                            padding: EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.borderLighter),
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      controller.reset();
                                      Navigator.pop(context);
                                    },
                                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white, size: 20),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text(
                                  'Forgot Password',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.white),
                                ),
                              ],
                            ),
                          ),

                          // Step Indicator
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 30),
                            child: Row(
                              children: [
                                _buildStepIndicator(1, 'Email'),
                                Expanded(child: _buildStepLine(1)),
                                _buildStepIndicator(2, 'OTP'),
                                Expanded(child: _buildStepLine(2)),
                                _buildStepIndicator(3, 'Reset'),
                              ],
                            ),
                          ),

                          SizedBox(height: 30),

                          // Form Section
                          Expanded(
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(40),
                                    topRight: Radius.circular(40),
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(30),
                                  child: FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 10),

                                        // Step 1: Email
                                        if (_currentStep == 1) ...[
                                          Text(
                                            'Enter your email',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'We\'ll send a verification code to your email',
                                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                                          ),
                                          SizedBox(height: 30),

                                          // Email Field
                                          Text('Email', style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          )),
                                          SizedBox(height: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.surface,
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: controller.errorMessage != null
                                                    ? Colors.red
                                                    : AppColors.borderColor,
                                              ),
                                            ),
                                            child: TextFormField(
                                              controller: controller.emailController,
                                              keyboardType: TextInputType.emailAddress,
                                              style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
                                              decoration: InputDecoration(
                                                hintText: 'Enter your email',
                                                hintStyle: TextStyle(fontSize: 14, color: AppColors.textHint),
                                                prefixIcon: Icon(
                                                  Icons.email_outlined,
                                                  color: AppColors.primary,
                                                  size: 20,
                                                ),
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                              ),
                                            ),
                                          ),
                                          if (controller.errorMessage != null)
                                            Padding(
                                              padding: EdgeInsets.only(top: 8),
                                              child: Text(
                                                controller.errorMessage!,
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),

                                          SizedBox(height: 30),

                                          // Send OTP Button
                                          Container(
                                            width: double.infinity,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              gradient: AppColors.primaryGradient,
                                              borderRadius: BorderRadius.circular(30),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.primary.withOpacity(0.3),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ElevatedButton(
                                              onPressed: controller.isLoading ? null : () => _handleSendOtp(context),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent,
                                                foregroundColor: AppColors.textWhite,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                              ),
                                              child: controller.isLoading
                                                  ? SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child: CircularProgressIndicator(
                                                        color: AppColors.white,
                                                        strokeWidth: 2,
                                                      ),
                                                    )
                                                  : Text(
                                                      'Send OTP',
                                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                                    ),
                                            ),
                                          ),
                                        ],

                                        // Step 2: OTP
                                        if (_currentStep == 2) ...[
                                          Text(
                                            'Enter verification code',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Code sent to ${controller.emailController.text}',
                                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                                          ),
                                          SizedBox(height: 30),

                                          // OTP Field
                                          Text('OTP', style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          )),
                                          SizedBox(height: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.surface,
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: controller.errorMessage != null
                                                    ? Colors.red
                                                    : AppColors.borderColor,
                                              ),
                                            ),
                                            child: TextFormField(
                                              controller: controller.otpController,
                                              keyboardType: TextInputType.number,
                                              maxLength: 6,
                                              style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
                                              decoration: InputDecoration(
                                                hintText: 'Enter 6-digit OTP',
                                                hintStyle: TextStyle(fontSize: 14, color: AppColors.textHint),
                                                prefixIcon: Icon(Icons.pin_rounded, color: AppColors.primary, size: 20),
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                                counterText: '',
                                              ),
                                            ),
                                          ),
                                          if (controller.errorMessage != null)
                                            Padding(
                                              padding: EdgeInsets.only(top: 8),
                                              child: Text(
                                                controller.errorMessage!,
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),

                                          SizedBox(height: 20),

                                          // Resend OTP
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Didn't receive code? ",
                                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                              ),
                                              if (_canResend)
                                                GestureDetector(
                                                  onTap: controller.isLoading ? null : () => _handleResendOtp(context),
                                                  child: Text(
                                                    'Resend',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                )
                                              else
                                                Text(
                                                  'Resend in $_timerSeconds s',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textHint,
                                                  ),
                                                ),
                                            ],
                                          ),

                                          SizedBox(height: 30),

                                          // Verify OTP Button
                                          Container(
                                            width: double.infinity,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              gradient: AppColors.primaryGradient,
                                              borderRadius: BorderRadius.circular(30),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.primary.withOpacity(0.3),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ElevatedButton(
                                              onPressed: controller.isLoading ? null : () => _handleVerifyOtp(context),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent,
                                                foregroundColor: AppColors.textWhite,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                              ),
                                              child: controller.isLoading
                                                  ? SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child: CircularProgressIndicator(
                                                        color: AppColors.white,
                                                        strokeWidth: 2,
                                                      ),
                                                    )
                                                  : Text(
                                                      'Verify OTP',
                                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                                    ),
                                            ),
                                          ),
                                        ],

                                        // Step 3: New Password
                                        if (_currentStep == 3) ...[
                                          Text(
                                            'Reset your password',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Enter your new password',
                                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                                          ),
                                          SizedBox(height: 30),

                                          // New Password
                                          Text('New Password', style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          )),
                                          SizedBox(height: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.surface,
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: AppColors.borderColor),
                                            ),
                                            child: TextFormField(
                                              controller: controller.newPasswordController,
                                              obscureText: !_isPasswordVisible,
                                              style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
                                              decoration: InputDecoration(
                                                hintText: 'Enter new password',
                                                hintStyle: TextStyle(fontSize: 14, color: AppColors.textHint),
                                                prefixIcon: Icon(
                                                  Icons.lock_outline_rounded,
                                                  color: AppColors.primary,
                                                  size: 20,
                                                ),
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    _isPasswordVisible
                                                        ? Icons.visibility_off_rounded
                                                        : Icons.visibility_rounded,
                                                    color: AppColors.primary,
                                                    size: 20,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _isPasswordVisible = !_isPasswordVisible;
                                                    });
                                                  },
                                                ),
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                              ),
                                            ),
                                          ),

                                          SizedBox(height: 16),

                                          // Confirm Password
                                          Text('Confirm Password', style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          )),
                                          SizedBox(height: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.surface,
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: controller.errorMessage != null
                                                    ? Colors.red
                                                    : AppColors.borderColor,
                                              ),
                                            ),
                                            child: TextFormField(
                                              controller: controller.confirmPasswordController,
                                              obscureText: !_isConfirmPasswordVisible,
                                              style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
                                              decoration: InputDecoration(
                                                hintText: 'Confirm new password',
                                                hintStyle: TextStyle(fontSize: 14, color: AppColors.textHint),
                                                prefixIcon: Icon(
                                                  Icons.lock_outline_rounded,
                                                  color: AppColors.primary,
                                                  size: 20,
                                                ),
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    _isConfirmPasswordVisible
                                                        ? Icons.visibility_off_rounded
                                                        : Icons.visibility_rounded,
                                                    color: AppColors.primary,
                                                    size: 20,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                                    });
                                                  },
                                                ),
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                              ),
                                            ),
                                          ),
                                          if (controller.errorMessage != null)
                                            Padding(
                                              padding: EdgeInsets.only(top: 8),
                                              child: Text(
                                                controller.errorMessage!,
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),

                                          SizedBox(height: 30),

                                          // Reset Password Button
                                          Container(
                                            width: double.infinity,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              gradient: AppColors.primaryGradient,
                                              borderRadius: BorderRadius.circular(30),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.primary.withOpacity(0.3),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ElevatedButton(
                                              onPressed: controller.isLoading
                                                  ? null
                                                  : () => _handleResetPassword(context),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent,
                                                foregroundColor: AppColors.textWhite,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                              ),
                                              child: controller.isLoading
                                                  ? SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child: CircularProgressIndicator(
                                                        color: AppColors.white,
                                                        strokeWidth: 2,
                                                      ),
                                                    )
                                                  : Text(
                                                      'Reset Password',
                                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    bool isActive = step <= _currentStep;
    bool isCurrent = step == _currentStep;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: isActive ? AppColors.primaryGradient : null,
            color: isActive ? null : AppColors.borderLight,
            shape: BoxShape.circle,
            border: isCurrent ? Border.all(color: AppColors.white, width: 3) : null,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? AppColors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.white : AppColors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    bool isActive = step < _currentStep;

    return Container(
      height: 2,
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: isActive ? AppColors.primaryGradient : null,
        color: isActive ? null : AppColors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
