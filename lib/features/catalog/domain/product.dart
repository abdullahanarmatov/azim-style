enum ProductCategory {
  outerwear('Верхняя одежда'),
  tops('Верх'),
  bottoms('Низ'),
  shoes('Обувь'),
  accessories('Аксессуары');

  const ProductCategory(this.label);
  final String label;

  static ProductCategory parse(String value) => ProductCategory.values
      .firstWhere((c) => c.name == value, orElse: () => ProductCategory.tops);
}

class Product {
  const Product({
    required this.id,
    required this.title,
    required this.brand,
    required this.price,
    required this.category,
    required this.sizes,
    required this.stock,
    this.description = '',
    this.imageUrl,
    this.styleTags = const [],
    this.colors = const [],
  });

  final String id;
  final String title;
  final String brand;

  /// Whole currency units (no cents) to avoid float rounding.
  final int price;
  final ProductCategory category;
  final List<String> sizes;
  final int stock;
  final String description;
  final String? imageUrl;
  final List<String> styleTags;
  final List<String> colors;

  bool get inStock => stock > 0;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        title: json['title'] as String,
        brand: (json['brand'] as String?) ?? '',
        price: (json['price'] as num).toInt(),
        category: ProductCategory.parse(json['category'] as String),
        sizes: List<String>.from(json['sizes'] as List? ?? const []),
        stock: (json['stock'] as num?)?.toInt() ?? 0,
        description: (json['description'] as String?) ?? '',
        imageUrl: json['image_url'] as String?,
        styleTags: List<String>.from(json['style_tags'] as List? ?? const []),
        colors: List<String>.from(json['colors'] as List? ?? const []),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'brand': brand,
        'price': price,
        'category': category.name,
        'sizes': sizes,
        'stock': stock,
        'description': description,
        'image_url': imageUrl,
        'style_tags': styleTags,
        'colors': colors,
      };

  @override
  bool operator ==(Object other) => other is Product && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
