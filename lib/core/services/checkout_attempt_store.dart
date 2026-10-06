import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/order.dart';
import '../../data/repositories/orders_repository.dart';

/// One checkout attempt: the idempotency key that identifies it to the
/// server, and whether its request has (possibly) left the device.
class CheckoutAttempt {
  final String key;
  final String uid;
  final String cartId;
  final DateTime createdAt;

  /// True once the `place_order` request was sent. From then until the
  /// server's answer is known, the outcome is UNKNOWN — the order may or may
  /// not exist — and the attempt must survive an app restart.
  final bool submitted;

  const CheckoutAttempt({
    required this.key,
    required this.uid,
    required this.cartId,
    required this.createdAt,
    this.submitted = false,
  });

  CheckoutAttempt copyWith({bool? submitted}) => CheckoutAttempt(
        key: key,
        uid: uid,
        cartId: cartId,
        createdAt: createdAt,
        submitted: submitted ?? this.submitted,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'uid': uid,
        'cartId': cartId,
        'createdAt': createdAt.toIso8601String(),
        'submitted': submitted,
      };

  factory CheckoutAttempt.fromJson(Map<String, dynamic> json) => CheckoutAttempt(
        key: json['key'] as String,
        uid: json['uid'] as String,
        cartId: json['cartId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        submitted: json['submitted'] as bool? ?? false,
      );
}

/// Makes "Place Order" safe to retry — including after the connection
/// drops mid-request or the app is killed — without ever creating two
/// orders or claiming an order that the server did not accept.
///
/// How:
///  1. [begin] hands out ONE idempotency key per (customer, cart) and saves
///     it to disk. Every retry for that cart reuses the same key, and the
///     `place_order` database function returns the existing order for a key
///     it has already seen instead of creating another.
///  2. [markSubmitted] is called right before the request is sent.
///  3. On success [clear] is called. On a definitive server rejection
///     [clear] is called too (nothing was created; a later attempt is new).
///     On a transient failure the attempt is KEPT — the outcome is unknown.
///  4. [resolveUnconfirmed] runs whenever customer data loads while online:
///     if a submitted attempt exists it asks the server whether an order with
///     that key exists. If yes, the order really was accepted (see
///     [recoveredOrder]); if not, nothing was placed and a retry with the
///     same key remains safe.
class CheckoutAttemptStore extends ChangeNotifier {
  CheckoutAttemptStore._();
  static final CheckoutAttemptStore instance = CheckoutAttemptStore._();

  static const String _storageKey = 'melai_checkout_attempt_v1';
  static const Duration _maxAge = Duration(hours: 24);

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  /// Set when an earlier, unconfirmed checkout turned out to have been
  /// accepted by the server. The UI shows it once, then [dismissRecovered].
  Order? recoveredOrder;

  Future<CheckoutAttempt?> _read() async {
    try {
      final raw = await _prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return null;
      return CheckoutAttempt.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(CheckoutAttempt attempt) async {
    try {
      await _prefs.setString(_storageKey, jsonEncode(attempt.toJson()));
    } catch (_) {
      // If the disk write fails the attempt still works for this session.
    }
  }

  /// The attempt to use for [cartId]: the saved one if it belongs to this
  /// customer and cart and is recent, otherwise a brand-new key.
  Future<CheckoutAttempt> begin({required String uid, required String cartId}) async {
    final existing = await _read();
    if (existing != null &&
        existing.uid == uid &&
        existing.cartId == cartId &&
        DateTime.now().difference(existing.createdAt) < _maxAge) {
      return existing;
    }
    final fresh = CheckoutAttempt(
      key: _newKey(),
      uid: uid,
      cartId: cartId,
      createdAt: DateTime.now(),
    );
    await _write(fresh);
    return fresh;
  }

  Future<void> markSubmitted(CheckoutAttempt attempt) => _write(attempt.copyWith(submitted: true));

  Future<void> clear() async {
    try {
      await _prefs.remove(_storageKey);
    } catch (_) {}
  }

  /// Settles a checkout whose outcome was never seen. Only call while
  /// online. Throws if the server can't be reached (the attempt is kept).
  Future<void> resolveUnconfirmed(String uid) async {
    final attempt = await _read();
    if (attempt == null) return;
    if (attempt.uid != uid || DateTime.now().difference(attempt.createdAt) >= _maxAge) {
      await clear();
      return;
    }
    if (!attempt.submitted) return;

    final order = await OrdersRepository.instance.findByIdempotencyKey(uid, attempt.key);
    if (order == null) return; // never accepted; a same-key retry is safe
    await clear();
    recoveredOrder = order;
    notifyListeners();
  }

  void dismissRecovered() {
    if (recoveredOrder == null) return;
    recoveredOrder = null;
    notifyListeners();
  }

  /// Forget everything (sign-out).
  Future<void> reset() async {
    recoveredOrder = null;
    await clear();
    notifyListeners();
  }

  String _newKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return 'co-${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
  }
}
