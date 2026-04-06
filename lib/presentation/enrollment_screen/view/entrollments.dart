// enrollment_screen.dart
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:intl/intl.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/presentation/course_screen/course_screen.dart';
import 'package:luminar_std/presentation/enrollment_screen/controller/controller.dart';
import 'package:luminar_std/presentation/enrollment_screen/view/entrollment_screen.dart';
import 'package:luminar_std/presentation/enrollment_screen/view/widget/enrollment_card.dart';

import 'package:luminar_std/repository/enrollment_screen/model/enrollemnt_screen.dart';
import 'package:provider/provider.dart';

class EnrollmentScreen extends StatefulWidget {
  const EnrollmentScreen({Key? key}) : super(key: key);

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen>
    with TickerProviderStateMixin {
  late EnrollmentProvider _enrollmentProvider;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enrollmentProvider = Provider.of<EnrollmentProvider>(
        context,
        listen: false,
      );
      _loadData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _enrollmentProvider.fetchEnrollData(context: context);
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 75) return AppColors.statsGreen;
    if (percentage >= 50) return AppColors.statsBlue;
    if (percentage >= 25) return AppColors.statsOrange;
    return AppColors.error;
  }

  Color _getStatusColor(String colorHex) {
    try {
      if (colorHex.isNotEmpty) {
        return Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
      }
    } catch (e) {
      return AppColors.primary;
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            'My Enrollments',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),

        backgroundColor: AppColors.cardBackground,
        elevation: 0.5,
        shadowColor: AppColors.shadowLight,
      ),
      body: Consumer<EnrollmentProvider>(
        builder: (context, provider, child) {
          // Handle loading state
          if (provider.isLoading && provider.enrollmentData == null) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          // Handle error state
          if (provider.hasError) {
            final friendly = AppUtils.friendlyError(provider.errorMessage ?? '');
            final isNetwork = friendly.contains('internet');
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                      size: 72,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isNetwork ? 'No Internet Connection' : 'Something Went Wrong',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      friendly,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Handle no data state
          if (!provider.hasData ||
              provider.enrollmentData!.enrollments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                    ),
                    child: Icon(
                      Icons.school_outlined,
                      size: 80,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Enrollments Yet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start your learning journey today!',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          // Show enrollments
          final enrollments = provider.enrollmentData!.enrollments;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: enrollments.length,
              itemBuilder: (context, index) {
                final enrollment = enrollments[index];
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: EnrollmentCard(
                      enrollment: enrollment,
                      index: index,
                      onTap:
                          (enrollments[index].status.value ==
                                  "admission_fee_paid" ||
                              enrollments[index].status.value == "not_set" ||
                              enrollments[index].status.value == "demo_expired")
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EnrollmentDetailsScreen(
                                    index: index,
                                    backbuttonValue: true,
                                  ),
                                ),
                              );
                            }
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CourseScreen(
                                    discount: enrollments[index]
                                        .paymentInfo
                                        .totalDiscount
                                        .toInt(),
                                    institute: "Luminar Technolab",
                                    courseName:
                                        enrollments[index].course.courseName,
                                    batchName:
                                        enrollments[index].batch.batchName,
                                    enrollmentId:
                                        enrollments[index].enrollmentNumber,
                                    startDate: enrollments[index]
                                        .batch
                                        .startDate
                                        .toString(),
                                    schedule: enrollments[index].batch.time,
                                    batchTime: enrollments[index].batch.time,
                                    attendanceMode:
                                        enrollments[index].attendanceMode.name,
                                    progress: enrollments[index]
                                        .progress
                                        .completionPercentage
                                        .toInt(),
                                    attendance: enrollments[index]
                                        .progress
                                        .completionPercentage
                                        .toString(),
                                    paymentCompleted: enrollments[index]
                                        .paymentInfo
                                        .amountPaid
                                        .toInt(),
                                    amountPaid: enrollments[index]
                                        .paymentInfo
                                        .amountPaid
                                        .toInt(),
                                    pendingAmount: enrollments[index]
                                        .paymentInfo
                                        .pendingAmount
                                        .toInt(),
                                    totalFee: enrollments[index]
                                        .paymentInfo
                                        .grossAmount
                                        .toInt(),
                                  ),
                                ),
                              );
                            },
                      getProgressColor: _getProgressColor,
                      getStatusColor: _getStatusColor,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
