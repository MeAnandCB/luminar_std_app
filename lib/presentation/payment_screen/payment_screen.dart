// lib/main.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/home_screen/controller.dart';
import 'package:luminar_std/repository/payment_screen/model.dart';
import 'package:luminar_std/repository/payment_screen/service.dart';
import 'package:provider/provider.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<PaymentData> _paymentDataList = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, EnrollmentDetailResponse?> _enrollmentDetailsCache = {};

  @override
  void initState() {
    super.initState();
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

      await _fetchAllEnrollmentDetails();
      _processPaymentData();

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

  Future<void> _fetchAllEnrollmentDetails() async {
    final controller = Provider.of<DashboardController>(context, listen: false);
    final dashboardData = controller.dashboardModel?.dashboard;

    if (dashboardData == null) return;

    final enrollments = dashboardData.enrollmentDetails?.enrollments ?? [];
    if (enrollments.isEmpty) return;

    final accessKey = await AppUtils.getAccessKey();
    if (accessKey == null || accessKey.isEmpty) return;

    for (var enrollment in enrollments) {
      final enrollmentUid = enrollment.basicInfo?.uid;
      if (enrollmentUid != null && enrollmentUid.isNotEmpty) {
        try {
          final details = await PaymentScreenService.fetchEnrollmentDetails(
            enrollmentUid,
            accessKey,
          );
          if (details != null && mounted) {
            setState(() {
              _enrollmentDetailsCache[enrollmentUid] = details;
            });
          }
        } catch (e) {
          debugPrint('Error fetching details for $enrollmentUid: $e');
          continue;
        }
      }
    }
  }

  void _processPaymentData() {
    final controller = Provider.of<DashboardController>(context, listen: false);
    final dashboardData = controller.dashboardModel?.dashboard;

    if (dashboardData == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'No dashboard data available';
        });
      }
      return;
    }

    final enrollments = dashboardData.enrollmentDetails?.enrollments ?? [];

    if (enrollments.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = 'No enrollments found';
        });
      }
      return;
    }

    List<PaymentData> paymentDataList = [];

    for (var enrollment in enrollments) {
      final basicInfo = enrollment.basicInfo;
      final enrollmentUid = basicInfo?.uid ?? '';

      final detailedData = _enrollmentDetailsCache[enrollmentUid];

      if (detailedData != null) {
        final paymentData = _mapDetailedDataToPaymentData(detailedData);
        paymentDataList.add(paymentData);
      } else {}
    }

    if (mounted) {
      setState(() {
        _paymentDataList = paymentDataList;
        // Only create TabController if we have multiple enrollments
        if (paymentDataList.length > 1) {
          _tabController = TabController(
            length: paymentDataList.length,
            vsync: this,
          );
        } else {
          _tabController = null; // No tabs needed for single enrollment
        }
      });
    }
  }

  PaymentData _mapDetailedDataToPaymentData(EnrollmentDetailResponse data) {
    List<Transaction> transactions = [];
    if (data.paymentTransactions != null) {
      for (var txn in data.paymentTransactions!) {
        transactions.add(
          Transaction(
            id:
                txn.transactionId ??
                'TXN${DateTime.now().millisecondsSinceEpoch}',
            date: txn.paymentDate ?? DateTime.now(),
            method: txn.paymentMethodDisplay ?? txn.paymentMethod ?? 'Unknown',
            amount: txn.amount ?? 0,
            status: _mapTransactionStatus(txn.status),
          ),
        );
      }
    }

    List<EmiInstallment> emiSchedule = [];
    if (data.emiInstallments != null) {
      for (var emi in data.emiInstallments!) {
        if (emi.installmentNumber != null && emi.dueDate != null) {
          emiSchedule.add(
            EmiInstallment(
              number: emi.installmentNumber!,
              dueDate: emi.dueDate!,
              amount: emi.totalAmount ?? 0,
              status: _mapEmiStatus(emi.status, emi.isOverdue ?? false),
            ),
          );
        }
      }
    }

    emiSchedule.sort((a, b) => a.number.compareTo(b.number));

    DateTime nextDueDate = DateTime.now();
    double nextDueAmount = 0;

    final pendingEmis = emiSchedule
        .where((e) => e.status != EmiStatus.paid)
        .toList();
    if (pendingEmis.isNotEmpty) {
      nextDueDate = pendingEmis.first.dueDate;
      nextDueAmount = pendingEmis.first.amount;
    } else if (data.nextEmiDueDate != null) {
      nextDueDate = DateTime.tryParse(data.nextEmiDueDate!) ?? DateTime.now();
    }

    return PaymentData(
      enrollmentId: data.enrollmentNumber ?? 'N/A',
      enrollmentUid: data.uid ?? '',
      courseName: data.batch?.courseName ?? 'Unknown Course',
      batchName: data.batch?.batchName ?? 'Unknown Batch',
      totalFee: data.netFees ?? data.originalCourseFees ?? 0,
      paidAmount: data.totalAmountPaid ?? 0,
      remainingAmount: data.totalPendingAmount ?? 0,
      paymentType: data.paymentType?.toUpperCase() ?? 'N/A',
      nextDueAmount: nextDueAmount,
      nextDueDate: nextDueDate,
      progress: data.paymentCompletionPercentage ?? 0,
      transactions: transactions,
      emiSchedule: emiSchedule,
      isOverdue: data.isPaymentOverdue ?? false,
      studentName: data.studentName ?? '',
      studentId: data.studentId ?? '',
    );
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

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  if (!_isLoading)
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
        // Only show bottom bar if we have multiple enrollments
        bottom:
            _paymentDataList.length > 1 && !_isLoading && _tabController != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(70),
                child: _buildTabBar(),
              )
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildTabBar() {
    final tabController = _tabController!;

    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: TabBar(
        controller: tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.purple.withOpacity(0.1),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.purple,
        unselectedLabelColor: Colors.grey[500],
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.grey[500],
        ),
        isScrollable: true,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tabs: _paymentDataList.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          return Tab(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: tabController.index == index
                          ? Colors.purple
                          : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tabController.index == index
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getShortCourseName(data.courseName),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (data.remainingAmount > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: data.isOverdue ? Colors.red : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSingleEnrollmentHeader() {
    if (_paymentDataList.isEmpty) return const SizedBox.shrink();

    final data = _paymentDataList.first;
    return Container(
      height: 70,
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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.purple[50],
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.school, color: Colors.purple, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.courseName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  data.batchName,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (data.remainingAmount > 0)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: data.isOverdue ? Colors.red : Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabCountIndicator() {
    if (_tabController == null || _paymentDataList.length <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.grid_view, size: 14, color: Colors.purple[400]),
                const SizedBox(width: 4),
                Text(
                  '${_tabController!.index + 1}/${_paymentDataList.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getShortCourseName(String courseName) {
    if (courseName.length > 12) {
      return '${courseName.substring(0, 10)}...';
    }
    return courseName;
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
                  _tabController = null;
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

    if (_paymentDataList.isEmpty) {
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

    // For single enrollment - just show the content without tabs
    if (_paymentDataList.length == 1) {
      return Column(
        children: [
          _buildSingleEnrollmentHeader(),
          Expanded(child: _buildPaymentContent(_paymentDataList.first)),
        ],
      );
    }

    // For multiple enrollments - show tabs
    if (_tabController == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [_buildTabCountIndicator()],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController!,
            children: _paymentDataList.map((data) {
              return _buildPaymentContent(data);
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showEmiDetails(BuildContext context, EmiInstallment emi) {
    final dateFormat = DateFormat('d/M/yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: emi.status == EmiStatus.paid
                        ? Colors.green[50]
                        : emi.status == EmiStatus.overdue
                        ? Colors.red[50]
                        : Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${emi.number}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: emi.status == EmiStatus.paid
                            ? Colors.green[700]
                            : emi.status == EmiStatus.overdue
                            ? Colors.red[700]
                            : Colors.blue[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Installment ${emi.number}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: emi.status == EmiStatus.paid
                              ? Colors.green[50]
                              : emi.status == EmiStatus.overdue
                              ? Colors.red[50]
                              : Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          emi.status == EmiStatus.paid
                              ? 'Paid'
                              : emi.status == EmiStatus.overdue
                              ? 'Overdue'
                              : 'Pending',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: emi.status == EmiStatus.paid
                                ? Colors.green[700]
                                : emi.status == EmiStatus.overdue
                                ? Colors.red[700]
                                : Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailItem('Amount', currencyFormat.format(emi.amount)),
            _buildDetailItem('Due Date', dateFormat.format(emi.dueDate)),
            const SizedBox(height: 24),
            if (emi.status != EmiStatus.paid)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text('Later'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handlePayment(emi);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: emi.status == EmiStatus.overdue
                            ? Colors.red[600]
                            : Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Pay Now'),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handlePayment(EmiInstallment emi) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Processing payment of ₹${emi.amount.toStringAsFixed(0)}',
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

  Widget _buildAttractiveNextDueCard(PaymentData data) {
    final isOverdue = data.isOverdue;

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
                            data.paymentType,
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
                          '₹${NumberFormat('#,##0').format(data.nextDueAmount)}',
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
                              DateFormat(
                                'dd MMMM, yyyy',
                              ).format(data.nextDueDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

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
                          onTap: () {
                            if (data.emiSchedule.isNotEmpty) {
                              _handlePayment(data.emiSchedule.first);
                            }
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
                                  isOverdue ? 'Pay Now' : 'Pay Now',
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
    List<Transaction> transactions,
  ) {
    if (transactions.isEmpty) {
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
                    color: txn.status == TransactionStatus.completed
                        ? Colors.green[50]
                        : txn.status == TransactionStatus.failed
                        ? Colors.red[50]
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    txn.status == TransactionStatus.completed
                        ? Icons.check_circle
                        : txn.status == TransactionStatus.failed
                        ? Icons.cancel
                        : Icons.pending,
                    size: 16,
                    color: txn.status == TransactionStatus.completed
                        ? Colors.green[600]
                        : txn.status == TransactionStatus.failed
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
                        '${dateFormat.format(txn.date)} • ${txn.method}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(txn.amount),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: txn.status == TransactionStatus.completed
                            ? Colors.green[600]
                            : txn.status == TransactionStatus.failed
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
                        color: txn.status == TransactionStatus.completed
                            ? Colors.green[50]
                            : txn.status == TransactionStatus.failed
                            ? Colors.red[50]
                            : Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        txn.status == TransactionStatus.completed
                            ? 'Success'
                            : txn.status == TransactionStatus.failed
                            ? 'Failed'
                            : 'Pending',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: txn.status == TransactionStatus.completed
                              ? Colors.green[700]
                              : txn.status == TransactionStatus.failed
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
    List<EmiInstallment> schedule,
  ) {
    if (schedule.isEmpty) {
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

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: schedule.length,
      separatorBuilder: (_, __) => const Divider(height: 8),
      itemBuilder: (context, index) {
        final emi = schedule[index];
        return InkWell(
          onTap: () => _showEmiDetails(context, emi),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: emi.status == EmiStatus.overdue
                    ? Colors.red[100]!
                    : emi.status == EmiStatus.paid
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
                    color: emi.status == EmiStatus.paid
                        ? Colors.green[50]
                        : emi.status == EmiStatus.overdue
                        ? Colors.red[50]
                        : Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${emi.number}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: emi.status == EmiStatus.paid
                            ? Colors.green[700]
                            : emi.status == EmiStatus.overdue
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
                        'Installment ${emi.number}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Due: ${dateFormat.format(emi.dueDate)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(emi.amount),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: emi.status == EmiStatus.overdue
                            ? Colors.red[600]
                            : emi.status == EmiStatus.paid
                            ? Colors.green[600]
                            : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (emi.status != EmiStatus.paid)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (emi.status == EmiStatus.overdue)
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
                          if (emi.status == EmiStatus.pending)
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

  Widget _buildPaymentContent(PaymentData data) {
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
                            data.courseName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.batchName,
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
                        color: data.isOverdue
                            ? Colors.red[50]
                            : Colors.green[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        data.isOverdue ? 'Overdue' : 'Active',
                        style: TextStyle(
                          fontSize: 11,
                          color: data.isOverdue
                              ? Colors.red[700]
                              : Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (data.studentName.isNotEmpty) ...[
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
                        data.studentName,
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
                        data.studentId,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatCard(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Total Fee',
                  value: '₹${NumberFormat('#,##0').format(data.totalFee)}',
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.check_circle_outline,
                  label: 'Paid',
                  value: '₹${NumberFormat('#,##0').format(data.paidAmount)}',
                  color: Colors.green,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.pending_outlined,
                  label: 'Remaining',
                  value:
                      '₹${NumberFormat('#,##0').format(data.remainingAmount)}',
                  color: Colors.orange,
                ),
              ],
            ),
          ),

          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          //   child: Container(
          //     padding: EdgeInsets.all(10),
          //     decoration: BoxDecoration(
          //       borderRadius: BorderRadius.circular(10),
          //       color: Colors.green,
          //     ),
          //     child: Column(
          //       children: [
          //         Text(
          //           'Total Discount',
          //           style: TextStyle(color: Colors.white, fontSize: 12),
          //         ),
          //         Text(
          //           '₹${NumberFormat('#,##0').format(data.)}',
          //           style: TextStyle(
          //             color: Colors.white,
          //             fontSize: 18,
          //             fontWeight: FontWeight.bold,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          _buildAttractiveNextDueCard(data),

          const SizedBox(height: 16),

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
                        '${data.progress.toStringAsFixed(1)}%',
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
                    value: (data.progress / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[100],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      data.isOverdue ? Colors.red : Colors.blue,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${NumberFormat('#,##0').format(data.paidAmount)} of ₹${NumberFormat('#,##0').format(data.totalFee)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
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
                  '${data.transactions.length} transactions',
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
                    child: _buildPaymentHistoryList(context, data.transactions),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (data.paymentType.toLowerCase().contains('emi'))
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
                    '${data.emiSchedule.where((e) => e.status != EmiStatus.paid).length} pending',
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
                      child: _buildEmiScheduleList(context, data.emiSchedule),
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
