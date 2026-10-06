import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/app_error.dart';
import '../models/payment.dart';

/// READ-ONLY access to the customer's payment records in Supabase.
///
/// A payment row is created by the database itself, inside the same
/// transaction as the order (`place_order`), always as `pending`. The
/// customer roles have no INSERT/UPDATE/DELETE privilege on `payments`, so
/// this app can neither create a payment record nor mark one as paid — a
/// modified client cannot either. A payment only moves past `pending` when a
/// trusted server-side path does it (staff confirming a cash/e-wallet
/// payment, or a payment-gateway webhook running with its own credentials).
///
/// There is deliberately no `recordPayment`/`markStatus` here. Do not add
/// client-side writes: the database will reject them, and they would be the
/// attack surface if it did not.
class PaymentsRepository {
  PaymentsRepository._();
  static final PaymentsRepository instance = PaymentsRepository._();

  SupabaseClient get _client => SupabaseService.instance.client;

  Future<List<PaymentTransaction>> fetchAll(String firebaseUid) async {
    final raw = await _client
        .from('payments')
        .select()
        .eq('firebase_uid', firebaseUid)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(raw).map(PaymentTransaction.fromRow).toList();
  }

  /// Live view of this customer's payments (status changes made by staff or
  /// the payment provider webhook). Each event is the full current list.
  Stream<List<PaymentTransaction>> watchAll(String firebaseUid) {
    return _client
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('firebase_uid', firebaseUid)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(PaymentTransaction.fromRow).toList())
        .transform(StreamTransformer<List<PaymentTransaction>, List<PaymentTransaction>>.fromHandlers(
          handleError: (error, stackTrace, sink) => sink.addError(AppErrors.from(error), stackTrace),
        ));
  }

  /// The single payment for [orderId] (one per order is enforced by a unique
  /// index), or null if there is none / it is not yours.
  Future<PaymentTransaction?> fetchForOrder(String orderId) async {
    final row = await _client.from('payments').select().eq('order_id', orderId).maybeSingle();
    return row == null ? null : PaymentTransaction.fromRow(row);
  }
}
