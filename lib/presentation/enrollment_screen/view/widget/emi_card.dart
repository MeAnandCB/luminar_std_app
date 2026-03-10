import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';

class EmiBreakdownCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final VoidCallback onConfirm;

  const EmiBreakdownCard({
    Key? key,
    required this.plan,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate EMI breakdown dates
    final now = DateTime.now();
    final installments = _generateInstallments(now, plan['months']);

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildScheduleTitle(),
          const SizedBox(height: 16),
          ...installments.asMap().entries.map(
            (entry) => _buildInstallmentRow(
              index: entry.key,
              date: entry.value,
              amount: entry.key == installments.length - 1
                  ? (plan['total']! -
                        (plan['monthly']! * (plan['months']! - 1)))
                  : plan['monthly']!,
              isLast: entry.key == installments.length - 1,
            ),
          ),
          const SizedBox(height: 20),
          _buildSummary(),
          const SizedBox(height: 24),
          _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.calendar_month_rounded,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EMI Payment Schedule',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '3 monthly installments',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleTitle() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Installment',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Due Date',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Amount',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentRow({
    required int index,
    required DateTime date,
    required double amount,
    required bool isLast,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        color: isLast
            ? AppColors.primary.withOpacity(0.02)
            : Colors.transparent,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isLast
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.statsBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isLast ? AppColors.primary : AppColors.statsBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    Text(
                      'Installment ${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isLast ? FontWeight.w600 : FontWeight.w500,
                        color: isLast
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(date),
                          style: TextStyle(
                            fontSize: 13,
                            color: isLast
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: isLast
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (index == 0)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.statsOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'First',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.statsOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (isLast)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.statsGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Last',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.statsGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Text(
              '₹${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: isLast ? FontWeight.w700 : FontWeight.w600,
                color: isLast ? AppColors.primary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final now = DateTime.now();
    final lastDate = now.add(
      Duration(days: 30 * ((plan['months'] as int) - 1)),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.primaryLight.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Total Amount',
                value: '₹${plan['total'].toStringAsFixed(0)}',
                color: AppColors.textPrimary,
              ),
              Container(height: 30, width: 1, color: AppColors.borderColor),
              _buildSummaryItem(
                icon: Icons.format_list_numbered_rounded,
                label: 'Installments',
                value: '${plan['months']}',
                color: AppColors.statsBlue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.borderColor, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                icon: Icons.event_available_rounded,
                label: 'First Payment',
                value: _formatDate(now),
                color: AppColors.statsOrange,
              ),
              Container(height: 30, width: 1, color: AppColors.borderColor),
              _buildSummaryItem(
                icon: Icons.event_busy_rounded,
                label: 'Last Payment',
                value: _formatDate(lastDate),
                color: AppColors.statsGreen,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calculate_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Monthly Average: ',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '₹${(plan['total']! / plan['months']!).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onConfirm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: AppColors.textWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 20),
            SizedBox(width: 8),
            Text(
              'Confirm EMI Plan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DateTime> _generateInstallments(DateTime startDate, int months) {
    List<DateTime> installments = [];
    for (int i = 0; i < months; i++) {
      installments.add(startDate.add(Duration(days: 30 * i)));
    }
    return installments;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
