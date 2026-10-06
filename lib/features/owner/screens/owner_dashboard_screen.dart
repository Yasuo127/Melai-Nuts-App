import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/dummy_data/dummy_inventory.dart';
import '../../../data/dummy_data/dummy_sales.dart';
import '../../../data/models/inventory_batch.dart';
import '../widgets/branch_performance_card.dart';
import '../widgets/sales_chart.dart';
import '../widgets/stat_card.dart';

/// Owner "Executive Command" dashboard — today's performance, FEFO/low
/// stock alerts, a 7-day sales trend, and per-branch operations, matching
/// the prototype's Owner Executive Dashboard.
class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  String _selectedBranch = 'All Branches';

  @override
  Widget build(BuildContext context) {
    final highPriorityBatches = batchesByPriority(FefoPriority.high);
    final totalInventoryUnits = kInventoryBatches.fold<int>(0, (sum, b) => sum + b.quantity);
    const dailyGoal = 65000.0;
    final goalProgress = (todaysGrossSales / dailyGoal).clamp(0, 1);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final label in ['All Branches', ...kInventoryBranches])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label == 'All Branches' ? 'All Branches (3)' : label.split(' ').first),
                      selected: _selectedBranch == label,
                      onSelected: (_) => setState(() => _selectedBranch = label),
                      selectedColor: AppColors.roleOwner.withValues(alpha: 0.15),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (highPriorityBatches.isNotEmpty)
            InkWell(
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.inventoryFefo, arguments: FefoPriority.high),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('FEFO Alert: Action Needed', style: AppTextStyles.labelLg.copyWith(color: AppColors.error)),
                          Text(
                            '${highPriorityBatches.length} batch${highPriorityBatches.length == 1 ? '' : 'es'} require markdown or dispatch transfer within 48 hrs.',
                            style: AppTextStyles.bodySm,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.error),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's Performance", style: AppTextStyles.headlineSm),
              if (todaysGrossSales > 0) Text('Updated just now', style: AppTextStyles.bodySm),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(16),
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
                    Text("TODAY'S GROSS SALES", style: AppTextStyles.labelSm),
                    const Spacer(),
                    if (todaysGrossSales > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(20)),
                        child: Text('↗ Tracking above avg', style: AppTextStyles.labelSm.copyWith(color: AppColors.success)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('₱${todaysGrossSales.toStringAsFixed(2)}', style: AppTextStyles.headlineLg.copyWith(color: AppColors.roleOwner)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: goalProgress.toDouble(), minHeight: 8, backgroundColor: AppColors.border, color: AppColors.primary),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${(goalProgress * 100).toStringAsFixed(1)}% achieved', style: AppTextStyles.bodySm),
                    Text('₱${(dailyGoal - todaysGrossSales).clamp(0, dailyGoal).toStringAsFixed(0)} to target', style: AppTextStyles.bodySm),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              OwnerStatCard(
                label: 'Orders Count',
                value: '$todaysOrderCount',
                sub: 'Completed Orders',
                icon: Icons.receipt_long_outlined,
                subColor: AppColors.success,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.ownerSalesOverview),
              ),
              OwnerStatCard(
                label: 'Total Inventory',
                value: '$totalInventoryUnits',
                sub: 'Packs in Stock',
                icon: Icons.inventory_2_outlined,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.inventoryDashboard),
              ),
              OwnerStatCard(
                label: 'Low-Stock Items',
                value: '${lowStockBatches.length} SKUs',
                sub: 'Reorder Required',
                icon: Icons.shopping_bag_outlined,
                valueColor: lowStockBatches.isEmpty ? null : AppColors.error,
                highlight: lowStockBatches.isNotEmpty,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.inventoryLowStock),
              ),
              OwnerStatCard(
                label: 'Expiring Products',
                value: '${highPriorityBatches.length} Batches',
                sub: 'FEFO Priority',
                icon: Icons.hourglass_bottom_rounded,
                valueColor: highPriorityBatches.isEmpty ? null : AppColors.error,
                highlight: highPriorityBatches.isNotEmpty,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.inventoryFefo, arguments: FefoPriority.high),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('7-Day Sales Trend', style: AppTextStyles.headlineSm),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.ownerSalesTrends),
                child: const Text('View Trends'),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.border), boxShadow: AppShadows.sm),
            child: kWeeklyRevenueSeries.isEmpty
                ? const SizedBox(
                    height: 200,
                    child: Center(child: Text('No sales data yet.')),
                  )
                : SalesBarChart(points: kWeeklyRevenueSeries),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Branch Operations', style: AppTextStyles.headlineSm),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.ownerBranchComparison),
                child: const Text('Compare All'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (kBranchSalesList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No branch performance data available.', style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted)),
              ),
            )
          else
            for (final sales in kBranchSalesList)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BranchPerformanceCard(
                  sales: sales,
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.ownerBranchPerformance, arguments: sales.branch),
                ),
              ),
          const SizedBox(height: AppSpacing.sm),
          Text('Quick Links', style: AppTextStyles.headlineSm),
          const SizedBox(height: AppSpacing.sm),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: [
              _QuickLink(icon: Icons.dashboard_customize_outlined, label: 'Business Overview', onTap: () => Navigator.of(context).pushNamed(AppRoutes.ownerBusinessOverview)),
              _QuickLink(icon: Icons.query_stats_rounded, label: 'Sales Analytics', onTap: () => Navigator.of(context).pushNamed(AppRoutes.ownerSalesAnalytics)),
              _QuickLink(icon: Icons.auto_graph_rounded, label: 'Sales Forecast', onTap: () => Navigator.of(context).pushNamed(AppRoutes.ownerSalesForecast)),
              _QuickLink(icon: Icons.leaderboard_outlined, label: 'Product Performance', onTap: () => Navigator.of(context).pushNamed(AppRoutes.ownerProductPerformance)),
              _QuickLink(icon: Icons.local_shipping_outlined, label: 'Delivery Management', onTap: () => Navigator.of(context).pushNamed(AppRoutes.deliveryDashboard)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLink({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.roleOwner, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: AppTextStyles.labelMd, maxLines: 2)),
          ],
        ),
      ),
    );
  }
}
