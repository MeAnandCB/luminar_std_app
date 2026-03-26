import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';

class PaymentTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String wasnow;
  final String amount;
  final bool isSelected;
  final VoidCallback onTap;
  final String? discount;
  final bool showOriginalPrice;
  final bool isFullpayment;

  const PaymentTile({
    Key? key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isSelected,
    required this.wasnow,
    required this.onTap,
    required this.isFullpayment,
    this.discount,
    this.showOriginalPrice = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cardBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: isFullpayment == true
            ? Row(
                children: [
                  _buildIcon(),
                  const SizedBox(width: 16),
                  Expanded(child: _buildContent()),
                  const SizedBox(width: 10),
                  _buildAmountAndSelection(),
                ],
              )
            : Column(
                children: [
                  Row(
                    children: [
                      _buildIcon(),
                      const SizedBox(width: 16),
                      Expanded(child: _buildContent()),
                      const SizedBox(width: 10),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [_buildAmountAndSelection()],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? iconColor.withOpacity(0.1)
            : AppColors.avatarBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        color: isSelected ? iconColor : AppColors.textHint,
        size: 24,
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? AppColors.textSecondary : AppColors.textHint,
          ),
        ),
        if (discount != null && isSelected) _buildDiscount(),
      ],
    );
  }

  Widget _buildDiscount() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.statsGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        discount!,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.statsGreen,
        ),
      ),
    );
  }

  Widget _buildAmountAndSelection() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? AppColors.statsGreen
                    : AppColors.textSecondary,
              ),
            ),
            if (showOriginalPrice && isSelected)
              Text(
                'was ₹28,000',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
          ],
        ),
        if (isSelected) _buildSelectedIndicator(),
      ],
    );
  }

  Widget _buildSelectedIndicator() {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_rounded,
        color: AppColors.textWhite,
        size: 16,
      ),
    );
  }
}
