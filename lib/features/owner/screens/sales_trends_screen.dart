import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/melai_app_bar.dart';
import '../../../data/dummy_data/dummy_sales.dart';
import '../widgets/sales_chart.dart';

/// Sales Trends — Daily/Weekly/Monthly bar chart plus a week-over-week
/// performance breakdown, matching the prototype's Sales Trends screen.
class SalesTrendsScreen extends StatefulWidget {
  const SalesTrendsScreen({super.key});

  @override
  State<SalesTrendsScreen> createState() => _SalesTrendsScreenState();
}

enum _Granularity { daily, weekly, monthly }

class _SalesTrendsScreenState extends State<SalesTrendsScreen> {
  _Granularity _granularity = _Granularity.weekly;

  @override
  Widget build(BuildContext context) {
    final series = _granularity == _Granularity.monthly ? kMonthlyRevenueSeries : kWeeklyRevenueSeries;
    final current = kWeeklyBreakdown.isEmpty
        ? const WeeklyBreakdown(label: '—', dateRange: 'No data yet', orders: 0, revenue: 0, growthPercent: 0)
        : kWeeklyBreakdown.first;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: MelaiAppBar(
        title: 'Sales Trends',
        showBack: true,
        actions: [IconButton(icon: const Icon(Icons.calendar_today_outlined), onPressed: () {})],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            SegmentedButton<_Granularity>(
              segments: const [
                ButtonSegment(value: _Granularity.daily, label: Text('Daily')),
                ButtonSegment(value: _Granularity.weekly, label: Text('Weekly')),
                ButtonSegment(value: _Granularity.monthly, label: Text('Monthly')),
              ],
              selected: {_granularity},
              onSelectionChanged: (s) => setState(() => _granularity = s.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _StatBlock(label: 'Current Period', value: '₱${current.revenue.toStringAsFixed(0)}'),
                ),
                Expanded(
                  child: _StatBlock(label: 'Velocity', value: '₱${(current.revenue / 7).toStringAsFixed(0)}/d'),
                ),
                Expanded(
                  child: _StatBlock(
                    label: 'Growth',
                    value: '+${current.growthPercent.toStringAsFixed(1)}%',
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.border), boxShadow: AppShadows.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_granularity == _Granularity.monthly ? 'MONTHLY REVENUE TRAJECTORY' : 'DAILY TRAJECTORY & VOLUME', style: AppTextStyles.labelSm),
                  const SizedBox(height: 10),
                  SalesBarChart(points: series),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Performance Breakdown', style: AppTextStyles.headlineSm),
                Text('4 Weeks Window', style: AppTextStyles.bodySm),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (kWeeklyBreakdown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No sales data yet.', style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted)),
                ),
              ),
            for (final w in kWeeklyBreakdown)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.border)),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.surfaceContainerLow, shape: BoxShape.circle),
                        child: Text(w.label, style: AppTextStyles.labelMd),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(w.dateRange, style: AppTextStyles.labelLg),
                            Text('${w.orders} orders • Avg ₱${(w.revenue / w.orders).toStringAsFixed(0)}/order', style: AppTextStyles.bodySm),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₱${w.revenue.toStringAsFixed(0)}', style: AppTextStyles.titleMd),
                          Text(
                            w.growthPercent == 0 ? 'Baseline' : '+${w.growthPercent.toStringAsFixed(1)}%',
                            style: AppTextStyles.bodySm.copyWith(color: w.growthPercent == 0 ? AppColors.textSecondary : AppColors.success),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.ownerSalesForecast),
              icon: const Icon(Icons.auto_graph_rounded, size: 16),
              label: const Text('Compare with Linear Trend Forecast'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatBlock({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySm),
          Text(value, style: AppTextStyles.titleMd.copyWith(color: color)),
        ],
      ),
    );
  }
}
