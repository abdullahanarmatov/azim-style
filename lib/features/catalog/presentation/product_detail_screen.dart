import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/product_image.dart';
import '../../../core/widgets/state_views.dart';
import '../../cart/data/cart_controller.dart';
import '../domain/product.dart';
import 'catalog_providers.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productProvider(productId));
    return Scaffold(
      appBar: AppBar(),
      body: product.when(
        data: (p) => p == null
            ? const MessageView(
                icon: Icons.search_off_rounded,
                title: 'Товар не найден',
                message: 'Возможно, его уже сняли с продажи.',
              )
            : _ProductBody(product: p),
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Skeleton(height: 420),
        ),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(productProvider(productId)),
        ),
      ),
    );
  }
}

class _ProductBody extends ConsumerStatefulWidget {
  const _ProductBody({required this.product});
  final Product product;

  @override
  ConsumerState<_ProductBody> createState() => _ProductBodyState();
}

class _ProductBodyState extends ConsumerState<_ProductBody> {
  String? _size;

  @override
  void initState() {
    super.initState();
    if (widget.product.sizes.length == 1) _size = widget.product.sizes.first;
  }

  void _addToCart() {
    final p = widget.product;
    final added = ref.read(cartProvider.notifier).add(p, _size!);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(added
          ? 'Добавлено в корзину'
          : 'В корзине уже всё, что есть в наличии'),
      action: added
          ? SnackBarAction(label: 'Корзина', onPressed: () => context.go('/cart'))
          : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final theme = Theme.of(context);
    final lowStock = p.inStock && p.stock <= 3;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              AspectRatio(
                aspectRatio: 4 / 5,
                child: Hero(tag: 'product-${p.id}', child: ProductImage(product: p)),
              ),
              const SizedBox(height: 16),
              Text(p.brand.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 1.4)),
              const SizedBox(height: 4),
              Text(p.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(formatMoney(p.price), style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              _StockLine(product: p, low: lowStock),
              const SizedBox(height: 20),
              Text('Размер', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in p.sizes)
                    ChoiceChip(
                      label: Text(s),
                      selected: _size == s,
                      onSelected: p.inStock ? (_) => setState(() => _size = s) : null,
                    ),
                ],
              ),
              if (p.description.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(p.description, style: theme.textTheme.bodyLarge),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push(Uri(
                      path: '/chat',
                      queryParameters: {
                        'text': 'Здравствуйте! Интересует «${p.title}». '
                            'Подойдёт ли мне и с чем носить?',
                      },
                    ).toString()),
                    child: const Text('Спросить'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: p.inStock && _size != null ? _addToCart : null,
                    child: Text(!p.inStock
                        ? 'Нет в наличии'
                        : _size == null
                            ? 'Выберите размер'
                            : 'В корзину'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StockLine extends StatelessWidget {
  const _StockLine({required this.product, required this.low});
  final Product product;
  final bool low;

  @override
  Widget build(BuildContext context) {
    final (icon, text, color) = !product.inStock
        ? (Icons.cancel_outlined, 'Нет в наличии', AppColors.danger)
        : low
            ? (Icons.local_fire_department_outlined,
                'Осталось ${product.stock} шт.', AppColors.camel)
            : (Icons.check_circle_outline, 'В наличии', AppColors.success);
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
