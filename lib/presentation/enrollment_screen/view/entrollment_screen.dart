import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';
import 'package:luminar_std/presentation/enrollment_screen/controller/controller.dart';
import 'package:luminar_std/presentation/enrollment_screen/view/widget/emi_card.dart';
import 'package:luminar_std/presentation/enrollment_screen/view/widget/pay_in_full_card.dart';
import 'package:luminar_std/presentation/global_widget/shimmer.dart';
import 'package:provider/provider.dart';

class EnrollmentDetailsScreen extends StatefulWidget {
  const EnrollmentDetailsScreen({Key? key, required this.index});
  final int index;
  @override
  State<EnrollmentDetailsScreen> createState() =>
      _EnrollmentDetailsScreenState();
}

class _EnrollmentDetailsScreenState extends State<EnrollmentDetailsScreen> {
  int selectedPaymentMethod = 0;
  int? selectedEmiPlan;
  bool isEmiExpanded = false;
  bool showFullPaymentDetails = true; // Set to true for initial display

  final List<Map<String, dynamic>> emiPlans = [
    {'months': 3, 'monthly': 8667.0, 'total': 26000.0, 'isPopular': true},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await Provider.of<EnrollmentProvider>(
        context,
        listen: false,
      ).fetchEnrollData(context: context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final enrollmentProvider = Provider.of<EnrollmentProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,

      body: SafeArea(
        child: enrollmentProvider.isLoading
            ? const DashboardShimmer()
            : enrollmentProvider.errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading EnrollmentScreen',
                        style: AppTextStyles.headerName.copyWith(
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        enrollmentProvider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.activitySubtitle,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          enrollmentProvider.refreshData(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(200, 45),
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  // App Bar (keep as is)
                  _buildAppBar(),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          _buildCourseHeader(),
                          const SizedBox(height: 20),
                          _buildPaymentOptionsTitle(),
                          const SizedBox(height: 24),

                          // Full Payment Tile
                          PaymentTile(
                            icon: Icons.flash_on_rounded,
                            iconColor: AppColors.primary,
                            title:
                                enrollmentProvider
                                    .enrollmentDataRes
                                    ?.enrollments[widget.index]
                                    .course
                                    .courseName ??
                                "",
                            subtitle: 'One-time payment',
                            amount: '₹26,000',
                            discount: 'Save ₹2,000',
                            showOriginalPrice: true,
                            isSelected: selectedPaymentMethod == 0,
                            isFullpayment: true,
                            onTap: () {
                              setState(() {
                                if (selectedPaymentMethod == 0) {
                                  // If already selected, deselect it
                                  selectedPaymentMethod =
                                      -1; // or any value that's not 0 or 1
                                  showFullPaymentDetails = false;
                                } else {
                                  // Select this option
                                  selectedPaymentMethod = 0;
                                  showFullPaymentDetails = true;
                                  isEmiExpanded = false;
                                  selectedEmiPlan = null;
                                }
                              });
                            },
                          ),

                          const SizedBox(height: 12),

                          // EMI Payment Tile
                          PaymentTile(
                            icon: Icons.calendar_month_rounded,
                            iconColor: AppColors.statsOrange,
                            title: 'EMI Payment Plan',
                            subtitle: 'Pay in installments',
                            amount: 'Multiple plans available',
                            isSelected: selectedPaymentMethod == 1,
                            isFullpayment: false,
                            onTap: () {
                              setState(() {
                                if (selectedPaymentMethod == 1) {
                                  // If already selected, deselect it
                                  selectedPaymentMethod = -1;
                                  showFullPaymentDetails = false;
                                  isEmiExpanded = false;
                                  selectedEmiPlan = null;
                                } else {
                                  // Select this option
                                  selectedPaymentMethod = 1;
                                  showFullPaymentDetails = false;
                                  isEmiExpanded = true;
                                }
                              });
                            },
                          ),

                          if (selectedPaymentMethod == 1 && isEmiExpanded) ...[
                            const SizedBox(height: 20),
                            ...emiPlans.asMap().entries.map(
                              (entry) => EmiBreakdownCard(
                                plan: entry.value,
                                onConfirm: () {
                                  setState(() {
                                    if (selectedEmiPlan == entry.key) {
                                      // If already selected, deselect it
                                      selectedEmiPlan = null;
                                    } else {
                                      // Select this plan
                                      selectedEmiPlan = entry.key;
                                    }
                                  });
                                },
                              ),

                              // EmiCard(

                              //   plan: entry.value,
                              //   isSelected: selectedEmiPlan == entry.key,
                              //   onTap: () {
                              //     setState(() {
                              //       if (selectedEmiPlan == entry.key) {
                              //         // If already selected, deselect it
                              //         selectedEmiPlan = null;
                              //       } else {
                              //         // Select this plan
                              //         selectedEmiPlan = entry.key;
                              //       }
                              //     });
                              //   },
                              // ),
                            ),
                          ],

                          if (selectedPaymentMethod == 0 &&
                              showFullPaymentDetails) ...[
                            const SizedBox(height: 32),
                            _buildPaymentBreakdown(),
                            const SizedBox(height: 20),
                            _buildRazorpayInfo(),
                          ],

                          const SizedBox(height: 40),
                          _buildSecuritySection(),
                          const SizedBox(height: 30),
                          _buildTrustBadges(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),

                  _buildBottomButton(),
                ],
              ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.white, AppColors.scaffoldBackground],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
                size: 16,
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primaryLight.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Luminar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Complete your Payment",
            style: AppTextStyles.courseCardLabel,
          ),
          const SizedBox(height: 8),
          Text(
            'ASP.NET MVC with Angular',
            style: AppTextStyles.courseCardTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient1,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Amount to Pay:", style: TextStyle(color: Colors.white)),
                  Row(
                    children: [
                      Text(
                        "₹28000",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.red,
                          decorationThickness: 3,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        "₹26000",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          if (selectedPaymentMethod == 0 && showFullPaymentDetails)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.statsGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.discount_rounded,
                    size: 16,
                    color: AppColors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Save ₹2,000',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionsTitle() {
    return Row(
      children: [
        Icon(Icons.payment_rounded, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          'PAYMENT OPTIONS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 12),
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.textSecondary.withOpacity(0.3),
                  AppColors.textSecondary.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentBreakdown() {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'PAYMENT BREAKDOWN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 12),
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.textSecondary.withOpacity(0.3),
                      AppColors.textSecondary.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildBreakdownRow(
                'Original Pending Amount:',
                '₹28,000',
                Icons.receipt_rounded,
              ),
              const SizedBox(height: 16),
              _buildBreakdownRow(
                'Full Payment Discount:',
                '- ₹2,000',
                Icons.discount_rounded,
                valueColor: AppColors.statsGreen,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: AppColors.borderColor),
              ),
              _buildBreakdownRow(
                'Final Amount to Pay:',
                '₹26,000',
                Icons.payment_rounded,
                isBold: true,
                valueColor: AppColors.primary,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.statsGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.savings_rounded,
                      size: 16,
                      color: AppColors.statsGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Total Savings:',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      '₹2,000',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.statsGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(
    String label,
    String value,
    IconData icon, {
    bool isBold = false,
    Color valueColor = AppColors.textPrimary,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRazorpayInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.payment_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Redirecting to Razorpay for secure payment',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSecurityIcon(
            Icons.lock_outline_rounded,
            '256-bit SSL',
            AppColors.statsBlue,
          ),
          Container(height: 30, width: 1, color: AppColors.borderColor),
          _buildSecurityIcon(
            Icons.verified_user_rounded,
            'Secure payment',
            AppColors.statsGreen,
          ),
          Container(height: 30, width: 1, color: AppColors.borderColor),
          _buildSecurityIcon(
            Icons.shield_rounded,
            'Protected',
            AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityIcon(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textHint,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildTrustBadges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTrustBadge('Razorpay', Icons.verified_rounded),
        const SizedBox(width: 20),
        _buildTrustBadge('SSL', Icons.security_rounded),
        const SizedBox(width: 20),
        _buildTrustBadge('PCI DSS', Icons.credit_card_rounded),
      ],
    );
  }

  Widget _buildTrustBadge(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textHint,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return selectedPaymentMethod == 1
        ? SizedBox()
        : Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _showPaymentConfirmation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: AppColors.textWhite,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.flash_on_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Pay ₹26,000 Now',

                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 12,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Secured with 256-bit SSL encryption',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
  }

  void _showPaymentConfirmation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildConfirmationSheet(),
    );
  }

  Widget _buildConfirmationSheet() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    selectedPaymentMethod == 0
                        ? Icons.flash_on_rounded
                        : Icons.calendar_month_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Confirm payment',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildConfirmRow(
                        'Amount',
                        selectedPaymentMethod == 0 ? '₹26,000' : '₹8,667',
                        Icons.currency_rupee_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildConfirmRow(
                        'Payment method',
                        selectedPaymentMethod == 0
                            ? 'Full payment'
                            : 'EMI - 3 months',
                        Icons.payment_rounded,
                      ),
                      if (selectedPaymentMethod == 1) ...[
                        const SizedBox(height: 16),
                        _buildConfirmRow(
                          'Total payable',
                          '₹26,000',
                          Icons.account_balance_wallet_rounded,
                        ),
                      ] else ...[
                        const SizedBox(height: 16),
                        _buildConfirmRow(
                          'You save',
                          '₹2,000',
                          Icons.savings_rounded,
                          valueColor: AppColors.statsGreen,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: AppColors.borderColor,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showSuccessMessage();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: AppColors.textWhite,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Pay now',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmRow(
    String label,
    String value,
    IconData icon, {
    Color valueColor = AppColors.textPrimary,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.textWhite,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedPaymentMethod == 0
                    ? 'Redirecting to Razorpay for secure payment...'
                    : 'Setting up EMI payment...',
                style: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: AppColors.textWhite,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.statsGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
