// lib/main.dart - Updated to show single enrollment details

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/home_screen/controller.dart';
import 'package:luminar_std/presentation/enrollment_screen/controller/controller.dart';
import 'package:luminar_std/repository/payment_screen/model.dart';
import 'package:luminar_std/repository/payment_screen/service.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await Provider.of<EnrollmentProvider>(
        context,
        listen: false,
      ).getEmiPaymentDetails(id: widget.uid);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    try {
      final controller = Provider.of<DashboardController>(
        context,
        listen: false,
      );

      await controller.getDashboardData(context: context);

      await _fetchEnrollmentDetails();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load payment data: $e';
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
      final details = await PaymentScreenService.fetchEnrollmentDetails(
        targetEnrollmentId,
        accessKey,
      );

      if (details != null && mounted) {
        setState(() {
          _paymentData = details;
        });
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load enrollment details';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching details for $targetEnrollmentId: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading details: $e';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    log('Thia is ${widget.uid}');
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.black87,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payments',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none,
                    color: Colors.black87,
                    size: 18,
                  ),
                  if (!_isLoading && _paymentData != null)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            onPressed: () {},
          ),
        ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              color: Colors.purple[50],
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.school, color: Colors.purple, size: 20),
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  data.batch?.batchName ?? 'Unknown Batch',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
                color: isOverdue ? Colors.red : Colors.orange,
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _initializeData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_paymentData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No payment data available',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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

  void _handlePayment(EmiInstallment emi) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Processing payment of ₹${(emi.totalAmount ?? 0).toStringAsFixed(0)}',
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: statusColor ?? Colors.black87,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.05),
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
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
        nextDueAmount = nextDueEmi?.totalAmount ?? 0;
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
                  color: (isOverdue ? Colors.red : Colors.purple).withOpacity(
                    0.3,
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
                            color: Colors.white.withOpacity(0.2),
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
                            color: Colors.white.withOpacity(0.9),
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
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            data.paymentType?.toUpperCase() ?? 'N/A',
                            style: const TextStyle(
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
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${NumberFormat('#,##0').format(nextDueAmount)}',
                          style: const TextStyle(
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
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMMM, yyyy').format(nextDueDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
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
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              final provider = Provider.of<EnrollmentProvider>(
                                context,
                                listen: false,
                              );
                              log(
                                'this is key: ${provider.emiResData?.key ?? ""}',
                              );
                              await Provider.of<EnrollmentProvider>(
                                context,
                                listen: false,
                              ).getEmiPaymentDetails(id: widget.uid);
                              ;
                            },
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
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF4158D0),
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
                color: Colors.white.withOpacity(0.1),
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
                color: Colors.white.withOpacity(0.05),
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
              Icon(Icons.history, size: 32, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No transactions found',
                style: TextStyle(color: Colors.grey[500]),
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

        return InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: status == TransactionStatus.completed
                        ? Colors.green[50]
                        : status == TransactionStatus.failed
                        ? Colors.red[50]
                        : Colors.orange[50],
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${dateFormat.format(txn.paymentDate ?? DateTime.now())} • ${txn.paymentMethodDisplay ?? txn.paymentMethod ?? 'Unknown'}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: status == TransactionStatus.completed
                            ? Colors.green[50]
                            : status == TransactionStatus.failed
                            ? Colors.red[50]
                            : Colors.orange[50],
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
                              ? Colors.green[700]
                              : status == TransactionStatus.failed
                              ? Colors.red[700]
                              : Colors.orange[700],
                        ),
                      ),
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
              Icon(Icons.schedule, size: 32, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No EMI schedule available',
                style: TextStyle(color: Colors.grey[500]),
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

        return InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: emiStatus == EmiStatus.overdue
                    ? Colors.red[100]!
                    : emiStatus == EmiStatus.paid
                    ? Colors.green[100]!
                    : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: emiStatus == EmiStatus.paid
                        ? Colors.green[50]
                        : emiStatus == EmiStatus.overdue
                        ? Colors.red[50]
                        : Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${emi.installmentNumber ?? index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: emiStatus == EmiStatus.paid
                            ? Colors.green[700]
                            : emiStatus == EmiStatus.overdue
                            ? Colors.red[700]
                            : Colors.blue[700],
                      ),
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Due: ${dateFormat.format(emi.dueDate ?? DateTime.now())}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(emi.totalAmount ?? 0),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: emiStatus == EmiStatus.overdue
                            ? Colors.red[600]
                            : emiStatus == EmiStatus.paid
                            ? Colors.green[600]
                            : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (emiStatus != EmiStatus.paid)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (emiStatus == EmiStatus.overdue)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Overdue',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.red[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          if (emiStatus == EmiStatus.pending)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Pending',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.orange[600],
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
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Pay',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
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
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Colors.blue,
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
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.batch?.batchName ?? 'Unknown Batch',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
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
                        color: isOverdue ? Colors.red[50] : Colors.green[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isOverdue ? 'Overdue' : 'Active',
                        style: TextStyle(
                          fontSize: 11,
                          color: isOverdue
                              ? Colors.red[700]
                              : Colors.green[700],
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
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data.studentName ?? '',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.badge_outlined,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data.studentId ?? '',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
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
                  color: Colors.grey.withOpacity(0.05),
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
                    const Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${progress.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
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
                    backgroundColor: Colors.grey[100],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOverdue ? Colors.red : Colors.blue,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${NumberFormat('#,##0').format(paidAmount)} of ₹${NumberFormat('#,##0').format(totalFee)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
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
                    color: Colors.grey.withOpacity(0.05),
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
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.schedule,
                      color: Colors.orange,
                      size: 18,
                    ),
                  ),
                  title: const Text(
                    'EMI Schedule',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${data.emiInstallments?.where((e) => e.status?.toLowerCase() != 'paid').length ?? 0} pending',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: Colors.grey,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
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
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.history,
                    color: Colors.purple,
                    size: 18,
                  ),
                ),
                title: const Text(
                  'Payment History',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${data.paymentTransactions?.length ?? 0} transactions',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                trailing: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.grey,
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
}
