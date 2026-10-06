import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/melai_app_bar.dart';
import 'package:melai_nuts/data/catalog_store.dart';
import '../../../data/models/product.dart';

/// Owner-facing, company-wide Product Performance ranking — cross-branch
/// revenue/units/margin view for executive decision-making.
///
/// Named [OwnerProductPerformanceScreen] (rather than
/// `ProductPerformanceScreen`) because the Product Management feature
/// (lib/features/products/) already has its own class with that name;
/// this avoids an ambiguous-import collision in routes.dart.
class OwnerProductPerformanceScreen extends StatefulWidget {
  const OwnerProductPerformanceScreen({super.key});

  @override
  State<OwnerProductPerformanceScreen> createState() => _OwnerProductPerformanceScreenState();
}

enum _SortBy { revenue, units, margin }

class _OwnerProductPerformanceScreenState extends State<OwnerProductPerformanceScreen> {
  _SortBy _sortBy = _SortBy.revenue;

  @override
  Widget build(BuildContext context) {
    final products = List<Product>.from(kProducts);
    switch (_sortBy) {
      case _SortBy.revenue:
        products.sort((a, b) => b.monthlyRevenue.compareTo(a.monthlyRevenue));
        break;
      case _SortBy.units:
        products.sort((a, b) => b.unitsSoldLast30Days.compareTo(a.unitsSoldLast30Days));
        break;
      case _SortBy.margin:
        products.sort((a, b) => b.marginPercent.compareTo(a.marginPercent));
        break;
    }

    final totalRevenue = kProducts.fold<double>(0, (sum, p) => sum + p.monthlyRevenue);
    final topTwo = products.take(2).toList();
    final crossSellShare = totalRevenue == 0
        ? 0.0
        : topTwo.fold<double>(0, (sum, p) => sum + p.monthlyRevenue) / totalRevenue * 100;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: MelaiAppBar(
        title: 'Product Performance',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sell_outlined),
            tooltip: 'Product & Pricing Hub',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.productManagement),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.border), boxShadow: AppShadows.sm),
              child: Row(
                children: [
                  Expanded(child: _Stat(label: 'Core Lines', value: '${kProducts.length} SKUs')),
                  Expanded(child: _Stat(label: 'Total Revenue', value: '₱${totalRevenue.toStringAsFixed(0)}')),
                  Expanded(child: _Stat(label: 'Active', value: '${kProducts.where((p) => p.isActive).length}/${kProducts.length}')),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ranked by:', style: AppTextStyles.bodySm),
                DropdownButton<_SortBy>(
                  value: _sortBy,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: _SortBy.revenue, child: Text('Revenue (Highest First)')),
                    DropdownMenuItem(value: _SortBy.units, child: Text('Units Sold')),
                    DropdownMenuItem(value: _SortBy.margin, child: Text('Margin %')),
                  ],
                  onChanged: (v) => setState(() => _sortBy = v ?? _sortBy),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (int i = 0; i < products.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RankCard(
                  rank: i + 1,
                  product: products[i],
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.productDetails, arguments: products[i].id),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            if (products.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.primaryContainer.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.link_rounded, color: AppColors.primaryDark),
                        const SizedBox(width: 8),
                        Text('Cross-Selling & Profit Driver', style: AppTextStyles.titleMd),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Builder(
                      builder: (context) {
                        final names = topTwo.map((p) => p.name.split('(').first.trim()).join(' + ');
                        return Text(
                          '$names generate ${crossSellShare.toStringAsFixed(1)}% of gross retail profits across all branches.',
                          style: AppTextStyles.bodyMd,
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySm),
        Text(value, style: AppTextStyles.titleMd),
      ],
    );
  }
}

class _RankCard extends StatelessWidget {
  final int rank;
  final Product product;
  final VoidCallback onTap;

  const _RankCard({required this.rank, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final category = findCategoryById(product.categoryId);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.border), boxShadow: AppShadows.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: rank <= 3 ? AppColors.primaryContainer : AppColors.surfaceContainerLow, shape: BoxShape.circle),
                  child: Text('#$rank', style: AppTextStyles.labelLg.copyWith(color: AppColors.primaryDark)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: AppTextStyles.labelLg, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${category.name} • Margin ${product.marginPercent.toStringAsFixed(0)}%', style: AppTextStyles.bodySm),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _MiniStat(label: 'Gross Revenue', value: '₱${product.monthlyRevenue.toStringAsFixed(0)}')),
                Expanded(child: _MiniStat(label: 'Units Sold', value: '${product.unitsSoldLast30Days}')),
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

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySm),
        Text(value, style: AppTextStyles.labelLg),
      ],
    );
  }
}
