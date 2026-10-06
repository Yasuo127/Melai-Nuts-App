import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../ocr_scan_result.dart';

/// "Text Recognition Failed" — matches the prototype's OCR Scan Issue
/// screen: failure summary, a diagnostic breakdown, tips for a better
/// rescan, and a manual-entry escape hatch. No unverified data is ever
/// committed from this screen.
class OcrErrorScreen extends StatelessWidget {
  const OcrErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.of(context).pop()),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.circle, size: 8, color: AppColors.error),
                          const SizedBox(width: 6),
                          Text('INVENTORY INBOUND', style: AppTextStyles.labelSm.copyWith(color: AppColors.error)),
                        ],
                      ),
                      Text('OCR Scan Issue', style: AppTextStyles.titleMd),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(20)),
                  child: Text('Santa Cruz Main', style: AppTextStyles.labelSm),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.sm,
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: AppColors.errorBg, shape: BoxShape.circle),
                    child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 34),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(20)),
                    child: Text('EXTRACTION FAILED', style: AppTextStyles.labelSm.copyWith(color: AppColors.error)),
                  ),
                  const SizedBox(height: 10),
                  Text('Text Recognition Failed', style: AppTextStyles.headlineMd, textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(
                    'The scanner could not clearly detect product name, batch ID, or expiration dates from the captured image.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd,
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.verified_user_outlined, size: 16, color: AppColors.success),
                      const SizedBox(width: 6),
                      Expanded(child: Text('No unverified stock data has been committed.', style: AppTextStyles.bodySm)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.image_outlined, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text('Captured Image Preview', style: AppTextStyles.labelMd.copyWith(color: Colors.white))),
                      Text('Frame #0482_RAW', style: AppTextStyles.bodySm.copyWith(color: Colors.white54)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AspectRatio(
                    aspectRatio: 1.6,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(color: Colors.brown.shade900, borderRadius: BorderRadius.circular(10)),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: _FlagChip(label: 'Skew: +24.8° (Max 15°)'),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _FlagChip(label: 'GLARE / BLOWN OUT', danger: true),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: _FlagChip(label: 'Batch ID: [Unreadable]', danger: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Diagnostic Breakdown', style: AppTextStyles.headlineSm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(20)),
                  child: Text('3 Critical Flags', style: AppTextStyles.labelSm.copyWith(color: AppColors.warning)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const _DiagnosticRow(icon: Icons.blur_on_rounded, title: 'Blurry / Low Lighting', subtitle: 'Camera shutter speed compromised edge sharpness.', tag: 'Warning'),
            const SizedBox(height: 8),
            const _DiagnosticRow(icon: Icons.wb_sunny_outlined, title: 'Reflection or Glare', subtitle: 'Overhead fluorescent reflection covering batch barcode and date stamps.', tag: 'Occluded'),
            const SizedBox(height: 8),
            const _DiagnosticRow(icon: Icons.crop_rotate_rounded, title: 'Extreme Perspective Skew', subtitle: 'Document angle skewed beyond automatic perspective correction limit.', tag: 'Off-Axis'),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, color: AppColors.success),
                      const SizedBox(width: 8),
                      Text('Tips for Better OCR Accuracy', style: AppTextStyles.titleMd),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _TipRow(number: 1, text: 'Ensure the document is flat on a well-lit table or checkout counter.'),
                  _TipRow(number: 2, text: 'Avoid direct overhead light glare on laminated or glossy batch foil labels.'),
                  _TipRow(number: 3, text: 'Keep all 4 corners of the supplier slip inside the viewfinder frame.'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Retake Photo with Flash / Better Light',
              icon: Icons.camera_alt_outlined,
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.ocrCapture,
                (r) => r.settings.name == AppRoutes.staffHome,
              ),
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: 'Enter Information Manually',
              icon: Icons.edit_note_rounded,
              onPressed: () => Navigator.of(context).pushReplacementNamed(
                AppRoutes.ocrVerify,
                arguments: OcrScanResult.blank(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  final String label;
  final bool danger;

  const _FlagChip({required this.label, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (danger ? AppColors.error : Colors.black).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
        border: danger ? Border.all(color: AppColors.error) : null,
      ),
      child: Text(label, style: AppTextStyles.labelSm.copyWith(color: Colors.white)),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;

  const _DiagnosticRow({required this.icon, required this.title, required this.subtitle, required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLg),
                Text(subtitle, style: AppTextStyles.bodySm),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Text(tag, style: AppTextStyles.labelSm.copyWith(color: AppColors.warning)),
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final int number;
  final String text;

  const _TipRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
            child: Text('$number', style: AppTextStyles.labelSm.copyWith(color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.bodyMd)),
        ],
      ),
    );
  }
}
