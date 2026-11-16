import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/money.dart';
import '../../../core/widgets/product_image.dart';
import '../../cart/data/cart_controller.dart';
import '../../catalog/domain/product.dart';

/// Lets the client pick a size per item and add a whole look in one tap.
Future<void> showAddLookSheet(
  BuildContext context, {
  required String title,
  required List<Product> products,
  String? preferredSize,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AddLookSheet(
          title: title, products: products, preferredSize: preferredSize),
    );

class _AddLookSheet extends ConsumerStatefulWidget {
  const _AddLookSheet({required this.title, required this.products, this.preferredSize});
  final String title;
  final List<Product> products;
  final String? preferredSize;

  @override
  ConsumerState<_AddLookSheet> createState() => _AddLookSheetState();
}

class _AddLookSheetState extends ConsumerState<_AddLookSheet> {
  late final Map<String, String> _sizes = {
    for (final p in widget.products.where((p) => p.inStock))
      p.id: p.sizes.contains(widget.preferredSize) ? widget.preferredSize! : p.sizes.first,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = widget.products.where((p) => p.inStock).toList();
    final total = items.fold(0, (s, p) => s + p.price);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(widget.title, style: theme.textTheme.titleLarge),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (_, i) {
                  final p = items[i];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 64, height: 80, child: ProductImage(product: p, borderRadius: 10)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.title, style: theme.textTheme.bodyLarge),
                            Text(formatMoney(p.price), style: theme.textTheme.bodySmall),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final s in p.sizes)
                                  ChoiceChip(
                                    visualDensity: VisualDensity.compact,
                                    label: Text(s),
                                    selected: _sizes[p.id] == s,
                                    onSelected: (_) => setState(() => _sizes[p.id] = s),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FilledButton(
                onPressed: items.isEmpty
                    ? null
                    : () {
                        final cart = ref.read(cartProvider.notifier);
                        for (final p in items) {
                          cart.add(p, _sizes[p.id]!);
                        }
                        final router = GoRouter.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.of(context).pop();
                        messenger.showSnackBar(SnackBar(
                          content: Text('Образ добавлен: ${items.length} вещ.'),
                          action: SnackBarAction(
                              label: 'Корзина', onPressed: () => router.go('/cart')),
                        ));
                      },
                child: Text('Добавить образ · ${formatMoney(total)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
