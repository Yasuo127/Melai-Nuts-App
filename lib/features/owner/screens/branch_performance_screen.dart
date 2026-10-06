import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/melai_app_bar.dart';
import '../../../data/dummy_data/dummy_inventory.dart';
import 'package:melai_nuts/data/catalog_store.dart';
import '../../../data/dummy_data/dummy_sales.dart';
import '../../../data/models/inventory_batch.dart';
import '../widgets/sales_chart.dart';
import '../widgets/stat_card.dart';

/// Deep-dive into a single branch's performance — revenue trend, top
/// products stocked there, and current inventory/FEFO status.
class BranchPerformanceScreen extends StatelessWidget {
  final String branch;

  const BranchPerformanceScreen({super.key, required this.branch});

  @override
  Widget build(BuildContext context) {
    final sales = findBranchSales(branch);
    final batches = batchesForBranch(branch);
    final lowStock = batches.where((b) => b.isLowStock).length;
    final highPriority = batches.where((b) => b.fefoPriority == FefoPriority.high).length;
    final stockedProducts = batches.map((b) => b.productId).toSet().map(findProductById).toList()
      ..sort((a, b) => b.monthlyRevenue.compareTo(a.monthlyRevenue));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: MelaiAppBar(title: branch, showBack: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.border), boxShadow: AppShadows.sm),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: AppColors.roleOwner.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.storefront_rounded, color: AppColors.roleOwner),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Branch Lead: ${sales.topPerformer}', style: AppTextStyles.labelLg),
                        Text(sales.leadContact, style: AppTextStyles.bodySm),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Simulated: calling ${sales.leadContact}')),
                    ),
                    icon: const Icon(Icons.call_outlined, size: 16),
                    label: const Text('Call'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: [
                OwnerStatCard(label: "Today's Revenue", value: '₱${sales.todayRevenue.toStringAsFixed(0)}', icon: Icons.payments_outlined),
                OwnerStatCard(label: 'Orders Today', value: '${sales.ordersToday}', sub: 'Avg ₱${sales.avgOrderValue.toStringAsFixed(0)}', icon: Icons.receipt_long_outlined),
                OwnerStatCard(
                  label: 'YoY Growth',
                  value: '${sales.yoyGrowthPercent >= 0 ? '+' : ''}${sales.yoyGrowthPercent.toStringAsFixed(1)}%',
                  icon: Icons.trending_up_rounded,
                  valueColor: AppColors.success,
                ),
                OwnerStatCard(
                  label: 'Stock Health',
                  value: '${sales.stockHealthPercent.toStringAsFixed(1)}%',
                  icon: Icons.inventory_2_outlined,
                  valueColor: sales.stockHealthPercent >= 95 ? AppColors.success : AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Weekly Revenue Trend', style: AppTextStyles.headlineSm),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.border), boxShadow: AppShadows.sm),
              child: SalesBarChart(points: kWeeklyRevenueSeries),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Inventory & FEFO Status', style: AppTextStyles.headlineSm),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OwnerStatCard(
                    label: 'Low Stock',
                    value: '$lowStock SKUs',
                    icon: Icons.warning_amber_rounded,
                    highlight: lowStock > 0,
                    valueColor: lowStock > 0 ? AppColors.error : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OwnerStatCard(
                    label: 'Expiring Soon',
                    value: '$highPriority Batches',
                    icon: Icons.hourglass_bottom_rounded,
                    highlight: highPriority > 0,
                    valueColor: highPriority > 0 ? AppColors.error : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Top Products at This Branch', style: AppTextStyles.headlineSm),
            const SizedBox(height: AppSpacing.sm),
            for (final p in stockedProducts.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.border)),
                  child: Row(
                    children: [
                      Icon(p.icon, color: p.color, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(p.name, style: AppTextStyles.bodyMd, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Text('₱${p.price.toStringAsFixed(0)}', style: AppTextStyles.labelLg),
                    ],
                  ),
                ),
              ),
            if (stockedProducts.isEmpty)
              Text('No inventory batches recorded for this branch yet.', style: AppTextStyles.bodyMd),
          ],
        ),
      ),
    );
  }
}
