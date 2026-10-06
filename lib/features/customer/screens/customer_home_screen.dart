import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/services/branch_controller.dart';
import '../../../core/services/customer_data_store.dart';
import 'package:melai_nuts/data/catalog_store.dart';
import '../../../data/models/notification_item.dart';
import '../../../data/models/order.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/products_repository.dart';
import '../../settings/screens/branch_settings_screen.dart';
import '../cart_controller.dart';
import '../widgets/category_chip.dart';
import '../widgets/order_status_badge.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';
import 'order_tracking_screen.dart';
import 'product_catalog_screen.dart';
import 'product_categories_screen.dart';
import 'product_details_screen.dart';
import 'search_results_screen.dart';

/// "Store Home" — branch selector, search, featured promos, categories,
/// and popular products (matches the prototype's Customer Home screen).
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  /// null = "All". Otherwise a real `product_categories.id` from Supabase.
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    // Catalog is preloaded at app boot; only re-fetch here if that hasn't
    // succeeded yet (e.g. cold start was offline). Loading / error / retry
    // state is read from ProductsRepository in build().
    final catalog = ProductsRepository.instance;
    if (!catalog.hasLoaded && !catalog.isLoading) _retryCatalog();
  }

  Future<void> _retryCatalog() => ProductsRepository.instance.loadCatalog(
        branchId: BranchController.instance.selectedBranch?.id,
      );

  /// The dashboard's "Popular Near You" strip, ranked by real sales
  /// ([kPopularProducts]; falls further back inside the repository), then
  /// narrowed to the selected category chip, if any.
  List<Product> get _visiblePopularProducts {
    final source = kPopularProducts.isNotEmpty ? kPopularProducts : kProducts;
    final categoryId = _selectedCategoryId;
    if (categoryId == null) return source.take(8).toList();
    return source.where((p) => p.categoryId == categoryId).take(8).toList();
  }

  /// Staff/owner-curated picks (`products.is_featured`), shown as their own
  /// row regardless of real sales ranking — distinct from "Popular Near
  /// You" so a featured product doesn't disappear once real sales exist
  /// (see `ProductsRepository._loadPopularProducts`'s fallback logic).
  List<Product> get _featuredProducts => kProducts.where((p) => p.isFeatured).take(8).toList();

  /// Orders that are placed but not yet completed/cancelled.
  List<Order> get _activeOrders =>
      CustomerDataStore.instance.orders.where((o) => o.status.isActive).toList()..sort((a, b) => b.date.compareTo(a.date));

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        CustomerDataStore.instance,
        ProductsRepository.instance,
      ]),
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final store = CustomerDataStore.instance;
    final firstName = (store.profile?.fullName ?? '').trim().split(' ').first;
    final greeting = firstName.isEmpty ? 'Mabuhay!' : 'Mabuhay, $firstName!';
    final unreadCount = CustomerDataStore.instance.notifications.where((n) => !n.read).length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MELAI NUTS LAGUNA', style: AppTextStyles.labelSm.copyWith(color: AppColors.primary)),
            Text(greeting, style: AppTextStyles.headlineSm),
          ],
        ),
        actions: [
          ListenableBuilder(
            listenable: CartController.instance,
            builder: (context, _) => Badge(
              label: Text(CartController.instance.itemCount.toString()),
              isLabelVisible: CartController.instance.itemCount > 0,
              child: IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
              ),
            ),
          ),
          Badge(
            label: Text(unreadCount.toString()),
            isLabelVisible: unreadCount > 0,
            child: IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.notificationCenter),
            ),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            children: [
              ListenableBuilder(
                listenable: BranchController.instance,
                builder: (context, _) {
                  final branch = BranchController.instance.selectedBranch;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              branch != null ? branch.name : 'No branch selected',
                              style: AppTextStyles.titleMd,
                            ),
                            Text(
                              branch != null ? branch.address : 'Select a branch to see inventory',
                              style: AppTextStyles.bodySm,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BranchSettingsScreen()),
                        ),
                        child: const Text('Change'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                onSubmitted: (q) => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SearchResultsScreen(query: q)),
                ),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search for garlic, spicy, or sweet...',
                ),
              ),
              // Loading indicator while the catalog or the customer's records
              // are being fetched, so the screen never looks silently blank.
              if (store.isLoading || ProductsRepository.instance.isLoading) ...[
                const SizedBox(height: AppSpacing.xs),
                const LinearProgressIndicator(minHeight: 2),
              ],
              // Customer records (orders / notifications / points) failed to
              // load: say so, with a retry, instead of hiding the sections.
              if (store.error != null && !store.isLoading) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: StateErrorView(
                    compact: true,
                    error: store.error,
                    message: 'We couldn\'t load your orders and notifications.',
                    onRetry: () => store.retry(),
                  ),
                ),
              ],
              // Active Orders — real, from `orders`/`order_status_events`.
              // Hidden entirely when there's nothing in progress.
              if (_activeOrders.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text('Active Orders', style: AppTextStyles.titleMd),
                const SizedBox(height: AppSpacing.xs),
                for (final order in _activeOrders) ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadows.sm,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_shipping_outlined, color: AppColors.darkBrown),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order #${(order.id.length >= 8 ? order.id.substring(0, 8) : order.id).toUpperCase()}',
                                  style: AppTextStyles.labelLg,
                                ),
                                Text(
                                  '${order.itemCount} item${order.itemCount == 1 ? '' : 's'} • ₱${order.total.toStringAsFixed(0)}',
                                  style: AppTextStyles.bodySm,
                                ),
                              ],
                            ),
                          ),
                          OrderStatusBadge(status: order.status),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
              // Most recent notification — real, from `notifications`.
              // Hidden when the customer has none at all.
              if (CustomerDataStore.instance.notifications.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Builder(builder: (context) {
                  final latest = CustomerDataStore.instance.notifications.first;
                  return InkWell(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.notificationCenter),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: latest.read ? Colors.white : AppColors.primaryContainer.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(latest.category.icon, color: latest.category.color),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(latest.title, style: AppTextStyles.labelLg, maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text(latest.body, style: AppTextStyles.bodySm, maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Text(_relativeTime(latest.time), style: AppTextStyles.bodySm),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              // Promo banner(s) — real, staff-managed rows from
              // `promotions`. No section at all when there isn't a current
              // one, rather than a made-up offer.
              if (kPromotions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: kPromotions.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final promo = kPromotions[index];
                      return Container(
                        width: MediaQuery.of(context).size.width - (AppSpacing.md * 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, AppColors.secondaryBrown],
                          ),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          boxShadow: AppShadows.md,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  promo.badgeLabel,
                                  style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                promo.title,
                                style: AppTextStyles.headlineMd.copyWith(color: Colors.white),
                              ),
                              if (promo.subtitle.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  promo.subtitle,
                                  style: AppTextStyles.bodySm.copyWith(color: Colors.white),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              // Category Picker — real categories from `product_categories`.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Categories', style: AppTextStyles.titleMd),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProductCategoriesScreen()),
                    ),
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    CategoryChip(
                      label: 'All',
                      selected: _selectedCategoryId == null,
                      onTap: () => setState(() => _selectedCategoryId = null),
                    ),
                    for (final category in kProductCategories) ...[
                      const SizedBox(width: 8),
                      CategoryChip(
                        label: category.name,
                        selected: _selectedCategoryId == category.id,
                        onTap: () => setState(() => _selectedCategoryId = category.id),
                      ),
                    ],
                  ],
                ),
              ),
              // Featured Section — staff/owner-curated picks
              // (`products.is_featured`), always shown when any exist,
              // independent of the sales-ranked "Popular" row below.
              if (_featuredProducts.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Featured for You', style: AppTextStyles.headlineSm),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 280,
                  child: ListenableBuilder(
                    listenable: Listenable.merge([CartController.instance, BranchController.instance]),
                    builder: (context, _) {
                      final cart = CartController.instance;
                      final featured = _featuredProducts;
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: featured.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final product = featured[index];
                          final defaultVariant = product.variants.first;
                          return ProductCard(
                            product: product,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
                            ),
                            onAdd: () => addToCartWithFeedback(context, product, defaultVariant),
                            quantityInCart: cart.quantityFor(product.id, defaultVariant.label),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              // Popular Section — ranked by real units sold (falls back to
              // staff-featured, then newest, only if nothing's sold yet).
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Popular Near You', style: AppTextStyles.headlineSm),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProductCatalogScreen()),
                    ),
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 280,
                child: ListenableBuilder(
                  // Rebuilds when the cart changes (quantity badges) AND
                  // when the selected branch changes (stock/availability,
                  // since BranchController re-scopes kProducts/kPopularProducts).
                  listenable: Listenable.merge([CartController.instance, BranchController.instance]),
                  builder: (context, _) {
                    final cart = CartController.instance;
                    final popular = _visiblePopularProducts;
                    if (popular.isEmpty) {
                      final catalog = ProductsRepository.instance;
                      return DataStateView(
                        compact: true,
                        isLoading: catalog.isLoading,
                        error: catalog.error,
                        isEmpty: true,
                        onRetry: _retryCatalog,
                        errorScope: ErrorScope.catalog,
                        emptyIcon: Icons.inventory_2_outlined,
                        emptyTitle: _selectedCategoryId == null
                            ? 'No products available yet.'
                            : 'No products in this category yet.',
                        loadingMessage: 'Loading products...',
                        builder: (_) => const SizedBox.shrink(),
                      );
                    }
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: popular.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final product = popular[index];
                        final defaultVariant = product.variants.first;
                        return ProductCard(
                          product: product,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
                          ),
                          onAdd: () => addToCartWithFeedback(context, product, defaultVariant),
                          quantityInCart: cart.quantityFor(product.id, defaultVariant.label),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // RFID Rewards Teaser
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  boxShadow: AppShadows.sm,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Golden Kernel Rewards', style: AppTextStyles.labelLg),
                          Text(
                            '${store.pointsBalance} pts available',
                            style: AppTextStyles.bodySm,
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.customerLoyaltyDashboard),
                      child: const Text('View'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
