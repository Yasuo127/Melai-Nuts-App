/// Simulated OCR extraction result passed between OCR flow screens.
///
/// There is no real OCR engine here — this returns a blank template
/// so the Capture → Preview → Processing → Verify → Success
/// flow can be demoed end-to-end without a camera or backend.
class OcrScanResult {
  String productName;
  String matchedSku;
  String batchNumber;
  int quantity;
  DateTime manufactureDate;
  DateTime expirationDate;
  String receivingBranch;
  String receivingStaff;
  double confidence; // 0-1

  OcrScanResult({
    required this.productName,
    required this.matchedSku,
    required this.batchNumber,
    required this.quantity,
    required this.manufactureDate,
    required this.expirationDate,
    required this.receivingBranch,
    required this.receivingStaff,
    required this.confidence,
  });

  /// A blank template used when someone chooses "Enter Information
  /// Manually" after a failed scan.
  factory OcrScanResult.blank() => OcrScanResult(
        productName: '',
        matchedSku: '',
        batchNumber: '',
        quantity: 0,
        manufactureDate: DateTime.now(),
        expirationDate: DateTime.now().add(const Duration(days: 90)),
        receivingBranch: '',
        receivingStaff: '',
        confidence: 0,
      );
}
