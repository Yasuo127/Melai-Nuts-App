import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/melai_app_bar.dart';
import 'package:melai_nuts/data/catalog_store.dart';
import '../../../data/models/product.dart';

/// "Manage Variants" — one card per packaging tier with SKU, COGS/SRP,
/// a margin gauge, and stock on hand, matching the prototype's Product
/// Variants & Pricing screen.
class ProductVariantsScreen extends StatelessWidget {
  final String productId;

  const ProductVariantsScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final product = findProductById(productId);
    final combinedStock = product.variants.fold<int>(0, (sum, v) => sum + (v.stockOnHand ?? 0));
    final weightedMargin = product.variants.isEmpty
        ? 0.0
        : product.variants.map((v) => v.marginPercent).reduce((a, b) => a + b) / product.variants.length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: MelaiAppBar(
        title: 'Manage Variants',
        showBack: true,
        actions: [
          TextButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Simulated: new variant added.')),
            ),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add Variant'),
          ),
        ],
      ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: product.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                        child: Icon(product.icon, color: product.color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name, style: AppTextStyles.titleMd),
                            Text('Base SKU: ${product.sku} • ${product.variants.length} Active Weight Tiers', style: AppTextStyles.bodySm),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryStat(label: 'Combined Stock', value: '$combinedStock packs'),
                      ),
                      Expanded(
                        child: _SummaryStat(label: 'Weighted Margin', value: '${weightedMargin.toStringAsFixed(1)}%', valueColor: AppColors.success),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final variant in product.variants)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _VariantCard(
                  variant: variant,
                  onEditPricing: () => Navigator.of(context).pushNamed(AppRoutes.productPricing, arguments: product.id),
                ),
              ),
            OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Simulated: custom variant form opened.')),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Custom Variant (e.g. 1kg Catering Bag)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryStat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySm),
        Text(value, style: AppTextStyles.titleMd.copyWith(color: valueColor)),
      ],
    );
  }
}

class _VariantCard extends StatelessWidget {
  final ProductVariant variant;
  final VoidCallback onEditPricing;

  const _VariantCard({required this.variant, required this.onEditPricing});

  @override
  Widget build(BuildContext context) {
    final healthy = variant.marginPercent >= 55;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: variant.badge != null ? AppColors.primary : AppColors.border, width: variant.badge != null ? 1.4 : 1),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(variant.label, style: AppTextStyles.titleMd)),
              if (variant.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(20)),
                  child: Text(variant.badge!, style: AppTextStyles.labelSm.copyWith(color: AppColors.primaryDark)),
                ),
            ],
          ),
          Text('SKU: ${variant.sku ?? '—'}', style: AppTextStyles.bodySm),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEditPricing,
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Edit Pricing'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Simulated: ${variant.label} duplicated.')),
                  ),
                  icon: const Icon(Icons.copy_outlined, size: 14),
                  label: const Text('Duplicate'),
                ),
              ),
              IconButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Simulated: ${variant.label} removed.')),
                ),
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('COGS: ₱${(variant.costPrice ?? 0).toStringAsFixed(2)}', style: AppTextStyles.bodySm),
              Text('SRP: ₱${variant.price.toStringAsFixed(2)}', style: AppTextStyles.labelLg.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Margin Gauge', style: AppTextStyles.bodySm),
              Text(
                '${variant.marginPercent.toStringAsFixed(1)}% ${healthy ? 'Healthy' : 'Review'}',
                style: AppTextStyles.labelSm.copyWith(color: healthy ? AppColors.success : AppColors.warning),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (variant.marginPercent / 100).clamp(0, 1),
              minHeight: 6,
              backgroundColor: AppColors.border,
              color: healthy ? AppColors.success : AppColors.warning,
            ),
          ),
          const SizedBox(height: 6),
          Text('Net Profit: ₱${variant.netProfit.toStringAsFixed(2)} / pack', style: AppTextStyles.bodySm),
          if (variant.stockOnHand != null) ...[
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Stock on Hand', style: AppTextStyles.bodySm),
                Text('${variant.stockOnHand} packs', style: AppTextStyles.labelLg),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
