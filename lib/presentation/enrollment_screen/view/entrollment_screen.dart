import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';
import 'package:luminar_std/presentation/enrollment_screen/controller/controller.dart';
import 'package:luminar_std/presentation/enrollment_screen/view/widget/pay_in_full_card.dart';
import 'package:luminar_std/presentation/global_widget/shimmer.dart';
import 'package:luminar_std/repository/enrollment_screen/model/emiplans_model.dart';
import 'package:luminar_std/repository/enrollment_screen/service/installment_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class EnrollmentDetailsScreen extends StatefulWidget {
  const EnrollmentDetailsScreen({
    Key? key,
    required this.index,
    required this.backbuttonValue,
  });
  final int index;
  final bool backbuttonValue;

  @override
  State<EnrollmentDetailsScreen> createState() =>
      _EnrollmentDetailsScreenState();
}

class _EnrollmentDetailsScreenState extends State<EnrollmentDetailsScreen> {
  int selectedPaymentMethod = 0;
  String? selectedEmiPlanId;
  int? expandedEmiTile;
  bool showFullPaymentDetails = true;

  late Future<List<EmiPlan>> emiPlans;
  EmiPlan? _selectedPlan;
  EmiPreviewResponse? _previewData;
  bool _isLoadingPreview = false;
  String? _errorMessage;
  final PaymentDetailsApiService _apiService = PaymentDetailsApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final provider = Provider.of<EnrollmentProvider>(context, listen: false);
      await Provider.of<EnrollmentProvider>(
        context,
        listen: false,
      ).fetchEnrollData(context: context);
    });
    _apiService.setEnrollmentId(
      Provider.of<EnrollmentProvider>(
            context,
            listen: false,
          ).enrollmentDataRes?.enrollments[widget.index].uid ??
          "",
    );
    emiPlans = _apiService.fetchEmiPlans();
  }

  void _selectPlan(EmiPlan plan) async {
    if (plan.id.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Error'),
          content: Text('Selected plan has no ID. Please try again.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK')),
          ],
        ),
      );

      setState(() {
        _errorMessage = 'Invalid plan selected: Plan ID is missing';
      });
      return;
    }

    setState(() {
      _selectedPlan = plan;
      selectedEmiPlanId = plan.id;
      _isLoadingPreview = true;
      _previewData = null;
      _errorMessage = null;
    });

    try {
      final preview = await _apiService.fetchEmiPreview(plan.id);
      setState(() {
        _previewData = preview;
        _isLoadingPreview = false;
      });
    } catch (e) {
      String errorMsg = e.toString();

      // Try to extract meaningful error message
      if (errorMsg.contains('400')) {
        // The error might contain the response body
        try {
          // Check if the error message contains JSON
          if (errorMsg.contains('{') && errorMsg.contains('}')) {
            final jsonStart = errorMsg.indexOf('{');
            final jsonEnd = errorMsg.lastIndexOf('}') + 1;
            if (jsonStart >= 0 && jsonEnd > jsonStart) {
              final jsonStr = errorMsg.substring(jsonStart, jsonEnd);
              final errorData = json.decode(jsonStr);
              if (errorData.containsKey('message')) {
                errorMsg = errorData['message'];
              }
            }
          }
        } catch (parseError) {
          // If parsing fails, keep original message
          print('Error parsing error: $parseError');
        }
      }

      setState(() {
        _isLoadingPreview = false;
        _errorMessage = errorMsg;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMsg.length > 100 ? 'Failed to load EMI preview' : errorMsg,
            style: const TextStyle(fontSize: 13),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _deselectPlan() {
    setState(() {
      _selectedPlan = null;
      _previewData = null;
      selectedEmiPlanId = null;
      expandedEmiTile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentDetailsScreenProvider = Provider.of<EnrollmentProvider>(
      context,
    );

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: paymentDetailsScreenProvider.isLoading
            ? const DashboardShimmer()
            : paymentDetailsScreenProvider.errorMessage != null
            ? _buildErrorWidget(paymentDetailsScreenProvider)
            : Column(
                children: [
                  _buildAppBar(widget.backbuttonValue),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          _buildCourseHeader(paymentDetailsScreenProvider),
                          const SizedBox(height: 20),
                          _buildPaymentOptionsTitle(),
                          const SizedBox(height: 24),

                          // Full Payment Tile
                          PaymentTile(
                            icon: Icons.flash_on_rounded,
                            iconColor: AppColors.primary,
                            title: "Pay Full Amount",
                            subtitle: 'One-time payment',
                            wasnow:
                                "₹${paymentDetailsScreenProvider.enrollmentDataRes?.enrollments[widget.index].paymentInfo.amountPaid ?? ""}",
                            amount:
                                "₹${paymentDetailsScreenProvider.enrollmentDataRes?.enrollments[widget.index].paymentInfo.pendingAmount ?? ""}",
                            discount:
                                'Save ₹${paymentDetailsScreenProvider.enrollmentDataRes?.enrollments[widget.index].paymentInfo.totalDiscount ?? ""}',
                            showOriginalPrice: true,
                            isSelected: selectedPaymentMethod == 0,
                            isFullpayment: true,
                            onTap: () {
                              setState(() {
                                if (selectedPaymentMethod == 0) {
                                  selectedPaymentMethod = -1;
                                  showFullPaymentDetails = false;
                                } else {
                                  selectedPaymentMethod = 0;
                                  showFullPaymentDetails = true;
                                  expandedEmiTile = null;
                                  _deselectPlan();
                                }
                              });
                            },
                          ),

                          const SizedBox(height: 12),

                          // EMI Payment Main Tile
                          PaymentTile(
                            wasnow: "",
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
                                  selectedPaymentMethod = -1;
                                  showFullPaymentDetails = false;
                                  expandedEmiTile = null;
                                  _deselectPlan();
                                } else {
                                  selectedPaymentMethod = 1;
                                  showFullPaymentDetails = false;
                                }
                              });
                            },
                          ),

                          // EMI Plans List
                          if (selectedPaymentMethod == 1) ...[
                            const SizedBox(height: 20),
                            _buildEmiPlansHeader(),
                            const SizedBox(height: 12),
                            FutureBuilder<List<EmiPlan>>(
                              future: emiPlans,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: 48,
                                            color: Colors.red,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'Error loading EMI plans',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            snapshot.error.toString(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.red,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: 16),
                                          ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                emiPlans = _apiService
                                                    .fetchEmiPlans();
                                              });
                                            },
                                            child: Text('Retry'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Text(
                                        'No EMI plans available',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final plans = snapshot.data!;
                                return Column(
                                  children: [
                                    ...plans.asMap().entries.map(
                                      (entry) => _buildEmiTile(
                                        index: entry.key,
                                        plan: entry.value,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],

                          // Full Payment Details
                          if (selectedPaymentMethod == 0 &&
                              showFullPaymentDetails) ...[
                            const SizedBox(height: 32),
                            _buildPaymentBreakdown(
                              paymentDetailsScreenProvider,
                            ),
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
                  _buildBottomButton(paymentDetailsScreenProvider),
                ],
              ),
      ),
    );
  }

  Widget _buildErrorWidget(EnrollmentProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading EnrollmentScreen',
              style: AppTextStyles.headerName.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: AppTextStyles.activitySubtitle,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => provider.refreshData(context),
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
    );
  }

  Widget _buildEmiPlansHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.statsOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.format_list_bulleted_rounded,
            size: 16,
            color: AppColors.statsOrange,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'AVAILABLE EMI PLANS',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
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

  Widget _buildEmiTile({required int index, required EmiPlan plan}) {
    final isExpanded = expandedEmiTile == index;
    final isSelected = _selectedPlan?.id == plan.id;

    return Column(
      children: [
        // EMI Tile Header
        GestureDetector(
          onTap: () {
            setState(() {
              if (isExpanded) {
                expandedEmiTile = null;
                if (isSelected) {
                  _deselectPlan();
                }
              } else {
                expandedEmiTile = index;
                // Automatically select and load details when expanded
                if (!isSelected) {
                  _selectPlan(plan);
                }
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isExpanded
                    ? AppColors.statsOrange.withOpacity(0.5)
                    : isSelected
                    ? AppColors.primary
                    : Colors.transparent,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Plan icon with month count
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.statsOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (index + 1).toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.statsOrange,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Plan details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              plan.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (plan.planDurationMonths <= 3)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.statsOrange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'POPULAR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${plan.installmentCount} installments • First EMI after ${plan.firstEmiAfterDays} days',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Expand/collapse icon
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 28,
                ),
              ],
            ),
          ),
        ),

        // Expanded EMI Details - Show directly when expanded
        if (isExpanded) ...[
          const SizedBox(height: 12),
          // Show loading or preview based on selection state
          if (_selectedPlan?.id == plan.id)
            _buildPlanPreview()
          else if (_isLoadingPreview && _selectedPlan?.id == plan.id)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Loading EMI details...'),
                  ],
                ),
              ),
            )
          else
            // Show placeholder while loading
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Loading EMI details...'),
                  ],
                ),
              ),
            ),
        ],

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPlanPreview() {
    if (_isLoadingPreview) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: const Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Loading EMI details...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      // Parse the error response if it's a JSON string
      String errorTitle = 'Error';
      String errorDetail = _errorMessage!;
      Map<String, dynamic>? errorData;

      try {
        // Check if the error message contains JSON
        if (_errorMessage!.contains('{') && _errorMessage!.contains('}')) {
          final jsonStart = _errorMessage!.indexOf('{');
          final jsonEnd = _errorMessage!.lastIndexOf('}') + 1;
          if (jsonStart >= 0 && jsonEnd > jsonStart) {
            final jsonStr = _errorMessage!.substring(jsonStart, jsonEnd);
            errorData = json.decode(jsonStr);

            if (errorData != null) {
              errorTitle =
                  errorData['status']?.toString().toUpperCase() ?? 'ERROR';
              errorDetail = errorData['message'] ?? _errorMessage!;
            }
          }
        }
      } catch (e) {
        // If JSON parsing fails, use the original error message
        print('Error parsing error JSON: $e');
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.error_outline, color: Colors.red, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        errorTitle,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Unable to load EMI details',
                        style: TextStyle(
                          color: Colors.red.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Display error details in a card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    errorDetail,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),

                  // Show payment analysis if available
                  if (errorData != null &&
                      errorData.containsKey('payment_analysis')) ...[
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.borderColor),
                    const SizedBox(height: 8),
                    const Text(
                      'Payment Analysis:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildAnalysisRow(
                      'Batch EMI Fees',
                      '₹${_formatAmount(errorData['payment_analysis']['batch_emi_fees'])}',
                    ),
                    _buildAnalysisRow(
                      'Total Paid',
                      '₹${_formatAmount(errorData['payment_analysis']['total_paid'])}',
                      valueColor: AppColors.statsGreen,
                    ),
                    _buildAnalysisRow(
                      'Total Discount',
                      '₹${_formatAmount(errorData['payment_analysis']['total_discount'])}',
                      valueColor: AppColors.statsGreen,
                    ),
                    const Divider(color: AppColors.borderColor),
                    _buildAnalysisRow(
                      'Amount to Finance',
                      '₹${_formatAmount(errorData['payment_analysis']['amount_to_finance'])}',
                      valueColor: Colors.red,
                      isBold: true,
                    ),
                    if (errorData['payment_analysis'].containsKey(
                      'calculation',
                    )) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          errorData['payment_analysis']['calculation'],
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      );
    }

    if (_previewData != null) {
      return EmiPreviewDetails(
        response: _previewData!,
        plan: _selectedPlan!,
        isSelected: true,
        onSelect: () {},
        onDeselect: _deselectPlan,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: const Center(child: Text('No preview available')),
    );
  }

  // Helper method for building analysis rows
  Widget _buildAnalysisRow(
    String label,
    String value, {
    Color valueColor = AppColors.textPrimary,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    try {
      if (amount is String) {
        return double.parse(amount).toStringAsFixed(0);
      } else if (amount is num) {
        return amount.toStringAsFixed(0);
      }
      return '0';
    } catch (e) {
      return '0';
    }
  }

  Widget _buildAppBar(bool backbuttonValue) {
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
          backbuttonValue == true
              ? Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                )
              : SizedBox(),
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

  Widget _buildCourseHeader(EnrollmentProvider provider) {
    final pendingAmount =
        provider
            .enrollmentDataRes
            ?.enrollments[widget.index]
            .paymentInfo
            .pendingAmount ??
        "";
    final amountPaid =
        provider
            .enrollmentDataRes
            ?.enrollments[widget.index]
            .paymentInfo
            .amountPaid ??
        "";
    final discount =
        provider
            .enrollmentDataRes
            ?.enrollments[widget.index]
            .paymentInfo
            .totalDiscount ??
        "";

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
            provider
                    .enrollmentDataRes
                    ?.enrollments[widget.index]
                    .course
                    .courseName ??
                "",
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
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Amount You Paid",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        "₹$amountPaid",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Amount to Pay:",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "₹$pendingAmount",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
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
                  const Icon(
                    Icons.discount_rounded,
                    size: 16,
                    color: AppColors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Save ₹$discount',
                    style: const TextStyle(
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
        const Text(
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

  Widget _buildPaymentBreakdown(EnrollmentProvider provider) {
    final grossAmount =
        provider
            .enrollmentDataRes
            ?.enrollments[widget.index]
            .paymentInfo
            .grossAmount ??
        "";
    final discount =
        provider
            .enrollmentDataRes
            ?.enrollments[widget.index]
            .paymentInfo
            .totalDiscount ??
        "";
    final pendingAmount =
        provider
            .enrollmentDataRes
            ?.enrollments[widget.index]
            .paymentInfo
            .pendingAmount ??
        "";

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
            const Text(
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
                'Total Amount:',
                '₹$grossAmount',
                Icons.receipt_rounded,
              ),
              const SizedBox(height: 16),
              _buildBreakdownRow(
                'Full Payment Discount:',
                '₹$discount',
                Icons.discount_rounded,
                valueColor: AppColors.statsGreen,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: AppColors.borderColor),
              ),
              _buildBreakdownRow(
                'Final Amount to Pay:',
                '₹$pendingAmount',
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
                    const Expanded(
                      child: Text(
                        'Total Savings:',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      '₹$discount',
                      style: const TextStyle(
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
      child: const Row(
        children: [
          Icon(Icons.payment_rounded, color: AppColors.primary, size: 20),
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

  Widget _buildBottomButton(EnrollmentProvider provider) {
    if (selectedPaymentMethod == -1) return const SizedBox();

    if (selectedPaymentMethod == 1 && _selectedPlan == null) {
      return Container(
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
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.textHint.withOpacity(0.3),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Text(
                'Select an EMI plan to continue',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final pendingAmount =
        provider
            .enrollmentDataRes
            ?.enrollments[widget.index]
            .paymentInfo
            .pendingAmount ??
        "";

    String amountToShow = '';
    String buttonText = '';

    if (selectedPaymentMethod == 0) {
      amountToShow = '₹$pendingAmount';
      buttonText = 'Pay $amountToShow Now';
    } else if (selectedPaymentMethod == 1 && _previewData != null) {
      final monthlyAmount =
          _previewData!.emiPreview.totalEmiAmount /
          _previewData!.emiPreview.installmentCount;
      amountToShow = '₹${monthlyAmount.toStringAsFixed(0)}/mo';
      buttonText = 'Pay First $amountToShow';
    } else {
      amountToShow = '';
      buttonText = 'Proceed with EMI';
    }

    return Container(
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
                    Icon(
                      selectedPaymentMethod == 0
                          ? Icons.flash_on_rounded
                          : Icons.calendar_month_rounded,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      buttonText,
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
                const Text(
                  'Secured with 256-bit SSL encryption',
                  style: TextStyle(fontSize: 11, color: AppColors.textHint),
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
    final provider = Provider.of<EnrollmentProvider>(context, listen: false);
    final grossAmount =
        provider
            .enrollmentDataRes
            ?.enrollments[widget.index]
            .paymentInfo
            .grossAmount ??
        "";
    final discount =
        provider
            .enrollmentDataRes
            ?.enrollments[widget.index]
            .paymentInfo
            .totalDiscount ??
        "";
    final pendingAmount =
        provider
            .enrollmentDataRes
            ?.enrollments[widget.index]
            .paymentInfo
            .pendingAmount ??
        "";

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
                      if (selectedPaymentMethod == 1 &&
                          _previewData != null) ...[
                        _buildConfirmRow(
                          'Plan',
                          _previewData!.emiPlanDetails.planName,
                          Icons.timer_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildConfirmRow(
                          'Monthly Payment',
                          '₹${(_previewData!.emiPreview.totalEmiAmount / _previewData!.emiPreview.installmentCount).toStringAsFixed(0)}',
                          Icons.currency_rupee_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildConfirmRow(
                          'Total Amount',
                          '₹${_previewData!.emiPreview.totalEmiAmount.toStringAsFixed(0)}',
                          Icons.account_balance_wallet_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildConfirmRow(
                          'Installments',
                          '${_previewData!.emiPreview.installmentCount} payments',
                          Icons.calendar_month_rounded,
                        ),
                      ] else if (selectedPaymentMethod == 0) ...[
                        _buildConfirmRow(
                          'Gross Amount',
                          '₹$grossAmount',
                          Icons.receipt_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildConfirmRow(
                          'Discount',
                          '₹$discount',
                          Icons.discount_rounded,
                          valueColor: AppColors.statsGreen,
                        ),
                        const SizedBox(height: 16),
                        _buildConfirmRow(
                          'Final Amount',
                          '₹$pendingAmount',
                          Icons.payment_rounded,
                          valueColor: AppColors.primary,
                        ),
                      ],
                      const SizedBox(height: 16),
                      _buildConfirmRow(
                        'Payment method',
                        selectedPaymentMethod == 0
                            ? 'Full payment'
                            : 'EMI - ${_previewData?.emiPlanDetails.planName ?? ''}',
                        Icons.payment_rounded,
                      ),
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
                          onPressed: () async {
                            log(
                              'this is key: ${provider.paymentDetails?.key ?? ""}',
                            );
                            await Provider.of<EnrollmentProvider>(
                              context,
                              listen: false,
                            ).getPaymentDetails(
                              id: provider.enrollmentData!.enrollments[0].uid,
                            );

                            Razorpay razorpay = Razorpay();
                            var options = {
                              'key': provider.paymentDetails?.key,
                              'amount': provider.paymentDetails?.amount,
                              "order_id": provider.paymentDetails?.orderId,
                              'name': provider.paymentDetails?.name,
                              'description':
                                  provider.paymentDetails?.description,
                              'retry': {'enabled': true, 'max_count': 1},
                              'send_sms_hash': true,
                              'prefill': {
                                'contact':
                                    provider.paymentDetails?.prefill?.contact,
                                'email':
                                    provider.paymentDetails?.prefill?.email,
                              },
                              'external': {
                                'wallets': ['paytm'],
                              },
                            };
                            razorpay.on(
                              Razorpay.EVENT_PAYMENT_ERROR,
                              handlePaymentErrorResponse,
                            );
                            razorpay.on(
                              Razorpay.EVENT_PAYMENT_SUCCESS,
                              handlePaymentSuccessResponse,
                            );
                            razorpay.on(
                              Razorpay.EVENT_EXTERNAL_WALLET,
                              handleExternalWalletSelected,
                            );
                            razorpay.open(options);
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
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Pay now',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, size: 18),
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

  void handlePaymentErrorResponse(PaymentFailureResponse response) {
    /*
    * PaymentFailureResponse contains three values:
    * 1. Error Code
    * 2. Error Description
    * 3. Metadata
    * */
    showAlertDialog(
      context,
      "Payment Failed",
      "Code: ${response.code}\nDescription: ${response.message}\nMetadata:${response.error.toString()}",
    );
  }

  void handlePaymentSuccessResponse(PaymentSuccessResponse response) {
    /*
    * Payment Success Response contains three values:
    * 1. Order ID
    * 2. Payment ID
    * 3. Signature
    * */
    showAlertDialog(
      context,
      "Payment Successful",
      "Payment ID: ${response.paymentId}",
    );
  }

  void handleExternalWalletSelected(ExternalWalletResponse response) {
    showAlertDialog(
      context,
      "External Wallet Selected",
      "${response.walletName}",
    );
  }

  void showAlertDialog(BuildContext context, String title, String message) {
    // set up the buttons
    Widget continueButton = ElevatedButton(
      child: const Text("Continue"),
      onPressed: () {},
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(title: Text(title), content: Text(message));
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}

// ==================== EMI PREVIEW DETAILS WIDGET ====================

class EmiPreviewDetails extends StatelessWidget {
  final EmiPreviewResponse response;
  final EmiPlan plan;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onDeselect;

  const EmiPreviewDetails({
    required this.response,
    required this.plan,
    required this.isSelected,
    required this.onSelect,
    required this.onDeselect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total EMI Amount',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '₹${response.emiPreview.totalEmiAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: AppColors.borderColor),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Installments',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${response.emiPreview.installmentCount} Payments',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'First EMI',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _formatDate(response.emiPreview.firstEmiDate),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Last EMI',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _formatDate(response.emiPreview.lastEmiDate),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // EMI Plan Details Expansion Tile
          _buildExpansionTile(
            title: 'EMI Plan Details',
            icon: Icons.info_outline,
            children: [
              _buildDetailRow('Plan Name', response.emiPlanDetails.planName),
              _buildDetailRow(
                'Description',
                response.emiPlanDetails.description,
              ),
              _buildDetailRow(
                'Installments',
                '${response.emiPlanDetails.installmentCount} payments',
              ),
              _buildDetailRow(
                'Frequency',
                response.emiPlanDetails.installmentFrequencyReadable,
              ),
              _buildDetailRow(
                'First EMI After',
                '${response.emiPlanDetails.firstEmiAfterDays} days',
              ),
            ],
          ),

          // Payment Schedule Expansion Tile
          if (response.installmentBreakdown.schedule.isNotEmpty)
            _buildExpansionTile(
              title: 'Payment Schedule',
              icon: Icons.calendar_month,
              initiallyExpanded: true,
              children: [
                // Schedule header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.borderColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Due Date',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '#',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Amount',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                // Schedule items
                ...response.installmentBreakdown.schedule.map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.borderColor.withOpacity(0.5),
                        ),
                      ),
                      color: item.isFirstInstallment
                          ? AppColors.statsGreen.withOpacity(0.1)
                          : item.isLastInstallment
                          ? AppColors.statsOrange.withOpacity(0.1)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.formattedDueDate,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (item.isFirstInstallment)
                                Text(
                                  'First',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.statsGreen,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              else if (item.isLastInstallment)
                                Text(
                                  'Last',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.statsOrange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '#${item.installmentNumber}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '₹${item.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: item.isLastInstallment
                                  ? AppColors.statsOrange
                                  : AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildExpansionTile({
    required String title,
    required IconData icon,
    List<Widget> children = const [],
    bool initiallyExpanded = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        initiallyExpanded: initiallyExpanded,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    try {
      if (amount is String) {
        return double.parse(amount).toStringAsFixed(0);
      } else if (amount is num) {
        return amount.toStringAsFixed(0);
      }
      return '0';
    } catch (e) {
      return '0';
    }
  }
}
