import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_text_styles.dart';

/// "Scan Supplier Invoice or Batch Tag" — a full-screen dark camera mock
/// matching the prototype's OCR Scanner capture screen. There is no real
/// camera here: tapping the shutter simulates taking a photo and moves to
/// the (also simulated) preview screen.
class OcrCaptureScreen extends StatefulWidget {
  const OcrCaptureScreen({super.key});

  @override
  State<OcrCaptureScreen> createState() => _OcrCaptureScreenState();
}

enum _ScanMode { barcode, documentOcr, crateTag }

class _OcrCaptureScreenState extends State<OcrCaptureScreen> {
  _ScanMode _mode = _ScanMode.documentOcr;
  bool _flashOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _RoundIconButton(icon: Icons.close_rounded, onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.storefront_rounded, color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Text('Melai Nuts · OCR Scanner', style: AppTextStyles.labelMd.copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _RoundIconButton(icon: Icons.grid_view_rounded, onTap: () {}),
                  const SizedBox(width: 8),
                  _RoundIconButton(
                    icon: Icons.bolt_rounded,
                    onTap: () => setState(() => _flashOn = !_flashOn),
                    highlighted: _flashOn,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Scan Supplier Invoice or Batch Tag',
              style: AppTextStyles.headlineSm.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              'Laguna Intake Verification System',
              style: AppTextStyles.bodySm.copyWith(color: Colors.white60),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Viewfinder corner brackets.
                    Positioned.fill(child: CustomPaint(painter: _ViewfinderPainter())),
                    // Mock document card standing in for the camera preview.
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('MELAI NUTS LOGISTICS', style: AppTextStyles.labelSm.copyWith(color: Colors.brown)),
                          Text('Laguna Master Roastery & Co-op', style: AppTextStyles.labelLg),
                          const Divider(height: 16),
                          Text('PRODUCT', style: AppTextStyles.labelSm),
                          Text('Garlic Peanuts (250g Standup Pouch)', style: AppTextStyles.bodyMd),
                          const SizedBox(height: 6),
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ModeLabel(label: 'BARCODE', selected: _mode == _ScanMode.barcode, onTap: () => setState(() => _mode = _ScanMode.barcode)),
                  _ModeLabel(label: 'DOCUMENT OCR', selected: _mode == _ScanMode.documentOcr, onTap: () => setState(() => _mode = _ScanMode.documentOcr)),
                  _ModeLabel(label: 'CRATE TAG', selected: _mode == _ScanMode.crateTag, onTap: () => setState(() => _mode = _ScanMode.crateTag)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SideAction(icon: Icons.photo_library_outlined, label: 'Gallery', onTap: () => Navigator.of(context).pushNamed(AppRoutes.ocrPreview)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.ocrPreview),
                    child: Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.deepOrange, width: 3),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Container(
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        child: const Icon(Icons.document_scanner_outlined, color: Colors.black87),
                      ),
                    ),
                  ),
                  _SideAction(icon: Icons.landscape_outlined, label: 'Macro Doc', onTap: () => Navigator.of(context).pushNamed(AppRoutes.ocrPreview)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

  const _RoundIconButton({required this.icon, required this.onTap, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: highlighted ? Colors.deepOrange : Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _ModeLabel extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeLabel({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.black54 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMd.copyWith(color: selected ? Colors.white : Colors.white38, fontWeight: selected ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }
}

class _SideAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SideAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodySm.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepOrange
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const len = 28.0;
    final rect = Rect.fromLTWH(0, size.height * 0.08, size.width, size.height * 0.78);

    // Top-left
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(len, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, len), paint);
    // Top-right
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(-len, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, len), paint);
    // Bottom-left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(len, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(0, -len), paint);
    // Bottom-right
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(-len, 0), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(0, -len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
