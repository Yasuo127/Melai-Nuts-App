import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/product.dart';

/// Product "photo" tile: the real uploaded product image when one exists,
/// otherwise an on-brand gradient placeholder with the product's icon —
/// never a fake/stock photo standing in for a real product picture.
class ProductThumbnail extends StatelessWidget {
  final Product product;
  final double size;
  final BorderRadius? borderRadius;

  const ProductThumbnail({
    super.key,
    required this.product,
    this.size = 84,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(14);
    if (product.images.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          product.images.first,
          width: size,
          height: size,
          fit: BoxFit.cover,
          // A broken/expired image URL falls back to the placeholder
          // instead of Flutter's default error icon.
          errorBuilder: (context, error, stackTrace) => _placeholder(radius),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _placeholder(radius);
          },
        ),
      );
    }
    return _placeholder(radius);
  }

  Widget _placeholder(BorderRadius radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            product.color.withValues(alpha: 0.20),
            product.color.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Icon(product.icon, color: product.color, size: size * 0.42),
    );
  }
}

/// Standard product grid/list card: thumbnail, name, rating, price, and an
/// Add button. Used on the Home, Catalog, Category, and Search screens.
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final int quantityInCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAdd,
    this.quantityInCart = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.sm,
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // Fixed-height image container to avoid infinite height constraints
                // in unconstrained parents like Columns or ListViews.
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: ProductThumbnail(
                    product: product,
                    size: double.infinity,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                if (product.badge != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.darkBrown,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product.badge!,
                        style: AppTextStyles.labelSm.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                // Real stock/availability state — only shown when it isn't
                // the default "In Stock" (nothing to flag there).
                if (product.isOutOfStock || product.isLowStock)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: product.stockLabelBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product.stockLabel,
                        style: AppTextStyles.labelSm.copyWith(color: product.stockLabelColor),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelLg,
            ),
            // Only shown once real reviews exist — a "0.0 (0)" rating on
            // every card would look like fabricated star ratings.
            if (product.reviewCount > 0) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                  const SizedBox(width: 2),
                  Text(
                    '${product.rating.toStringAsFixed(1)} (${product.reviewCount})',
                    style: AppTextStyles.bodySm,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₱${product.price.toStringAsFixed(0)}',
                        style: AppTextStyles.titleMd.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      if (product.originalPrice != null)
                        Text(
                          '₱${product.originalPrice!.toStringAsFixed(0)}',
                          style: AppTextStyles.bodySm.copyWith(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ),
                _AddButton(
                  quantity: quantityInCart,
                  onAdd: product.isOutOfStock ? null : onAdd,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final int quantity;

  /// Null means this product can't be added right now (out of stock).
  final VoidCallback? onAdd;

  const _AddButton({required this.quantity, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    if (onAdd == null && quantity == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.errorBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('Unavailable', style: AppTextStyles.labelSm.copyWith(color: AppColors.error)),
      );
    }
    if (quantity > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'In cart · $quantity',
          style: AppTextStyles.labelSm.copyWith(color: AppColors.primaryDark),
        ),
      );
    }
    return SizedBox(
      height: 32,
      child: ElevatedButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded, size: 16),
        label: const Text('Add'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          textStyle: AppTextStyles.labelSm.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
