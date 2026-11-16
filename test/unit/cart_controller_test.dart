import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:azim_style/features/cart/data/cart_controller.dart';
import 'package:azim_style/features/catalog/data/mock_catalog.dart';

void main() {
  late ProviderContainer c;
  final shirt = demoProducts.firstWhere((p) => p.id == 'p3'); // stock 12
  final loafers = demoProducts.firstWhere((p) => p.id == 'p10'); // stock 3
  final hoodie = demoProducts.firstWhere((p) => p.id == 'p6'); // stock 0

  setUp(() {
    c = ProviderContainer();
    addTearDown(c.dispose);
  });

  CartController cart() => c.read(cartProvider.notifier);

  test('merges same product and size into one line', () {
    cart().add(shirt, 'M');
    cart().add(shirt, 'M');
    cart().add(shirt, 'L');
    final items = c.read(cartProvider);
    expect(items, hasLength(2));
    expect(items.first.quantity, 2);
    expect(c.read(cartCountProvider), 3);
    expect(c.read(cartTotalProvider), shirt.price * 3);
  });

  test('never exceeds stock', () {
    cart().add(loafers, '42', quantity: 2);
    expect(cart().add(loafers, '42', quantity: 5), isTrue);
    expect(c.read(cartProvider).single.quantity, 3);
    expect(cart().add(loafers, '42'), isFalse);
  });

  test('rejects out-of-stock products', () {
    expect(cart().add(hoodie, 'M'), isFalse);
    expect(c.read(cartProvider), isEmpty);
  });

  test('setQuantity to zero removes the line; clear empties cart', () {
    cart().add(shirt, 'M');
    cart().add(loafers, '42');
    cart().setQuantity(c.read(cartProvider).first.key, 0);
    expect(c.read(cartProvider).single.product, loafers);
    cart().clear();
    expect(c.read(cartTotalProvider), 0);
  });
}
