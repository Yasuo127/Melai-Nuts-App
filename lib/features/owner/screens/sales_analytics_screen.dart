import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/melai_app_bar.dart';
import 'package:melai_nuts/data/catalog_store.dart';
import '../../../data/dummy_data/dummy_sales.dart';
import '../../../data/models/product.dart';

/// Sales Analytics — revenue by category, payment method mix, and top
/// products by revenue. Complements Sales Overview/Trends/Forecast.
class SalesAnalyticsScreen extends StatelessWidget {
  const SalesAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = categoryRevenueBreakdown..sort((a, b) => b.revenue.compareTo(a.revenue));
    final totalRevenue = categories.fold<double>(0, (sum, c) => sum + c.revenue);
    final topProducts = List<Product>.from(kProducts)..sort((a, b) => b.monthlyRevenue.compareTo(a.monthlyRevenue));

    // Payment method mix — to be populated by real payment gateway data.
    const paymentMix = <({String label, double percent, Color color})>[];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const MelaiAppBar(title: 'Sales Analytics', showBack: true),
      body: SafeArea(
        child: kProducts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.analytics_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text('No sales analytics yet.', style: AppTextStyles.headlineSm.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Text('Data will appear once transactions are processed.', style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Text('Revenue by Category', style: AppTextStyles.headlineSm),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.border), boxShadow: AppShadows.sm),
                    child: Column(
                      children: [
                        for (final cat in categories)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(findCategoryById(cat.categoryId).icon, size: 14, color: findCategoryById(cat.categoryId).color),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(findCategoryById(cat.categoryId).name, style: AppTextStyles.bodyMd)),
                                    Text(
                                      '${totalRevenue == 0 ? 0 : (cat.revenue / totalRevenue * 100).toStringAsFixed(0)}%',
                                      style: AppTextStyles.labelLg,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: totalRevenue == 0 ? 0 : cat.revenue / totalRevenue,
                                    minHeight: 8,
                                    backgroundColor: AppColors.border,
                                    color: findCategoryById(cat.categoryId).color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Monthly Revenue', style: AppTextStyles.labelLg),
                            Text('₱${totalRevenue.toStringAsFixed(0)}', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Payment Method Mix', style: AppTextStyles.headlineSm),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.border), boxShadow: AppShadows.sm),
                    child: paymentMix.isEmpty
                        ? const SizedBox(height: 60, child: Center(child: Text('No payment data yet.')))
                        : Column(
                            children: [
                              for (final method in paymentMix)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Container(width: 10, height: 10, decoration: BoxDecoration(color: method.color, shape: BoxShape.circle)),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(method.label, style: AppTextStyles.bodyMd)),
                                      Text('${method.percent.toStringAsFixed(0)}%', style: AppTextStyles.labelLg),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Top Products by Revenue', style: AppTextStyles.headlineSm),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.ownerProductPerformance),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (topProducts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No products found.')),
                    )
                  else
                    for (final p in topProducts.take(5))
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
                              Text('₱${p.monthlyRevenue.toStringAsFixed(0)}', style: AppTextStyles.labelLg.copyWith(color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
      ),
    );
  }
}
