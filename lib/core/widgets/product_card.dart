import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/catalog/domain/product.dart';
import '../utils/money.dart';
import 'product_image.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '${product.title}, ${formatMoney(product.price)}',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/product/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(tag: 'product-${product.id}', child: ProductImage(product: product)),
                  if (!product.inStock)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Chip(
                        label: const Text('Нет в наличии'),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: theme.colorScheme.surface,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(product.brand.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2, color: theme.colorScheme.onSurfaceVariant)),
            Text(product.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium),
            Text(formatMoney(product.price),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
