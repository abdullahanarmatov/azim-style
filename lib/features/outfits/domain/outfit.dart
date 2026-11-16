import '../../catalog/domain/product.dart';

/// A ready-made look assembled by the stylist from catalog products.
class Outfit {
  const Outfit({
    required this.id,
    required this.title,
    required this.occasion,
    required this.products,
    this.note = '',
    this.coverUrl,
  });

  final String id;
  final String title;
  final String occasion;
  final List<Product> products;
  final String note;
  final String? coverUrl;

  int get totalPrice => products.fold(0, (sum, p) => sum + p.price);

  factory Outfit.fromJson(Map<String, dynamic> json) => Outfit(
        id: json['id'] as String,
        title: json['title'] as String,
        occasion: (json['occasion'] as String?) ?? '',
        note: (json['note'] as String?) ?? '',
        coverUrl: json['cover_url'] as String?,
        // Supabase nested select: outfit_items(products(*))
        products: [
          for (final item in (json['outfit_items'] as List? ?? const []))
            Product.fromJson(
                (item as Map<String, dynamic>)['products'] as Map<String, dynamic>),
        ],
      );
}
