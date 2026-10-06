import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../ocr_scan_result.dart';

/// Simulated OCR extraction progress — matches the prototype's processing
/// screen (progress ring over the mock document + a step-by-step
/// "ingestion telemetry" list). After a short delay this auto-navigates to
/// Verify (success) or Error, depending on [simulateFailure].
class OcrProcessingScreen extends StatefulWidget {
  final bool simulateFailure;

  const OcrProcessingScreen({super.key, this.simulateFailure = false});

  @override
  State<OcrProcessingScreen> createState() => _OcrProcessingScreenState();
}

class _OcrProcessingScreenState extends State<OcrProcessingScreen> {
  double _progress = 0.0;
  int _stepIndex = 0;

  static const _steps = [
    ('Optical character recognition initialized', 'Tesseract OCR Engine active • 300 DPI upscale'),
    ('Detected document format', 'Roastery Batch Intake Slip (Laguna Hub standard v2.4)'),
    ('Parsing key-value pairs', 'Batch, quantity, product SKU, and FEFO expiry timeline'),
    ('Cross-referencing against catalog', 'Melai SKU Master Catalog • Automated pricing verification'),
  ];

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      setState(() {
        _stepIndex = i + 1;
        _progress = (i + 1) / _steps.length;
      });
    }
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    if (widget.simulateFailure) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.ocrError);
    } else {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.ocrVerify,
        arguments: OcrScanResult.blank(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Melai Nuts Retailing'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).popUntil((r) => r.settings.name == AppRoutes.staffHome),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Cancel'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.sm,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(20)),
                    child: Text('● ANALYZING BATCH RECEIPT & TEXT FIELDS...', style: AppTextStyles.labelSm),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(value: _progress, strokeWidth: 6, backgroundColor: AppColors.border, color: AppColors.primary),
                            Text('${(_progress * 100).round()}%', style: AppTextStyles.labelLg),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Extraction in Progress', style: AppTextStyles.titleMd),
                            Text(
                              'Extracting product SKU, batch number, production date, and FEFO expiry timeline.',
                              style: AppTextStyles.bodySm,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('REAL-TIME INGESTION TELEMETRY', style: AppTextStyles.labelSm),
                Text('STEP ${_stepIndex.clamp(1, _steps.length)} OF ${_steps.length}', style: AppTextStyles.labelSm),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < _steps.length; i++) ...[
                    _TelemetryRow(
                      title: _steps[i].$1,
                      subtitle: _steps[i].$2,
                      status: i < _stepIndex - 1
                          ? _TelemetryStatus.pass
                          : i == _stepIndex - 1
                              ? _TelemetryStatus.running
                              : _TelemetryStatus.queued,
                    ),
                    if (i != _steps.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'OCR provides smart assistance by auto-filling fields. You will be prompted to review and verify every field before any inventory is committed.',
                      style: AppTextStyles.bodyMd,
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

enum _TelemetryStatus { pass, running, queued }

class _TelemetryRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final _TelemetryStatus status;

  const _TelemetryRow({required this.title, required this.subtitle, required this.status});

  @override
  Widget build(BuildContext context) {
    late final Widget badge;
    switch (status) {
      case _TelemetryStatus.pass:
        badge = _Badge(label: 'PASS', color: AppColors.success);
        break;
      case _TelemetryStatus.running:
        badge = _Badge(label: 'RUNNING', color: AppColors.warning);
        break;
      case _TelemetryStatus.queued:
        badge = _Badge(label: 'QUEUED', color: AppColors.textSecondary);
        break;
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            status == _TelemetryStatus.pass
                ? Icons.check_circle
                : status == _TelemetryStatus.running
                    ? Icons.autorenew_rounded
                    : Icons.hourglass_empty_rounded,
            size: 20,
            color: status == _TelemetryStatus.pass
                ? AppColors.success
                : status == _TelemetryStatus.running
                    ? AppColors.warning
                    : AppColors.textSecondary,
          ),
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
          badge,
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: AppTextStyles.labelSm.copyWith(color: color)),
    );
  }
}
