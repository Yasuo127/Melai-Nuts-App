import '../models/order.dart';

/// Real order history — starts empty until connected to a backend.
final List<Order> kOrders = <Order>[];

/// The customer's current in-progress order, or null if none is active.
Order? get activeOrder {
  for (final order in kOrders) {
    if (order.status.isActive) return order;
  }
  return null;
}
