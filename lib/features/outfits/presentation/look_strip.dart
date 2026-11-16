import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/product_image.dart';
import '../../catalog/domain/product.dart';

/// Horizontal strip of the pieces that make up a look.
class LookStrip extends StatelessWidget {
  const LookStrip({super.key, required this.products, this.height = 150});
  final List<Product> products;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: products.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) => AspectRatio(
            aspectRatio: 0.78,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push('/product/${products[i].id}'),
              child: ProductImage(product: products[i], borderRadius: 12),
            ),
          ),
        ),
      );
}
