import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/domain/product.dart';
import '../domain/cart_item.dart';

final cartProvider =
    NotifierProvider<CartController, List<CartItem>>(CartController.new);

final cartTotalProvider =
    Provider<int>((ref) => ref.watch(cartProvider).fold(0, (s, i) => s + i.subtotal));

final cartCountProvider =
    Provider<int>((ref) => ref.watch(cartProvider).fold(0, (s, i) => s + i.quantity));

class CartController extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => const [];

  /// Adds [product] in [size]; merges with an existing line and never exceeds
  /// available stock. Returns false if nothing could be added.
  bool add(Product product, String size, {int quantity = 1}) {
    if (!product.inStock || quantity <= 0) return false;
    final key = CartItem(product: product, size: size).key;
    final index = state.indexWhere((i) => i.key == key);
    if (index == -1) {
      state = [
        ...state,
        CartItem(product: product, size: size, quantity: quantity.clamp(1, product.stock)),
      ];
      return true;
    }
    final current = state[index];
    final next = (current.quantity + quantity).clamp(1, product.stock);
    if (next == current.quantity) return false;
    state = [...state]..[index] = current.copyWith(quantity: next);
    return true;
  }

  void setQuantity(String key, int quantity) {
    if (quantity <= 0) return remove(key);
    state = [
      for (final i in state)
        if (i.key == key)
          i.copyWith(quantity: quantity.clamp(1, i.product.stock))
        else
          i,
    ];
  }

  void remove(String key) => state = state.where((i) => i.key != key).toList();

  void clear() => state = const [];
}
