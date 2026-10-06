import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/melai_app_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/dummy_data/dummy_sales.dart';
import '../widgets/sales_chart.dart';

/// Sales Forecast & Restocking — a clearly-labeled *estimate* projected
/// from recent sales trends (simulated simple linear regression), plus
/// restocking guidance derived from it. This is explicitly NOT a
/// guaranteed prediction — see the disclaimer banner.
class SalesForecastScreen extends StatefulWidget {
  const SalesForecastScreen({super.key});

  @override
  State<SalesForecastScreen> createState() => _SalesForecastScreenState();
}

enum _Horizon { sevenDays, fourteenDays, nextMonth }

class _SalesForecastScreenState extends State<SalesForecastScreen> {
  _Horizon _horizon = _Horizon.nextMonth;

  @override
  Widget build(BuildContext context) {
    late final double factor;
    late final String horizonLabel;
    switch (_horizon) {
      case _Horizon.sevenDays:
        factor = 7 / 30;
        horizonLabel = 'next 7 days';
        break;
      case _Horizon.fourteenDays:
        factor = 14 / 30;
        horizonLabel = 'next 14 days';
        break;
      case _Horizon.nextMonth:
        factor = 1;
        horizonLabel = 'next month';
        break;
    }
    final forecastTotal = kForecastNextMonthTotal * factor;
    final forecastLow = kForecastRangeLow * factor;
    final forecastHigh = kForecastRangeHigh * factor;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const MelaiAppBar(title: 'Sales Forecast & Restocking', showBack: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_graph_rounded, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Estimated Forecast (Simple Linear Regression Model)',
                          style: AppTextStyles.labelLg.copyWith(color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'This is a statistical projection calculated from past point-of-sale data trends. '
                    'It is intended for operational planning and restock guidance only — it is an estimate, '
                    'not a guaranteed prediction of future sales.',
                    style: AppTextStyles.bodyMd,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SegmentedButton<_Horizon>(
              segments: const [
                ButtonSegment(value: _Horizon.sevenDays, label: Text('Next 7 Days')),
                ButtonSegment(value: _Horizon.fourteenDays, label: Text('Next 14 Days')),
                ButtonSegment(value: _Horizon.nextMonth, label: Text('Next Month')),
              ],
              selected: {_horizon},
              onSelectionChanged: (s) => setState(() => _horizon = s.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.border), boxShadow: AppShadows.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ESTIMATED REVENUE FORECAST', style: AppTextStyles.labelSm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(20)),
                        child: Text('R² = ${kForecastConfidenceR2.toStringAsFixed(2)}', style: AppTextStyles.labelSm),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₱${forecastTotal.toStringAsFixed(0)}', style: AppTextStyles.headlineLg.copyWith(color: AppColors.roleOwner)),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('↗ +${kForecastGrowthPercent.toStringAsFixed(1)}%', style: AppTextStyles.labelLg.copyWith(color: AppColors.success)),
                      ),
                    ],
                  ),
                  Text(
                    'Estimated for $horizonLabel • Range: ₱${forecastLow.toStringAsFixed(0)} – ₱${forecastHigh.toStringAsFixed(0)}',
                    style: AppTextStyles.bodySm,
                  ),
                  const SizedBox(height: 14),
                  Text('SALES TRAJECTORY (HISTORY + PROJECTION)', style: AppTextStyles.labelSm),
                  const SizedBox(height: 8),
                  if (kWeeklyRevenueSeries.isEmpty && kForecastTrajectory.isEmpty)
                    const SizedBox(height: 200, child: Center(child: Text('No trajectory data available.')))
                  else
                    SalesBarChart(points: [...kWeeklyRevenueSeries, ...kForecastTrajectory]),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _LegendDot(color: AppColors.primary, label: 'Historical'),
                      const SizedBox(width: 14),
                      _LegendDot(color: AppColors.primary.withValues(alpha: 0.35), label: 'Projected (Estimate)'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Restocking Insights', style: AppTextStyles.headlineSm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(20)),
                  child: Text('${kRestockInsights.length} Active', style: AppTextStyles.labelSm.copyWith(color: AppColors.primaryDark)),
                ),
              ],
            ),
            Text('Estimated demand — recommended batch allocations for Laguna hubs.', style: AppTextStyles.bodySm),
            const SizedBox(height: AppSpacing.sm),
            if (kRestockInsights.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No restocking insights available.', style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted))),
              )
            else
              for (final insight in kRestockInsights)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.border), boxShadow: AppShadows.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(20)),
                            child: Text('↗ Est. Surge +${insight.growthPercent.toStringAsFixed(1)}%', style: AppTextStyles.labelSm.copyWith(color: AppColors.success)),
                          ),
                          const Spacer(),
                          Text(insight.branch, style: AppTextStyles.bodySm),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(insight.productName, style: AppTextStyles.titleMd),
                      Text(insight.note, style: AppTextStyles.bodySm),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Current Weekly Run', style: AppTextStyles.bodySm),
                                Text('${insight.currentWeeklyRun} packs', style: AppTextStyles.labelLg),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Est. Projected Demand', style: AppTextStyles.bodySm),
                                Text('${insight.projectedDemand} packs', style: AppTextStyles.labelLg.copyWith(color: AppColors.success)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
                        child: Text(insight.recommendation, style: AppTextStyles.bodySm.copyWith(color: AppColors.primaryDark)),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(
              label: 'Apply Recommended Roasting Schedule',
              icon: Icons.check_circle_outline_rounded,
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Simulated: recommended schedule applied (estimate-based, no backend).')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.bodySm),
      ],
    );
  }
}
