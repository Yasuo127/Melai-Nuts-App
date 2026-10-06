import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/melai_app_bar.dart';
import 'package:melai_nuts/data/catalog_store.dart';
import '../../../data/dummy_data/dummy_sales.dart';
import '../widgets/stat_card.dart';

/// "All Branches" business overview — consolidated revenue/orders/margin
/// across the whole Laguna network, plus category revenue breakdown.
class BusinessOverviewScreen extends StatelessWidget {
  const BusinessOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final avgMargin = kProducts.isEmpty
        ? 0.0
        : kProducts.map((p) => p.marginPercent).reduce((a, b) => a + b) / kProducts.length;
    final categories = categoryRevenueBreakdown..sort((a, b) => b.revenue.compareTo(a.revenue));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const MelaiAppBar(title: 'Business Overview', showBack: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text('Laguna Branch Network', style: AppTextStyles.bodySm),
            const SizedBox(height: AppSpacing.sm),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: [
                OwnerStatCard(label: 'Month Revenue', value: '₱${monthGrossSales.toStringAsFixed(0)}', icon: Icons.payments_outlined),
                OwnerStatCard(label: 'Week Revenue', value: '₱${weekGrossSales.toStringAsFixed(0)}', icon: Icons.calendar_view_week_rounded),
                OwnerStatCard(label: 'Orders (Week)', value: '$weekOrderCount', icon: Icons.receipt_long_outlined),
                OwnerStatCard(label: 'Average Margin', value: '${avgMargin.toStringAsFixed(1)}%', icon: Icons.trending_up_rounded, valueColor: AppColors.success),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Branch Breakdown', style: AppTextStyles.headlineSm),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.border)),
              child: Column(
                children: [
                  for (final b in kBranchSalesList) ...[
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b.branch, style: AppTextStyles.labelLg),
                                Text('${b.ordersWeek} orders this week', style: AppTextStyles.bodySm),
                              ],
                            ),
                          ),
                          Text('₱${b.weekRevenue.toStringAsFixed(0)}', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
                        ],
                      ),
                    ),
                    if (b != kBranchSalesList.last) const Divider(height: 1),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Category Revenue & Margin', style: AppTextStyles.headlineSm),
            const SizedBox(height: AppSpacing.sm),
            for (final cat in categories)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CategoryRow(categoryId: cat.categoryId, revenue: cat.revenue, marginPercent: cat.marginPercent),
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.ownerBranchComparison),
                    icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                    label: const Text('Compare Branches'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.productManagement),
                    icon: const Icon(Icons.sell_outlined, size: 16),
                    label: const Text('Pricing Hub'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String categoryId;
  final double revenue;
  final double marginPercent;

  const _CategoryRow({required this.categoryId, required this.revenue, required this.marginPercent});

  @override
  Widget build(BuildContext context) {
    final category = findCategoryById(categoryId);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.border), boxShadow: AppShadows.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(category.icon, size: 18, color: category.color),
              const SizedBox(width: 8),
              Expanded(child: Text(category.name, style: AppTextStyles.labelLg)),
              Text('Margin ${marginPercent.toStringAsFixed(1)}%', style: AppTextStyles.labelLg.copyWith(color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Monthly Rev. ₱${revenue.toStringAsFixed(0)}', style: AppTextStyles.bodySm),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: (marginPercent / 100).clamp(0, 1), minHeight: 6, backgroundColor: AppColors.border, color: category.color),
          ),
        ],
      ),
    );
  }
}
