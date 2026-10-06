import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_error.dart';
import '../../../data/catalog_store.dart';
import '../../../data/models/branch.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/orders_repository.dart';
import 'order_details_screen.dart';

/// Live order tracking — ETA banner, real order timeline, and rider info.
/// Everything shown comes from Supabase and updates live via realtime. There
/// is no GPS feed in the backend, so no map is drawn rather than showing a
/// made-up van position.
class OrderTrackingScreen extends StatefulWidget {
  final Order order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late Order _order;
  Stream<List<Map<String, dynamic>>>? _stream;
  bool _refetching = false;

  /// Friendly message shown in a banner when the last refresh failed.
  String? _refreshError;

  /// The live status we last failed to load. Prevents a rebuild from firing
  /// the same failing request over and over; a new status or the Retry
  /// button tries again.
  String? _failedForStatus;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _stream = OrdersRepository.instance.watchOrder(_order.id);
  }

  Future<void> _refetch({String? liveStatus}) async {
    if (_refetching) return;
    _refetching = true;
    try {
      final updated = await OrdersRepository.instance.refetch(_order.id);
      if (!mounted) return;
      setState(() {
        _order = updated;
        _refreshError = null;
        _failedForStatus = null;
      });
    } catch (e) {
      // Keep showing the last known order and say so, instead of silently
      // showing a stale status as if it were current.
      if (!mounted) return;
      setState(() {
        _refreshError = AppErrors.from(e, scope: ErrorScope.order).message;
        _failedForStatus = liveStatus;
      });
    } finally {
      _refetching = false;
    }
  }

  double _progressFor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 0.1;
      case OrderStatus.confirmed:
        return 0.3;
      case OrderStatus.preparing:
        return 0.55;
      case OrderStatus.readyForPickup:
        return 0.85;
      case OrderStatus.outForDelivery:
        return 0.85;
      case OrderStatus.completed:
        return 1.0;
      case OrderStatus.cancelled:
        return 0.0;
      case OrderStatus.refundRequested:
        return 1.0;
      case OrderStatus.refunded:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final rows = snapshot.data!;
          if (rows.isNotEmpty) {
            final live = rows.first['status'] as String?;
            if (live != null && live != _order.status.name && live != _failedForStatus && !_refetching) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _refetch(liveStatus: live));
            }
          }
        }
        final streamError = snapshot.hasError
            ? 'Live updates are paused. ${AppErrors.from(snapshot.error!, scope: ErrorScope.order).message}'
            : null;
        return _buildScaffold(context, notice: streamError ?? _refreshError);
      },
    );
  }

  Branch? _branchForOrder() {
    for (final b in kBranches) {
      if (b.name == _order.branch) return b;
    }
    return null;
  }

  /// Shows the real contact details of the branch fulfilling this order.
  void _showBranchContact(BuildContext context) {
    final branch = _branchForOrder();
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Need help with ${_order.id}?', style: AppTextStyles.titleMd),
              const SizedBox(height: 8),
              if (branch == null)
                Text('Contact details for ${_order.branch} are not available right now.',
                    style: AppTextStyles.bodyMd)
              else ...[
                Text(branch.name, style: AppTextStyles.labelLg),
                if (branch.address.isNotEmpty) Text(branch.address, style: AppTextStyles.bodyMd),
                if (branch.contactPhone?.isNotEmpty == true)
                  Text('Phone: ${branch.contactPhone}', style: AppTextStyles.bodyMd),
                if (branch.operatingHours?.isNotEmpty == true)
                  Text('Hours: ${branch.operatingHours}', style: AppTextStyles.bodyMd),
                if (branch.address.isEmpty &&
                    branch.contactPhone?.isNotEmpty != true &&
                    branch.operatingHours?.isNotEmpty != true)
                  Text('This branch has not published contact details yet.', style: AppTextStyles.bodyMd),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, {String? notice}) {
    final order = _order;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        leading: const BackButton(),
        title: Column(
          children: [
            Text('MELAI NUTS DELIVERY', style: AppTextStyles.labelSm),
            Text('Track Order ${order.id}', style: AppTextStyles.titleMd),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Contact branch',
            onPressed: () => _showBranchContact(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (notice != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 18, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(notice, style: AppTextStyles.bodySm.copyWith(color: AppColors.warning)),
                    ),
                    TextButton(onPressed: _refetch, child: const Text('Retry')),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warningBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '● ${order.status.label}',
                          style: AppTextStyles.labelMd.copyWith(color: AppColors.warning),
                        ),
                      ),
                      Text(order.branch, style: AppTextStyles.bodySm),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'ETA ${order.etaLabel ?? '—'}',
                    style: AppTextStyles.headlineLg.copyWith(color: AppColors.primary),
                  ),
                  Text(
                    order.isDelivery ? 'Delivery order' : 'Pickup order',
                    style: AppTextStyles.bodySm,
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _progressFor(order.status),
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Order Timeline', style: AppTextStyles.titleMd),
                                          ],
                  ),
                  const SizedBox(height: 12),
                  for (int i = 0; i < order.timeline.length; i++)
                    _TimelineRow(
                      step: order.timeline[i],
                      isLast: i == order.timeline.length - 1,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (order.riderName != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primaryContainer,
                      child: Icon(Icons.person, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.riderName!, style: AppTextStyles.titleMd),
                          Text('Delivery rider', style: AppTextStyles.bodySm),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Rider messaging isn't available yet.")),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                    ),
                    IconButton(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Rider calling isn't available yet.")),
                      ),
                      icon: const Icon(Icons.call_outlined),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.darkBrown),
                      const SizedBox(width: 8),
                      Text('Package Manifest', style: AppTextStyles.titleMd),
                      const Spacer(),
                      Text('${order.itemCount} Items', style: AppTextStyles.bodySm),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final item in order.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 6, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${item.productName} (${item.variantLabel})',
                              style: AppTextStyles.bodyMd,
                            ),
                          ),
                          Text('${item.quantity}x', style: AppTextStyles.bodySm),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
              ),
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: const Text('View Order Details & Receipt'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final OrderTimelineStep step;
  final bool isLast;

  const _TimelineRow({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = step.done
        ? AppColors.success
        : step.current
        ? AppColors.primary
        : AppColors.border;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(
                  step.done
                      ? Icons.check
                      : step.current
                      ? Icons.local_shipping_rounded
                      : Icons.circle,
                  size: 13,
                  color: Colors.white,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: AppColors.border),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.label,
                          style: AppTextStyles.labelLg.copyWith(
                            color: step.current ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        Text(step.description, style: AppTextStyles.bodySm),
                      ],
                    ),
                  ),
                  Text(step.time, style: AppTextStyles.bodySm),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
