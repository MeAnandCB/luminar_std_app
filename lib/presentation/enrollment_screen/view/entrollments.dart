// enrollment_screen.dart
import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/presentation/course_screen/course_screen.dart';
import 'package:luminar_std/presentation/enrollment_screen/view/entrollment_screen.dart';
import 'package:luminar_std/presentation/enrollment_screen/view/widget/enrollment_card.dart';
import 'package:luminar_std/presentation/home_screen/controller.dart';
import 'package:provider/provider.dart';

class EnrollmentScreen extends StatefulWidget {
  const EnrollmentScreen({Key? key}) : super(key: key);

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen>
    with TickerProviderStateMixin {
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      body: Consumer<DashboardController>(
        builder: (context, dashboard, child) {
          // Show shimmer while dashboard is loading
          if (dashboard.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final enrollments = dashboard.enrollmentsFromDashboard;

          // Empty state
          if (enrollments.isEmpty) {
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

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: enrollments.length,
              itemBuilder: (context, index) {
                final enrollment = enrollments[index];
                final statusValue = enrollment.status.value;
                final isPaymentPending = statusValue == 'admission_fee_paid' ||
                    statusValue == 'not_set' ||
                    statusValue == 'demo_expired';
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: EnrollmentCard(
                      enrollment: enrollment,
                      index: index,
                      onTap: isPaymentPending
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
                                    discount: enrollment.paymentInfo.totalDiscount.toInt(),
                                    institute: "Luminar Technolab",
                                    courseName: enrollment.course.courseName,
                                    batchName: enrollment.batch.batchName,
                                    enrollmentId: enrollment.enrollmentNumber,
                                    startDate: enrollment.batch.startDate.toString(),
                                    schedule: enrollment.batch.time,
                                    batchTime: enrollment.batch.time,
                                    attendanceMode: enrollment.attendanceMode.name,
                                    progress: enrollment.progress.completionPercentage.toInt(),
                                    attendance: enrollment.progress.completionPercentage.toString(),
                                    paymentCompleted: enrollment.paymentInfo.amountPaid.toInt(),
                                    amountPaid: enrollment.paymentInfo.amountPaid.toInt(),
                                    pendingAmount: enrollment.paymentInfo.pendingAmount.toInt(),
                                    totalFee: enrollment.paymentInfo.grossAmount.toInt(),
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
