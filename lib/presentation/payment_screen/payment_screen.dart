// lib/main.dart - Updated to show single enrollment details

import 'dart:convert';
import 'package:luminar_std/core/theme/theme_provider.dart';
import 'dart:io';
import 'package:luminar_std/presentation/payment_screen/gateway_icons.dart';
import 'package:luminar_std/presentation/payment_screen/icici_payment_webview.dart';
import 'package:flutter/material.dart';
import 'package:luminar_std/presentation/test_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/presentation/home_screen/controller.dart';
import 'package:luminar_std/presentation/enrollment_screen/controller/controller.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/repository/payment_screen/model.dart';
import 'package:luminar_std/repository/payment_screen/service.dart';
import 'package:luminar_std/repository/razorpay/model/emi_res_model.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

// Define enums locally if needed
enum TransactionStatus { completed, failed, pending }

enum EmiStatus { paid, pending, overdue }

class PaymentScreen extends StatefulWidget {
  final String enrollmentId; // Add this parameter to accept enrollment ID
  final String uid;
  const PaymentScreen({
    super.key,
    required this.enrollmentId,
    required this.uid, // Optional parameter
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  EnrollmentDetailResponse? _paymentData; // Single enrollment data
  bool _isLoading = true;
  String? _errorMessage;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentErrorResponse);
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccessResponse);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWalletSelected);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData({bool forceRefresh = false}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final controller = Provider.of<DashboardController>(
        context,
        listen: false,
      );

      // getDashboardData is a no-op if data is already cached (C-1 guard),
      // so a forced refresh is required after a payment — otherwise the
      // dashboard's financial summary/payment status silently stays stale.
      await controller.getDashboardData(
        context: context,
        forceRefresh: forceRefresh,
      );

      await _fetchEnrollmentDetails();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load payment data. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchEnrollmentDetails() async {
    final controller = Provider.of<DashboardController>(context, listen: false);
    final dashboardData = controller.dashboardModel?.dashboard;

    if (dashboardData == null) return;

    final enrollments = dashboardData.enrollmentDetails?.enrollments ?? [];
    if (enrollments.isEmpty) return;

    final accessKey = await AppUtils.getAccessKey();
    if (accessKey == null || accessKey.isEmpty) return;

    // If enrollmentId is provided, fetch only that specific enrollment
    String? targetEnrollmentId = widget.enrollmentId;

    // If no enrollmentId provided, use the first enrollment from dashboard
    if (targetEnrollmentId == null || targetEnrollmentId.isEmpty) {
      final firstEnrollment = enrollments.firstOrNull;
      targetEnrollmentId = firstEnrollment?.basicInfo?.uid;

      if (targetEnrollmentId == null || targetEnrollmentId.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'No enrollment found';
          });
        }
        return;
      }
    }

    try {
      final detailsResponse = await PaymentScreenService()
          .fetchEnrollmentDetails(targetEnrollmentId, accessKey);

      if (detailsResponse.success && detailsResponse.data != null && mounted) {
        _savePaymentNotifications(detailsResponse.data!);
        setState(() {
          _paymentData = detailsResponse.data;
        });
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                detailsResponse.message ?? 'Failed to load enrollment details';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching details for $targetEnrollmentId: $e');
      if (mounted) {
        setState(() {
          _errorMessage =
              'Unable to load enrollment details. Please try again.';
        });
      }
    }
  }

  TransactionStatus _mapTransactionStatus(String? status) {
    if (status == null) return TransactionStatus.pending;
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return TransactionStatus.completed;
      case 'failed':
        return TransactionStatus.failed;
      default:
        return TransactionStatus.pending;
    }
  }

  EmiStatus _mapEmiStatus(String? status, bool isOverdue) {
    if (status == null) return EmiStatus.pending;
    if (status.toLowerCase() == 'paid') return EmiStatus.paid;
    if (isOverdue) return EmiStatus.overdue;
    return EmiStatus.pending;
  }

  Future<void> _savePaymentNotifications(EnrollmentDetailResponse data) async {
    final prefs = await SharedPreferences.getInstance();
    final installments = data.emiInstallments ?? [];
    final emiData = installments
        .map(
          (e) => {
            'uid': e.uid ?? '',
            'number': e.installmentNumber?.toInt() ?? 0,
            'due_date': e.dueDate?.toIso8601String() ?? '',
            'total': e.totalAmount?.toDouble() ?? 0.0,
            'pending': e.pendingAmount?.toDouble() ?? 0.0,
            'status': e.status ?? 'pending',
            'is_overdue': e.isOverdue ?? false,
          },
        )
        .toList();
    await prefs.setString(
      'payment_emi_data',
      jsonEncode({'installments': emiData}),
    );
  }

  String _getFormattedAmount(dynamic amount) {
    if (amount == null) return '₹0';
    if (amount is String) {
      return '₹${NumberFormat('#,##0').format(double.tryParse(amount) ?? 0)}';
    }
    if (amount is num) {
      return '₹${NumberFormat('#,##0').format(amount)}';
    }
    return '₹0';
  }

  double _getNumericAmount(dynamic amount) {
    if (amount == null) return 0;
    if (amount is String) {
      return double.tryParse(amount) ?? 0;
    }
    if (amount is num) {
      return amount.toDouble();
    }
    return 0;
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back,
              color: AppColors.textPrimary,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Payments',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildSingleEnrollmentHeader() {
    if (_paymentData == null) return const SizedBox.shrink();

    final data = _paymentData!;
    final remainingAmount = _getNumericAmount(data.totalPendingAmount);
    final isOverdue = data.isPaymentOverdue ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.school, color: AppColors.primary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.batch?.courseName ?? 'Unknown Course',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  data.batch?.batchName ?? 'Unknown Batch',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (remainingAmount > 0)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isOverdue ? AppColors.error : AppColors.statsOrange,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
        ),
      );
    }

    if (_errorMessage != null) {
      return NoInternetScreen();
    }

    if (_paymentData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No payment data available',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // Single enrollment - just show the content
    return Column(
      children: [
        _buildSingleEnrollmentHeader(),
        Expanded(child: _buildPaymentContent(_paymentData!)),
      ],
    );
  }

  void _handlePayment(EmiInstallment emi) async {
    final provider = Provider.of<EnrollmentProvider>(context, listen: false);

    // Show loading while fetching both gateway list + EMI order details in parallel
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: Colors.purple)),
    );

    try {
      final results = await Future.wait([
        provider.getEmiPaymentDetails(id: emi.uid ?? ''),
        PaymentScreenService().fetchPaymentGateways(),
      ]);

      if (!mounted) return;
      Navigator.pop(context); // dismiss loading

      final gateways = results[1] as List<PaymentGateway>;

      if (provider.emiResData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppUtils.friendlyError(
                provider.errorMessage ?? 'Failed to get payment details',
              ),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // If only Razorpay is available → skip the picker and go straight to checkout
      final hasOnlyRazorpay =
          gateways.length == 1 && gateways.first.id == 'razorpay';

      if (hasOnlyRazorpay) {
        _startEmiRazorpayPayment(provider.emiResData!);
      } else {
        _showGatewaySheet(gateways, provider.emiResData!, emi);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showGatewaySheet(
    List<PaymentGateway> gateways,
    EmiResponseData details,
    EmiInstallment emi,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _GatewaySheet(
        gateways: gateways,
        emi: emi,
        onSelect: (gateway) async {
          Navigator.pop(context);
          if (gateway.id == 'razorpay') {
            _startEmiRazorpayPayment(details);
          } else if (gateway.id == 'icici') {
            await _openIciciEmiPayment(emi.uid ?? '');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${gateway.label} integration coming soon.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: statusColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttractiveNextDueCard(EnrollmentDetailResponse data) {
    final isOverdue = data.isPaymentOverdue ?? false;

    // Find next due EMI
    EmiInstallment? nextDueEmi;
    num nextDueAmount = 0;
    DateTime nextDueDate = DateTime.now();

    if (data.emiInstallments != null && data.emiInstallments!.isNotEmpty) {
      final pendingEmis = data.emiInstallments!
          .where((e) => e.status?.toLowerCase() != 'paid')
          .toList();
      if (pendingEmis.isNotEmpty) {
        pendingEmis.sort((a, b) {
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        nextDueEmi = pendingEmis.first;
        // Use pendingAmount (what's actually owed) — matches what the backend
        // creates the Razorpay order for. totalAmount is the gross installment
        // value and differs when a partial payment has already been made.
        nextDueAmount = nextDueEmi.pendingAmount ?? nextDueEmi.totalAmount ?? 0;
        nextDueDate = nextDueEmi?.dueDate ?? DateTime.now();
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isOverdue
                    ? [
                        Colors.red[400]!,
                        Colors.orange[400]!,
                        Colors.yellow[400]!,
                      ]
                    : const [
                        Color(0xFF4158D0),
                        Color(0xFFC850C0),
                        Color(0xFFFFCC70),
                      ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (isOverdue ? Colors.red : Colors.purple).withValues(
                    alpha: 0.3,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          Container(
            height: 180,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isOverdue
                                ? Icons.warning_amber
                                : Icons.calendar_today,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isOverdue ? 'Overdue Payment' : 'Next Payment',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            data.paymentType?.toUpperCase() ?? 'N/A',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOverdue ? 'Overdue Amount' : 'Due Amount',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${NumberFormat('#,##0').format(nextDueAmount)}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.event,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMMM, yyyy').format(nextDueDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Pay Now Button with Razorpay Integration
                    if (nextDueEmi != null)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _handlePayment(nextDueEmi!),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isOverdue ? 'Pay Overdue' : 'Pay Now',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF4158D0),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                    color: Color(0xFF4158D0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryList(
    BuildContext context,
    List<PaymentTransaction>? transactions,
  ) {
    if (transactions == null || transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.history,
                size: 32,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'No transactions found',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('d/M/yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const Divider(height: 12),
      itemBuilder: (context, index) {
        final txn = transactions[index];
        final amount = _getNumericAmount(txn.amount);
        final status = _mapTransactionStatus(txn.status);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: status == TransactionStatus.completed
                      ? AppColors.statsGreen.withValues(alpha: 0.1)
                      : status == TransactionStatus.failed
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.statsOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  status == TransactionStatus.completed
                      ? Icons.check_circle
                      : status == TransactionStatus.failed
                      ? Icons.cancel
                      : Icons.pending,
                  size: 16,
                  color: status == TransactionStatus.completed
                      ? Colors.green[600]
                      : status == TransactionStatus.failed
                      ? Colors.red[600]
                      : Colors.orange[600],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${dateFormat.format(txn.paymentDate ?? DateTime.now())} • ${txn.paymentMethodDisplay ?? txn.paymentMethod ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(amount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: status == TransactionStatus.completed
                          ? Colors.green[600]
                          : status == TransactionStatus.failed
                          ? Colors.red[600]
                          : Colors.orange[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: status == TransactionStatus.completed
                          ? AppColors.statsGreen.withValues(alpha: 0.1)
                          : status == TransactionStatus.failed
                          ? AppColors.error.withValues(alpha: 0.1)
                          : AppColors.statsOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status == TransactionStatus.completed
                          ? 'Success'
                          : status == TransactionStatus.failed
                          ? 'Failed'
                          : 'Pending',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: status == TransactionStatus.completed
                            ? AppColors.statsGreen
                            : status == TransactionStatus.failed
                            ? AppColors.error
                            : AppColors.statsOrange,
                      ),
                    ),
                  ),
                  if (status == TransactionStatus.completed) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _downloadReceipt(txn),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.download_rounded,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Receipt',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmiScheduleList(
    BuildContext context,
    List<EmiInstallment>? schedule,
  ) {
    if (schedule == null || schedule.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.schedule,
                size: 32,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'No EMI schedule available',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('d/M/yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    // Sort by installment number
    final sortedSchedule = List<EmiInstallment>.from(schedule)
      ..sort(
        (a, b) =>
            (a.installmentNumber ?? 0).compareTo(b.installmentNumber ?? 0),
      );

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedSchedule.length,
      separatorBuilder: (_, __) => const Divider(height: 8),
      itemBuilder: (context, index) {
        final emi = sortedSchedule[index];
        final emiStatus = _mapEmiStatus(emi.status, emi.isOverdue ?? false);
        final isEnabled =
            index == 0 ||
            sortedSchedule[index - 1].status?.toLowerCase() == 'paid';

        return InkWell(
          onTap: isEnabled && emiStatus != EmiStatus.paid
              ? () {
                  _handlePayment(emi);
                }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isEnabled ? AppColors.cardBackground : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: !isEnabled
                    ? AppColors.borderColor
                    : emiStatus == EmiStatus.overdue
                    ? AppColors.error.withValues(alpha: 0.3)
                    : emiStatus == EmiStatus.paid
                    ? AppColors.statsGreen.withValues(alpha: 0.3)
                    : AppColors.borderColor,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: !isEnabled
                        ? AppColors.surface
                        : emiStatus == EmiStatus.paid
                        ? AppColors.statsGreen.withValues(alpha: 0.1)
                        : emiStatus == EmiStatus.overdue
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      !isEnabled
                          ? Icons.lock_outline
                          : emiStatus == EmiStatus.paid
                          ? Icons.check
                          : Icons.payment,
                      size: 16,
                      color: !isEnabled
                          ? AppColors.textSecondary.withValues(alpha: 0.5)
                          : emiStatus == EmiStatus.paid
                          ? AppColors.statsGreen
                          : emiStatus == EmiStatus.overdue
                          ? AppColors.error
                          : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Installment ${emi.installmentNumber ?? index + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isEnabled
                              ? AppColors.textPrimary
                              : AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Due: ${dateFormat.format(emi.dueDate ?? DateTime.now())}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isEnabled
                              ? AppColors.textSecondary
                              : AppColors.textSecondary.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      // Paid → show original total. Unpaid → show what's
                      // actually due (matches the Razorpay order amount).
                      currencyFormat.format(
                        emiStatus == EmiStatus.paid
                            ? (emi.totalAmount ?? 0)
                            : (emi.pendingAmount ?? emi.totalAmount ?? 0),
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: !isEnabled
                            ? AppColors.textSecondary.withValues(alpha: 0.3)
                            : emiStatus == EmiStatus.overdue
                            ? AppColors.error
                            : emiStatus == EmiStatus.paid
                            ? AppColors.statsGreen
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (emiStatus != EmiStatus.paid)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (emiStatus == EmiStatus.overdue && isEnabled)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Overdue',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          if (emiStatus == EmiStatus.pending || !isEnabled)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isEnabled
                                    ? AppColors.statsOrange.withValues(
                                        alpha: 0.1,
                                      )
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                !isEnabled ? 'Locked' : 'Pending',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: isEnabled
                                      ? AppColors.statsOrange
                                      : AppColors.textSecondary.withValues(
                                          alpha: 0.5,
                                        ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isEnabled
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isEnabled ? 'Pay' : 'Wait',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: isEnabled
                                    ? AppColors.primary
                                    : AppColors.textSecondary.withValues(
                                        alpha: 0.5,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentContent(EnrollmentDetailResponse data) {
    final totalFee = _getNumericAmount(data.originalCourseFees);
    final paidAmount = _getNumericAmount(data.totalAmountPaid);
    final remainingAmount = _getNumericAmount(data.totalPendingAmount);
    final discount = _getNumericAmount(data.totalDiscountAmount);
    final admission = _getNumericAmount(data.originalAdmissionFees);
    final progress = data.paymentCompletionPercentage ?? 0;
    final isOverdue = data.isPaymentOverdue ?? false;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.batch?.courseName ?? 'Unknown Course',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.batch?.batchName ?? 'Unknown Batch',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? AppColors.error.withValues(alpha: 0.1)
                            : AppColors.statsGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isOverdue ? 'Overdue' : 'Active',
                        style: TextStyle(
                          fontSize: 11,
                          color: isOverdue
                              ? AppColors.error
                              : AppColors.statsGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if ((data.studentName ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data.studentName ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.badge_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data.studentId ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          data.paymentTypeDisplay == "Full Amount"
              ? SizedBox()
              : _buildAttractiveNextDueCard(data),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatCard(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Total Fee',
                  value: '₹${NumberFormat('#,##0').format(totalFee)}',
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.check_circle_outline,
                  label: 'Paid',
                  value: '₹${NumberFormat('#,##0').format(paidAmount)}',
                  color: Colors.green,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.pending_outlined,
                  label: 'Remaining',
                  value: '₹${NumberFormat('#,##0').format(remainingAmount)}',
                  color: Colors.orange,
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatCard(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Total Discount',
                  value: '₹${NumberFormat('#,##0').format(discount)}',
                  color: const Color.fromARGB(255, 40, 17, 124),
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.check_circle_outline,
                  label: 'Admission Fee',
                  value: '₹${NumberFormat('#,##0').format(admission)}',
                  color: const Color.fromARGB(255, 145, 25, 95),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${progress.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (progress / 100).clamp(0.0, 1.0),
                    backgroundColor: AppColors.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOverdue ? AppColors.error : AppColors.primary,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${NumberFormat('#,##0').format(paidAmount)} of ₹${NumberFormat('#,##0').format(totalFee)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if ((data.paymentType ?? '').toLowerCase().contains('emi'))
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.statsOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.schedule,
                      color: AppColors.statsOrange,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    'EMI Schedule',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${data.emiInstallments?.where((e) => e.status?.toLowerCase() != 'paid').length ?? 0} pending',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _buildEmiScheduleList(
                        context,
                        data.emiInstallments,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.history,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                title: Text(
                  'Payment History',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${data.paymentTransactions?.length ?? 0} transactions',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _buildPaymentHistoryList(
                      context,
                      data.paymentTransactions,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _downloadReceipt(PaymentTransaction txn) async {
    try {
      final data = _paymentData;
      final dateFormat = DateFormat('dd/MM/yyyy');
      final currencyFormat = NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
      );

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ── Header ──
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('6C5CE7'),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'LUMINAR TECHNOHUB',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Payment Receipt',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),

                // ── Receipt Info ──
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Receipt No: ${txn.transactionId ?? txn.uid ?? 'N/A'}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      'Date: ${dateFormat.format(txn.paymentDate ?? DateTime.now())}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 16),

                // ── Student Details ──
                pw.Text(
                  'Student Details',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                _pdfRow('Student Name', data?.studentName ?? 'N/A'),
                _pdfRow('Student ID', data?.studentId ?? 'N/A'),
                _pdfRow('Course', data?.batch?.courseName ?? 'N/A'),
                _pdfRow('Batch', data?.batch?.batchName ?? 'N/A'),
                pw.SizedBox(height: 16),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 16),

                // ── Payment Details ──
                pw.Text(
                  'Payment Details',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                _pdfRow(
                  'Amount Paid',
                  currencyFormat.format(_getNumericAmount(txn.amount)),
                ),
                _pdfRow(
                  'Payment Method',
                  txn.paymentMethodDisplay ?? txn.paymentMethod ?? 'N/A',
                ),
                _pdfRow('Status', txn.status?.toUpperCase() ?? 'N/A'),
                if ((txn.transactionId ?? '').isNotEmpty)
                  _pdfRow('Transaction ID', txn.transactionId!),
                pw.SizedBox(height: 16),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 16),

                // ── Fee Summary ──
                pw.Text(
                  'Fee Summary',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                _pdfRow(
                  'Total Course Fee',
                  currencyFormat.format(
                    _getNumericAmount(data?.originalCourseFees),
                  ),
                ),
                _pdfRow(
                  'Total Paid',
                  currencyFormat.format(
                    _getNumericAmount(data?.totalAmountPaid),
                  ),
                ),
                _pdfRow(
                  'Balance Due',
                  currencyFormat.format(
                    _getNumericAmount(data?.totalPendingAmount),
                  ),
                ),
                pw.SizedBox(height: 32),

                // ── Footer ──
                pw.Center(
                  child: pw.Text(
                    'This is a computer-generated receipt and does not require a signature.',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/receipt_$timestamp.pdf');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                const Expanded(child: Text('Receipt saved successfully')),
                TextButton(
                  onPressed: () => OpenFilex.open(file.path),
                  child: const Text(
                    'OPEN',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.statsGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Failed to download receipt. Please try again.',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void handlePaymentErrorResponse(PaymentFailureResponse response) {
    final error = response.error ?? {};
    final reason = error['reason'] as String? ?? '';
    final step = error['step'] as String? ?? '';
    final code = response.code ?? -1;

    String title;
    String message;
    IconData icon;
    Color iconColor;

    // Razorpay code 0 = network error
    if (code == 0) {
      icon = Icons.wifi_off_rounded;
      iconColor = AppColors.statsOrange;
      title = 'No Internet Connection';
      message = 'Please check your connection and try again.';
    }
    // User cancelled / closed the Razorpay sheet
    else if (reason == 'cancel' || reason == 'dismissed') {
      icon = Icons.cancel_outlined;
      iconColor = AppColors.textSecondary;
      title = 'Payment Cancelled';
      message = 'You closed the payment window. No amount was deducted.';
    }
    // Authentication / OTP failed
    else if (step == 'payment_authentication') {
      icon = Icons.lock_outline_rounded;
      iconColor = AppColors.error;
      title = 'Authentication Failed';
      message =
          'Your bank declined the payment. Please verify your OTP or try a different card/UPI.';
    }
    // Card / UPI not authorized
    else if (step == 'payment_authorization') {
      icon = Icons.credit_card_off_rounded;
      iconColor = AppColors.error;
      title = 'Payment Not Authorized';
      message =
          'Your bank did not authorize this transaction. Please try a different payment method.';
    }
    // Generic bad-request / declined
    else {
      icon = Icons.error_outline_rounded;
      iconColor = AppColors.error;
      title = 'Payment Failed';
      message =
          'Your payment could not be processed. Please try again or use a different payment method.';
    }

    _showPaymentResultDialog(
      icon: icon,
      iconColor: iconColor,
      title: title,
      message: message,
      isSuccess: false,
    );
  }

  void handlePaymentSuccessResponse(PaymentSuccessResponse response) {
    _showPaymentResultDialog(
      icon: Icons.check_circle_outline_rounded,
      iconColor: AppColors.statsGreen,
      title: 'Payment Successful',
      message:
          'Your payment has been received.\nPayment ID: ${response.paymentId ?? '—'}',
      isSuccess: true,
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _initializeData(forceRefresh: true);
    });
  }

  void handleExternalWalletSelected(ExternalWalletResponse response) {
    _showPaymentResultDialog(
      icon: Icons.account_balance_wallet_outlined,
      iconColor: AppColors.primary,
      title: 'Wallet Selected',
      message:
          '${response.walletName ?? 'External wallet'} was selected for payment.',
      isSuccess: true,
    );
  }

  void _showPaymentResultDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSuccess
                      ? AppColors.statsGreen
                      : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isSuccess ? 'Done' : 'Try Again',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showAlertDialog(BuildContext context, String title, String message) {
    AlertDialog alert = AlertDialog(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text(message),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      actions: [
        TextButton(
          child: Text(
            "OK",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<void> _openIciciPayment(String enrollmentId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final session = await PaymentScreenService().getIciciSession(enrollmentId);
    if (!mounted) return;
    Navigator.pop(context);

    if (session != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IciciPaymentWebView(
            paymentUrl: session.url,
            amount: session.amount,
            discountApplied: session.discountApplied,
            discountAmount: session.discountAmount,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to get ICICI payment URL.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openIciciEmiPayment(String emiId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final session = await PaymentScreenService().getIciciEmiSession(emiId);
    if (!mounted) return;
    Navigator.pop(context);

    if (session != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IciciPaymentWebView(
            paymentUrl: session.url,
            amount: session.amount,
            discountApplied: session.discountApplied,
            discountAmount: session.discountAmount,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to get ICICI EMI payment URL.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _startEmiRazorpayPayment(EmiResponseData details) {
    var options = {
      'key': details.key,
      'amount': details.amount,
      "order_id": details.orderId,
      'name': details.name,
      'description': details.description,
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': details.prefill?.contact,
        'email': details.prefill?.email,
      },
      'external': {
        'wallets': ['paytm'],
      },
    };
    _razorpay.open(options);
  }
}

// ─── Payment Gateway Selection Sheet ─────────────────────────────────────────

class _GatewaySheet extends StatelessWidget {
  const _GatewaySheet({
    required this.gateways,
    required this.emi,
    required this.onSelect,
  });

  final List<PaymentGateway> gateways;
  final EmiInstallment emi;
  final void Function(PaymentGateway) onSelect;

  @override
  Widget build(BuildContext context) {
    final amount = emi.pendingAmount ?? emi.totalAmount ?? 0;
    final installNo = emi.installmentNumber?.toInt() ?? 0;
    final dueDate = emi.dueDate;
    final isOverdue = emi.isOverdue ?? false;
    final dueFmt = dueDate != null
        ? DateFormat('dd MMM yyyy').format(dueDate)
        : '—';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Payment summary header ──────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isOverdue
                    ? [const Color(0xFFB71C1C), const Color(0xFFE53935)]
                    : [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isOverdue
                        ? Icons.warning_amber_rounded
                        : Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        installNo > 0
                            ? 'EMI Installment #$installNo'
                            : 'Payment Due',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${NumberFormat('#,##,###').format(amount)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isOverdue ? 'OVERDUE' : 'DUE DATE',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white60,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dueFmt,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Gateway section label ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.payment_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'SELECT PAYMENT METHOD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Divider(
            color: AppColors.borderColor.withValues(alpha: 0.5),
            height: 1,
          ),
          const SizedBox(height: 4),

          // ── Gateway tiles ───────────────────────────────────────────────
          ...gateways.map(
            (gw) => _GatewayTile(gateway: gw, onTap: () => onSelect(gw)),
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _GatewayTile extends StatelessWidget {
  const _GatewayTile({required this.gateway, required this.onTap});

  final PaymentGateway gateway;
  final VoidCallback onTap;

  static const _kRazorpayBlue = Color(0xFF2C73D2);
  static const _kIciciOrange = Color(0xFFE87722);

  Color get _brandColor {
    switch (gateway.id) {
      case 'razorpay':
        return _kRazorpayBlue;
      case 'icici':
        return _kIciciOrange;
      default:
        return AppColors.primary;
    }
  }

  //TODO: Replace with actual logos if available
  Widget _icon() {
    switch (gateway.id) {
      case 'razorpay':
        return CircleAvatar(
          radius: 19,
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          child: Image.asset('assets/images/ray.jpeg', width: 45, height: 45),
        );
      case 'icici':
        return CircleAvatar(
          radius: 19,
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          child: Image.asset('assets/images/icici.png', width: 30, height: 30),
        );
      default:
        return Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _brandColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.account_balance_rounded,
            color: _brandColor,
            size: 20,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            _icon(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gateway.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _subtitle(),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle() {
    switch (gateway.id) {
      case 'razorpay':
        return 'Cards, UPI, Net Banking & Wallets';
      case 'icici':
        return 'ICICI Bank Net Banking & Cards';
      default:
        return 'Secure online payment';
    }
  }
}
