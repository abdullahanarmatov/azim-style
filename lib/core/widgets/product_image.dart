import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/catalog/domain/product.dart';
import '../theme/app_colors.dart';

/// Product photo with a calm branded placeholder (no broken-image icons).
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.product, this.borderRadius = 16});

  final Product product;
  final double borderRadius;

  static IconData iconFor(ProductCategory c) => switch (c) {
        ProductCategory.outerwear => Icons.checkroom_outlined,
        ProductCategory.tops => Icons.dry_cleaning_outlined,
        ProductCategory.bottoms => Icons.straighten_outlined,
        ProductCategory.shoes => Icons.ice_skating_outlined,
        ProductCategory.accessories => Icons.watch_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final tint = AppColors.placeholders[
        product.id.hashCode.abs() % AppColors.placeholders.length];
    final placeholder = ColoredBox(
      color: tint,
      child: Center(
        child: Icon(iconFor(product.category),
            size: 40, color: AppColors.ink.withValues(alpha: 0.35)),
      ),
    );
    final url = product.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: url == null || url.isEmpty
          ? placeholder
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, _) => placeholder,
              errorWidget: (_, _, _) => placeholder,
            ),
    );
  }
}
