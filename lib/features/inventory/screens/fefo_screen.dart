import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/melai_app_bar.dart';
import '../../../core/services/staff_store.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/staff_data_scope.dart';
import '../../../data/dummy_data/dummy_inventory.dart';
import '../../../data/models/inventory_batch.dart';
import '../widgets/fefo_badge.dart';
import '../widgets/inventory_card.dart';

/// FEFO (First Expired, First Out) overview: priority-tier breakdown,
/// per-branch stock summary, and (when a single tier is selected) the full
/// list of batches in that tier.
class FefoScreen extends StatelessWidget {
  final FefoPriority? initialFilter;

  const FefoScreen({super.key, this.initialFilter});

  /// Staff only work in one branch; the list holds the branch being viewed.
  List<String> _branches() {
    final name = StaffStore.instance.activeBranchName;
    return name.isEmpty ? const [] : [name];
  }

  @override
  Widget build(BuildContext context) {
    return StaffDataScope(builder: (context, store) => _content(context));
  }

  Widget _content(BuildContext context) {
    // A specific tier was requested (e.g. tapped from the dashboard's
    // "Expiring Soon" stat) — show just that tier's batch list.
    if (initialFilter != null) {
      final priority = initialFilter!;
      final batches = batchesByPriority(priority);
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: MelaiAppBar(title: '${priority.label} Priority Batches', showBack: true),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Row(
                children: [
                  FefoBadge(priority: priority, showDot: true),
                  const SizedBox(width: 8),
                  Text(priority.description, style: AppTextStyles.bodySm),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              for (final batch in batches)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InventoryCard.batch(
                    batch: batch,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.inventoryBatchDetails, arguments: batch),
                  ),
                ),
              if (batches.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No batches in this tier.', style: AppTextStyles.bodyMd)),
                ),
            ],
          ),
        ),
      );
    }

    // Default: the full FEFO overview.
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const MelaiAppBar(title: 'FEFO Overview', showBack: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'FEFO = First Expired, First Out. Batches closer to expiry should always be sold before newer stock.',
                      style: AppTextStyles.bodyMd,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('FEFO Priority Tiers', style: AppTextStyles.headlineSm),
            const SizedBox(height: AppSpacing.sm),
            for (final priority in FefoPriority.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PriorityTierRow(
                  priority: priority,
                  count: batchesByPriority(priority).length,
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.inventoryFefo,
                    arguments: priority,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            Text('Stock by Branch', style: AppTextStyles.headlineSm),
            const SizedBox(height: AppSpacing.sm),
            for (final branch in _branches())
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BranchSummaryRow(
                  branch: branch,
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.inventoryBranch, arguments: branch),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: 'View Full Inventory List',
              icon: Icons.list_alt_rounded,
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.inventoryList),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityTierRow extends StatelessWidget {
  final FefoPriority priority;
  final int count;
  final VoidCallback onTap;

  const _PriorityTierRow({required this.priority, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: priority.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: priority.color, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${priority.label} PRIORITY', style: AppTextStyles.labelLg.copyWith(color: priority.color)),
                  Text(priority.description, style: AppTextStyles.bodySm),
                ],
              ),
            ),
            Text('$count batches', style: AppTextStyles.labelLg),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _BranchSummaryRow extends StatelessWidget {
  final String branch;
  final VoidCallback onTap;

  const _BranchSummaryRow({required this.branch, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final batches = batchesForBranch(branch);
    final units = batches.fold<int>(0, (sum, b) => sum + b.quantity);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            const Icon(Icons.storefront_outlined, color: AppColors.roleStaff),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(branch, style: AppTextStyles.labelLg),
                  Text('${batches.length} batches • $units units', style: AppTextStyles.bodySm),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
