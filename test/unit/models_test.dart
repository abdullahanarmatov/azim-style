import 'package:flutter_test/flutter_test.dart';

import 'package:azim_style/core/utils/money.dart';
import 'package:azim_style/features/catalog/data/mock_catalog.dart';
import 'package:azim_style/features/catalog/domain/product.dart';
import 'package:azim_style/features/orders/domain/order.dart';
import 'package:azim_style/features/outfits/domain/outfit.dart';

void main() {
  test('Product survives a JSON round trip', () {
    final p = demoProducts.first;
    final back = Product.fromJson(p.toJson());
    expect(back.title, p.title);
    expect(back.price, p.price);
    expect(back.category, p.category);
    expect(back.sizes, p.sizes);
    expect(back.styleTags, p.styleTags);
  });

  test('Outfit parses Supabase nested select and sums price', () {
    final o = Outfit.fromJson({
      'id': 'o',
      'title': 'T',
      'occasion': 'Работа',
      'outfit_items': [
        {'position': 0, 'products': demoProducts[0].toJson()},
        {'position': 1, 'products': demoProducts[2].toJson()},
      ],
    });
    expect(o.products, hasLength(2));
    expect(o.totalPrice, demoProducts[0].price + demoProducts[2].price);
  });

  test('Order parses status and lines', () {
    final o = Order.fromJson({
      'id': 'abcdef1234',
      'status': 'confirmed',
      'total': 18900,
      'created_at': '2026-11-16T10:00:00Z',
      'order_items': [
        {'title': 'Рубашка', 'size': 'M', 'quantity': 1, 'unit_price': 18900},
      ],
    });
    expect(o.status, OrderStatus.confirmed);
    expect(o.shortId, 'ABCDEF');
    expect(o.lines.single.unitPrice, 18900);
  });

  test('money is formatted with grouping and currency', () {
    expect(formatMoney(24900).replaceAll(RegExp(r'\s'), ' '), '24 900 ₸');
  });
}
