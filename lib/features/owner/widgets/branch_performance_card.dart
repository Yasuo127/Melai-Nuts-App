import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/sales_data.dart';

/// Summary card for one branch's performance — revenue, orders, stock
/// health, YoY growth, and top performer — with an optional rank badge.
/// Used on the Owner dashboard and Branch Comparison screen.
class BranchPerformanceCard extends StatelessWidget {
  final BranchSales sales;
  final int? rank;
  final VoidCallback onTap;

  const BranchPerformanceCard({
    super.key,
    required this.sales,
    required this.onTap,
    this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (rank != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(20)),
                    child: Text('Rank #$rank', style: AppTextStyles.labelSm.copyWith(color: AppColors.success)),
                  ),
                  const Spacer(),
                ] else
                  Expanded(child: Text(sales.branch, style: AppTextStyles.titleMd)),
                if (rank != null)
                  Text('₱${sales.todayRevenue.toStringAsFixed(0)}', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
              ],
            ),
            if (rank != null) ...[
              const SizedBox(height: 4),
              Text(sales.branch, style: AppTextStyles.titleMd),
            ],
            Row(
              children: [
                Icon(
                  sales.yoyGrowthPercent >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: 14,
                  color: sales.yoyGrowthPercent >= 0 ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  '${sales.yoyGrowthPercent >= 0 ? '+' : ''}${sales.yoyGrowthPercent.toStringAsFixed(1)}% YoY',
                  style: AppTextStyles.bodySm.copyWith(color: sales.yoyGrowthPercent >= 0 ? AppColors.success : AppColors.error),
                ),
                if (rank == null) ...[
                  const Spacer(),
                  Text('₱${sales.todayRevenue.toStringAsFixed(0)}', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _MiniStat(label: 'Orders', value: '${sales.ordersToday}', sub: 'Avg ₱${sales.avgOrderValue.toStringAsFixed(0)}')),
                Expanded(child: _MiniStat(label: 'Stock Health', value: '${sales.stockHealthPercent.toStringAsFixed(1)}%', sub: sales.stockHealthPercent >= 95 ? 'Optimal' : 'Watch')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('Top Performer: ', style: AppTextStyles.bodySm),
                Text(sales.topPerformer, style: AppTextStyles.labelMd),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String sub;

  const _MiniStat({required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySm),
        Text(value, style: AppTextStyles.labelLg),
        Text(sub, style: AppTextStyles.bodySm),
      ],
    );
  }
}
