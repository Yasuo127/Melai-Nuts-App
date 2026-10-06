import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import 'package:melai_nuts/data/catalog_store.dart';
import '../../../data/dummy_data/dummy_inventory.dart';
import '../ocr_scan_result.dart';

/// "Stock Imported Successfully!" — confirms the (simulated) OCR-driven
/// batch intake, with before/after stock numbers and an audit trail.
class OcrSuccessScreen extends StatelessWidget {
  final OcrScanResult result;

  const OcrSuccessScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    // Match scanned product against catalog so metrics are grounded in data.
    final matchedProduct = kProducts.cast().firstWhere(
          (p) => result.matchedSku.isNotEmpty && p!.variants.any((v) => v.sku == result.matchedSku),
      orElse: () => null,
    );
    final previousStock = matchedProduct == null ? 0 : totalStockFor(matchedProduct.id);
    final newBalance = previousStock + result.quantity;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('OCR VERIFICATION', style: AppTextStyles.labelSm),
                      Text('Inflow Intake Recorded', style: AppTextStyles.titleMd),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, color: AppColors.success, size: 38),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(20)),
                    child: Text('● OCR ENGINE SYNCED', style: AppTextStyles.labelSm.copyWith(color: AppColors.success)),
                  ),
                  const SizedBox(height: 12),
                  Text('Stock Imported\nSuccessfully!', textAlign: TextAlign.center, style: AppTextStyles.headlineLg),
                  const SizedBox(height: 8),
                  Text(
                    '${result.quantity} packs of ${result.productName} have been verified and added to the ${result.receivingBranch} inventory ledger.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd,
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storefront_outlined, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(result.receivingBranch, style: AppTextStyles.labelMd),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(20)),
                        child: Text('Live Reconciled', style: AppTextStyles.labelSm.copyWith(color: AppColors.success)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('SKU METRICS', style: AppTextStyles.labelSm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Text(result.batchNumber, style: AppTextStyles.labelSm),
                      ),
                    ],
                  ),
                  Text(matchedProduct?.name ?? result.productName, style: AppTextStyles.titleMd),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _Metric(label: 'Previous', value: '$previousStock', sub: 'packs')),
                      Expanded(child: _Metric(label: 'OCR Added', value: '+${result.quantity}', sub: 'verified', color: AppColors.success)),
                      Expanded(child: _Metric(label: 'New Balance', value: '$newBalance', sub: 'packs total', color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 18, color: AppColors.darkBrown),
                      const SizedBox(width: 8),
                      Text('Audit & Traceability', style: AppTextStyles.titleMd),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(20)),
                        child: Text('Encrypted', style: AppTextStyles.labelSm.copyWith(color: AppColors.success)),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  const _AuditRow(label: 'Intake Method', value: 'OCR Smart Scan (Manual Verified)'),
                  _AuditRow(label: 'Authorized Receiver', value: result.receivingStaff),
                  _AuditRow(label: 'Timestamp', value: 'Today, ${TimeOfDay.now().format(context)}'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'View Updated Product Inventory',
              icon: Icons.inventory_2_outlined,
              onPressed: matchedProduct == null
                  ? null
                  : () => Navigator.of(context).pushNamed(
                AppRoutes.inventoryProductDetails,
                arguments: matchedProduct.id,
              ),
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: 'Scan Another Batch Tag / Invoice',
              icon: Icons.qr_code_scanner_rounded,
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.ocrCapture,
                    (r) => r.settings.name == AppRoutes.staffHome,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).popUntil((r) => r.settings.name == AppRoutes.staffHome),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Return to Inventory Command'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color? color;

  const _Metric({required this.label, required this.value, required this.sub, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.bodySm),
        Text(value, style: AppTextStyles.headlineSm.copyWith(color: color)),
        Text(sub, style: AppTextStyles.bodySm),
      ],
    );
  }
}

class _AuditRow extends StatelessWidget {
  final String label;
  final String value;

  const _AuditRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySm),
          Text(value, style: AppTextStyles.labelLg),
        ],
      ),
    );
  }
}