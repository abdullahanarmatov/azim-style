import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/money.dart';
import '../../../core/widgets/product_image.dart';
import '../../../core/widgets/state_views.dart';
import '../data/cart_controller.dart';
import '../domain/cart_item.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Корзина')),
      body: items.isEmpty
          ? MessageView(
              icon: Icons.shopping_bag_outlined,
              title: 'Корзина пуста',
              message: 'Загляните в готовые образы или пройдите анкету — '
                  'подберём вещи под вас.',
              actionLabel: 'Подобрать образ',
              onAction: () => context.push('/quiz'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 32),
              itemBuilder: (_, i) => _CartLine(item: items[i]),
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text('Итого', style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        Text(formatMoney(total),
                            style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.push('/checkout'),
                      child: const Text('Оформить заказ'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CartLine extends ConsumerWidget {
  const _CartLine({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cart = ref.read(cartProvider.notifier);
    final p = item.product;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 84, height: 104, child: ProductImage(product: p, borderRadius: 12)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.title, style: theme.textTheme.bodyLarge),
              Text('Размер ${item.size}', style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(formatMoney(item.subtotal), style: theme.textTheme.titleSmall),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Меньше',
                    onPressed: () => cart.setQuantity(item.key, item.quantity - 1),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('${item.quantity}', style: theme.textTheme.titleMedium),
                  IconButton(
                    tooltip: 'Больше',
                    onPressed: item.quantity < p.stock
                        ? () => cart.setQuantity(item.key, item.quantity + 1)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Удалить',
                    onPressed: () => cart.remove(item.key),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
