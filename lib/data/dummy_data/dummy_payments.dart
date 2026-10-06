import '../models/payment.dart';

/// Real payment transaction history — starts empty until connected to a
/// backend.
final List<PaymentTransaction> kPayments = <PaymentTransaction>[];

/// Returns the payment transaction for [orderId], or null if none exists.
PaymentTransaction? findPaymentByOrderId(String orderId) {
  for (final p in kPayments) {
    if (p.orderId == orderId) return p;
  }
  return null;
}
