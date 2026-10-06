import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/melai_app_bar.dart';
import '../../../data/dummy_data/dummy_sales.dart';

/// Sales Overview — Today / This Week / This Month totals with a
/// per-branch mini breakdown, and links into deeper Analytics/Trends/
/// Forecast screens.
class SalesOverviewScreen extends StatefulWidget {
  const SalesOverviewScreen({super.key});

  @override
  State<SalesOverviewScreen> createState() => _SalesOverviewScreenState();
}

enum _Period { today, week, month }

class _SalesOverviewScreenState extends State<SalesOverviewScreen> {
  _Period _period = _Period.today;

  @override
  Widget build(BuildContext context) {
    double revenue;
    int orders;
    switch (_period) {
      case _Period.today:
        revenue = todaysGrossSales;
        orders = todaysOrderCount;
        break;
      case _Period.week:
        revenue = weekGrossSales;
        orders = weekOrderCount;
        break;
      case _Period.month:
        revenue = monthGrossSales;
        orders = weekOrderCount * 4;
        break;
    }
    final avgOrder = orders == 0 ? 0 : revenue / orders;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: MelaiAppBar(
        title: 'Sales Overview',
        showBack: true,
        actions: [
          IconButton(icon: const Icon(Icons.query_stats_rounded), onPressed: () => Navigator.of(context).pushNamed(AppRoutes.ownerSalesAnalytics)),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            SegmentedButton<_Period>(
              segments: const [
                ButtonSegment(value: _Period.today, label: Text('Today')),
                ButtonSegment(value: _Period.week, label: Text('This Week')),
                ButtonSegment(value: _Period.month, label: Text('This Month')),
              ],
              selected: {_period},
              onSelectionChanged: (s) => setState(() => _period = s.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.border), boxShadow: AppShadows.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GROSS SALES', style: AppTextStyles.labelSm),
                  Text('₱${revenue.toStringAsFixed(2)}', style: AppTextStyles.headlineLg.copyWith(color: AppColors.roleOwner)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Orders', style: AppTextStyles.bodySm),
                            Text('$orders', style: AppTextStyles.titleMd),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Avg Order Value', style: AppTextStyles.bodySm),
                            Text('₱${avgOrder.toStringAsFixed(0)}', style: AppTextStyles.titleMd),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Per-Branch Breakdown', style: AppTextStyles.headlineSm),
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
                          Expanded(child: Text(b.branch, style: AppTextStyles.bodyMd)),
                          Text(
                            '₱${(_period == _Period.today ? b.todayRevenue : _period == _Period.week ? b.weekRevenue : b.monthRevenue).toStringAsFixed(0)}',
                            style: AppTextStyles.labelLg,
                          ),
                        ],
                      ),
                    ),
                    if (b != kBranchSalesList.last) const Divider(height: 1),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.ownerSalesTrends),
                    icon: const Icon(Icons.show_chart_rounded, size: 16),
                    label: const Text('Trends'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.ownerSalesForecast),
                    icon: const Icon(Icons.auto_graph_rounded, size: 16),
                    label: const Text('Forecast'),
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
