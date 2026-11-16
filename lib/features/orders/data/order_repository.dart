import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../cart/domain/cart_item.dart';
import '../domain/order.dart';

abstract interface class OrderRepository {
  /// Returns the new order id. Prices and stock are re-checked on the server.
  Future<String> placeOrder(List<CartItem> items, CheckoutDetails details);
  Future<List<Order>> myOrders();
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  if (Env.hasSupabase) return SupabaseOrderRepository(Supabase.instance.client);
  return MockOrderRepository();
});

final myOrdersProvider = FutureProvider.autoDispose<List<Order>>(
  (ref) => ref.watch(orderRepositoryProvider).myOrders(),
);

class SupabaseOrderRepository implements OrderRepository {
  SupabaseOrderRepository(this._db);
  final SupabaseClient _db;

  @override
  Future<String> placeOrder(List<CartItem> items, CheckoutDetails d) async {
    final id = await _db.rpc<String>('place_order', params: {
      'p_items': items.map((i) => i.toOrderJson()).toList(),
      'p_name': d.name,
      'p_phone': d.phone,
      'p_address': d.address,
      'p_comment': d.comment,
    });
    return id;
  }

  @override
  Future<List<Order>> myOrders() async {
    final rows = await _db
        .from('orders')
        .select('*, order_items(*)')
        .order('created_at', ascending: false);
    return rows.map(Order.fromJson).toList();
  }
}

class MockOrderRepository implements OrderRepository {
  final _orders = <Order>[];

  @override
  Future<String> placeOrder(List<CartItem> items, CheckoutDetails d) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final id = 'demo${(_orders.length + 1).toString().padLeft(4, '0')}';
    _orders.insert(
      0,
      Order(
        id: id,
        status: OrderStatus.pending,
        total: items.fold(0, (s, i) => s + i.subtotal),
        createdAt: DateTime.now(),
        address: d.address,
        phone: d.phone,
        comment: d.comment,
        lines: [
          for (final i in items)
            OrderLine(
              title: i.product.title,
              size: i.size,
              quantity: i.quantity,
              unitPrice: i.product.price,
            ),
        ],
      ),
    );
    return id;
  }

  @override
  Future<List<Order>> myOrders() async => List.unmodifiable(_orders);
}
