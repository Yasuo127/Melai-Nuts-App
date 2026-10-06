import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/melai_app_bar.dart';
import '../../../data/dummy_data/dummy_sales.dart';
import '../widgets/branch_performance_card.dart';

/// Branch Performance Comparison — ranked branch cards plus a shared
/// benchmark section (revenue share, transaction speed, stockouts, loyalty
/// tap rate), matching the prototype's Branch Comparison screen.
class BranchComparisonScreen extends StatelessWidget {
  const BranchComparisonScreen({super.key});

  // Operational benchmarks — to be populated by real telemetry.
  static const _txnSpeedSeconds = <String, int>{};
  static const _stockoutIncidents = <String, int>{};
  static const _loyaltyTapRate = <String, double>{};

  @override
  Widget build(BuildContext context) {
    final ranked = [...kBranchSalesList]..sort((a, b) => b.weekRevenue.compareTo(a.weekRevenue));
    final totalRevenue = kBranchSalesList.fold<double>(0, (sum, b) => sum + b.weekRevenue);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const MelaiAppBar(title: 'Branch Comparison', showBack: true),
      body: SafeArea(
        child: kBranchSalesList.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.compare_arrows_rounded, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text('No comparison data yet.', style: AppTextStyles.headlineSm.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Text('Add branches to compare their performance.', style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Text('Comparative audit & operations analytics • This Week (Mon–Sun)', style: AppTextStyles.bodySm),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Branch Comparison Matrix', style: AppTextStyles.headlineSm),
                  const SizedBox(height: AppSpacing.sm),
                  for (int i = 0; i < ranked.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BranchPerformanceCard(
                        sales: ranked[i],
                        rank: i + 1,
                        onTap: () => Navigator.of(context).pushNamed(AppRoutes.ownerBranchPerformance, arguments: ranked[i].branch),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Performance Benchmark', style: AppTextStyles.headlineSm),
                  Text('Comparative share across ${kBranchSalesList.length} branches', style: AppTextStyles.bodySm),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.border), boxShadow: AppShadows.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Revenue Distribution', style: AppTextStyles.labelLg),
                            Text('₱${totalRevenue.toStringAsFixed(0)} aggregate', style: AppTextStyles.bodySm),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            height: 12,
                            child: Row(
                              children: [
                                for (final b in kBranchSalesList)
                                  Expanded(
                                    flex: (totalRevenue == 0 ? 0 : b.weekRevenue / totalRevenue * 1000).round(),
                                    child: Container(color: _branchColor(b.branch)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          children: [
                            for (final b in kBranchSalesList)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(width: 10, height: 10, decoration: BoxDecoration(color: _branchColor(b.branch), shape: BoxShape.circle)),
                                  const SizedBox(width: 4),
                                  Text('${b.branch.split(' ').first} (${totalRevenue == 0 ? 0 : (b.weekRevenue / totalRevenue * 100).toStringAsFixed(0)}%)', style: AppTextStyles.bodySm),
                                ],
                              ),
                          ],
                        ),
                        const Divider(height: 24),
                        Text('Transaction Speed (Sec / Checkout) • Optimal: < 45s', style: AppTextStyles.labelLg),
                        const SizedBox(height: 8),
                        for (final b in kBranchSalesList)
                          _BenchmarkBar(
                            label: b.branch.split(' ').first,
                            value: (_txnSpeedSeconds[b.branch] ?? 0).toDouble(),
                            max: 60,
                            suffix: 's',
                            good: (_txnSpeedSeconds[b.branch] ?? 0) < 45,
                          ),
                        const Divider(height: 24),
                        Text('Stock-Out Frequency (Weekly Incidents) • Lower is better', style: AppTextStyles.labelLg),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (final b in kBranchSalesList)
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
                                  child: Column(
                                    children: [
                                      Text(b.branch.split(' ').first, style: AppTextStyles.bodySm),
                                      Text(
                                        '${_stockoutIncidents[b.branch] ?? 0}',
                                        style: AppTextStyles.headlineSm.copyWith(color: (_stockoutIncidents[b.branch] ?? 0) == 0 ? AppColors.success : AppColors.error),
                                      ),
                                      Text('incidents', style: AppTextStyles.bodySm),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Divider(height: 24),
                        Text('Customer Loyalty Tap Rate (Golden Kernel)', style: AppTextStyles.labelLg),
                        const SizedBox(height: 8),
                        for (final b in kBranchSalesList)
                          _BenchmarkBar(
                            label: b.branch.split(' ').first,
                            value: _loyaltyTapRate[b.branch] ?? 0,
                            max: 100,
                            suffix: '%',
                            good: true,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Color _branchColor(String branch) {
    switch (branch) {
      case 'Calamba Highway Branch':
        return AppColors.primary;
      case 'Los Baños Hub':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }
}

class _BenchmarkBar extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final String suffix;
  final bool good;

  const _BenchmarkBar({required this.label, required this.value, required this.max, required this.suffix, required this.good});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: AppTextStyles.bodySm)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (value / max).clamp(0, 1),
                minHeight: 10,
                backgroundColor: AppColors.border,
                color: good ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 44, child: Text('${value.toStringAsFixed(0)}$suffix', style: AppTextStyles.labelMd, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
