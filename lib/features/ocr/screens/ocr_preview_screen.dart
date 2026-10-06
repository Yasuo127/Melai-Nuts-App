import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';

/// Review the "captured" photo before running OCR. Since there's no real
/// camera, this shows a static mock preview. A demo toggle lets you force
/// the simulated low-quality/failure path so the OCR Error screen is
/// reachable without relying on random chance.
class OcrPreviewScreen extends StatefulWidget {
  const OcrPreviewScreen({super.key});

  @override
  State<OcrPreviewScreen> createState() => _OcrPreviewScreenState();
}

class _OcrPreviewScreenState extends State<OcrPreviewScreen> {
  bool _simulatePoorScan = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text('Review Capture', style: AppTextStyles.titleMd.copyWith(color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 24)],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('MELAI NUTS LOGISTICS', style: AppTextStyles.labelSm.copyWith(color: AppColors.primary)),
                      Text('Laguna Master Roastery & Co-op', style: AppTextStyles.titleMd),
                      const Divider(height: 20),
                      Text('PRODUCT', style: AppTextStyles.labelSm),
                      Text('Garlic Peanuts (250g Standup Pouch)', style: AppTextStyles.bodyMd),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('BATCH NO', style: AppTextStyles.labelSm),
                                Text('#MN-GP-045-SC', style: AppTextStyles.bodyMd),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('QUANTITY', style: AppTextStyles.labelSm),
                                Text('180 Foil Packs', style: AppTextStyles.bodyMd),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ROAST DATE', style: AppTextStyles.labelSm),
                                Text('Aug 20, 2026', style: AppTextStyles.bodyMd),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('EXPIRY DATE', style: AppTextStyles.labelSm),
                                Text('Nov 20, 2026', style: AppTextStyles.bodyMd),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _simulatePoorScan,
                  activeThumbColor: Colors.deepOrange,
                  onChanged: (v) => setState(() => _simulatePoorScan = v),
                  title: Text('Simulate poor scan quality', style: AppTextStyles.labelLg.copyWith(color: Colors.white)),
                  subtitle: Text('Demo toggle — forces the OCR error/retry path', style: AppTextStyles.bodySm.copyWith(color: Colors.white60)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Retake Photo',
                      icon: Icons.replay_rounded,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      label: 'Use This Photo',
                      icon: Icons.check_rounded,
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.ocrProcessing,
                        arguments: _simulatePoorScan,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
