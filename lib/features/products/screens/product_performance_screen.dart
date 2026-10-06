import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/melai_app_bar.dart';
import '../../../core/widgets/primary_button.dart';
import 'package:melai_nuts/data/catalog_store.dart';
import '../../../data/models/product.dart';

/// "Product Performance" ranking — consolidated stats + products ranked by
/// revenue (or units/margin), matching the prototype's Performance Ranking
/// screen.
class ProductPerformanceScreen extends StatefulWidget {
  const ProductPerformanceScreen({super.key});

  @override
  State<ProductPerformanceScreen> createState() => _ProductPerformanceScreenState();
}

enum _SortBy { revenue, units, margin }

class _ProductPerformanceScreenState extends State<ProductPerformanceScreen> {
  String? _categoryFilter;
  _SortBy _sortBy = _SortBy.revenue;

  @override
  Widget build(BuildContext context) {
    var products = _categoryFilter == null ? List<Product>.from(kProducts) : productsByCategory(_categoryFilter!);
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
    final totalUnits = kProducts.fold<int>(0, (sum, p) => sum + p.unitsSoldLast30Days);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const MelaiAppBar(title: 'Product Performance', showBack: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.sm,
              ),
              child: Row(
                children: [
                  Expanded(child: _StatColumn(label: 'Core Lines', value: '${kProducts.length} SKUs')),
                  Expanded(child: _StatColumn(label: 'Total Revenue', value: '₱${totalRevenue.toStringAsFixed(0)}')),
                  Expanded(child: _StatColumn(label: 'Units Sold', value: '$totalUnits')),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('All SKUs (${kProducts.length})'),
                      selected: _categoryFilter == null,
                      onSelected: (_) => setState(() => _categoryFilter = null),
                    ),
                  ),
                  for (final cat in kProductCategories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat.name),
                        selected: _categoryFilter == cat.id,
                        onSelected: (_) => setState(() => _categoryFilter = cat.id),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
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
                child: _RankCard(rank: i + 1, product: products[i]),
              ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'View Demand Forecast by Product',
              icon: Icons.query_stats_rounded,
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Demand forecast is part of a future batch.')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

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

  const _RankCard({required this.rank, required this.product});

  @override
  Widget build(BuildContext context) {
    final category = findCategoryById(product.categoryId);
    return Container(
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
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rank <= 3 ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: Text('#$rank', style: AppTextStyles.labelLg.copyWith(color: AppColors.primaryDark)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: AppTextStyles.labelLg, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${category.name} • Retail ₱${product.price.toStringAsFixed(0)} • Margin ${product.marginPercent.toStringAsFixed(0)}%', style: AppTextStyles.bodySm),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniStat(label: 'Gross Revenue', value: '₱${product.monthlyRevenue.toStringAsFixed(0)}'),
              ),
              Expanded(
                child: _MiniStat(label: 'Units Sold', value: '${product.unitsSoldLast30Days} units'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (product.marginPercent / 100).clamp(0, 1),
              minHeight: 5,
              backgroundColor: AppColors.border,
              color: category.color,
            ),
          ),
        ],
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
