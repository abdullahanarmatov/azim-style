import '../../catalog/domain/product.dart';

class CartItem {
  const CartItem({required this.product, required this.size, this.quantity = 1});

  final Product product;
  final String size;
  final int quantity;

  /// One cart line per product+size combination.
  String get key => '${product.id}::$size';
  int get subtotal => product.price * quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, size: size, quantity: quantity ?? this.quantity);

  Map<String, dynamic> toOrderJson() =>
      {'product_id': product.id, 'size': size, 'quantity': quantity};
}
