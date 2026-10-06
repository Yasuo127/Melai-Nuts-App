import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/melai_app_bar.dart';
import '../../../core/utils/validation_utils.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/dummy_data/dummy_inventory.dart';
import '../ocr_scan_result.dart';

/// "Verify Extracted Data" — every OCR field is editable before it's
/// committed, matching the prototype's Verify & Edit screen. Confirming
/// hands the (possibly edited) [OcrScanResult] to the Success screen.
class OcrVerifyScreen extends StatefulWidget {
  final OcrScanResult result;

  const OcrVerifyScreen({super.key, required this.result});

  @override
  State<OcrVerifyScreen> createState() => _OcrVerifyScreenState();
}

class _OcrVerifyScreenState extends State<OcrVerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.result.productName);
  late final _batchController = TextEditingController(text: widget.result.batchNumber);
  late final _staffController = TextEditingController(text: widget.result.receivingStaff);
  late int _quantity = widget.result.quantity;
  late String _branch = widget.result.receivingBranch;
  bool _committing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _batchController.dispose();
    _staffController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _committing = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _committing = false);

    widget.result
      ..productName = _nameController.text
      ..batchNumber = _batchController.text
      ..quantity = _quantity
      ..receivingBranch = _branch
      ..receivingStaff = _staffController.text;

    Navigator.of(context).pushReplacementNamed(AppRoutes.ocrSuccess, arguments: widget.result);
  }

  @override
  Widget build(BuildContext context) {
    final isManualEntry = widget.result.confidence == 0;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: MelaiAppBar(
        title: 'Verify Extracted Data',
        showBack: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.settings.name == AppRoutes.staffHome),
            child: const Text('Discard'),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
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
                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isManualEntry
                            ? 'Fill in the batch intake details manually below.'
                            : 'Please verify the information before saving. OCR has populated these fields from your document scan. You can edit any field to ensure exact accuracy before updating the ledger.',
                        style: AppTextStyles.bodyMd,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isManualEntry) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.border)),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.receipt_long_outlined, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Batch Intake Manifest ${widget.result.batchNumber}', style: AppTextStyles.labelLg),
                            Row(
                              children: [
                                const Icon(Icons.circle, size: 8, color: AppColors.success),
                                const SizedBox(width: 4),
                                Text(
                                  'OCR Confidence: ${(widget.result.confidence * 100).toStringAsFixed(1)}% High',
                                  style: AppTextStyles.bodySm.copyWith(color: AppColors.success),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _FieldCard(
                number: 1,
                icon: Icons.inventory_2_outlined,
                label: 'Product Name',
                trailing: widget.result.matchedSku.isNotEmpty ? 'Matched SKU: ${widget.result.matchedSku}' : 'Not Matched',
                child: TextFormField(
                  controller: _nameController,
                  validator: (v) => ValidationUtils.validateRequired(v, 'Product Name'),
                ),
              ),
              _FieldCard(
                number: 2,
                icon: Icons.tag_rounded,
                label: 'Batch Number',
                trailing: 'Format OK',
                child: TextFormField(
                  controller: _batchController,
                  validator: (v) => ValidationUtils.validateRequired(v, 'Batch Number'),
                ),
              ),
              _FieldCard(
                number: 3,
                icon: Icons.inventory_outlined,
                label: 'Quantity',
                child: Row(
                  children: [
                    IconButton.filled(onPressed: () => setState(() => _quantity = (_quantity - 1).clamp(0, 999999)), icon: const Icon(Icons.remove_rounded)),
                    Expanded(
                      child: Text('$_quantity', textAlign: TextAlign.center, style: AppTextStyles.headlineSm),
                    ),
                    IconButton.filled(onPressed: () => setState(() => _quantity += 1), icon: const Icon(Icons.add_rounded)),
                  ],
                ),
              ),
              _FieldCard(
                number: 4,
                icon: Icons.calendar_today_outlined,
                label: 'Manufacture / Roast Date',
                child: Text(_formatDate(widget.result.manufactureDate), style: AppTextStyles.bodyLg),
              ),
              _FieldCard(
                number: 5,
                icon: Icons.hourglass_bottom_rounded,
                label: 'Expiration Date',
                trailing: 'FEFO Tier',
                child: Text(_formatDate(widget.result.expirationDate), style: AppTextStyles.bodyLg),
              ),
              _FieldCard(
                number: 6,
                icon: Icons.storefront_outlined,
                label: 'Receiving Branch Destination',
                child: DropdownButtonFormField<String>(
                  initialValue: _branch.isEmpty ? null : _branch,
                  items: [for (final b in kInventoryBranches) DropdownMenuItem(value: b, child: Text(b))],
                  onChanged: (v) => setState(() => _branch = v ?? _branch),
                  validator: (v) => ValidationUtils.validateRequired(v, 'Branch'),
                ),
              ),
              _FieldCard(
                number: 7,
                icon: Icons.badge_outlined,
                label: 'Receiving Staff ID',
                child: TextFormField(
                  controller: _staffController,
                  validator: (v) => ValidationUtils.validateRequired(v, 'Staff ID'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Confirm & Commit to Inventory ($_quantity Packs)',
                icon: Icons.cloud_upload_outlined,
                loading: _committing,
                onPressed: _confirm,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Cancel & Re-scan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _FieldCard extends StatelessWidget {
  final int number;
  final IconData icon;
  final String label;
  final String? trailing;
  final Widget child;

  const _FieldCard({
    required this.number,
    required this.icon,
    required this.label,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(child: Text('$number. $label', style: AppTextStyles.labelLg)),
              if (trailing != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(trailing!, style: AppTextStyles.labelSm.copyWith(color: AppColors.success)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
