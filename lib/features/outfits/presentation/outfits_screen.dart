import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/money.dart';
import '../../../core/widgets/state_views.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../domain/outfit.dart';
import 'add_look_sheet.dart';
import 'look_strip.dart';

class OutfitsScreen extends ConsumerWidget {
  const OutfitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outfits = ref.watch(outfitsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Готовые образы')),
      body: outfits.when(
        data: (list) => list.isEmpty
            ? const MessageView(
                icon: Icons.style_outlined,
                title: 'Образов пока нет',
                message: 'Стилист готовит новую подборку.',
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(outfitsProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 28),
                  itemBuilder: (_, i) => _OutfitTile(outfit: list[i]),
                ),
              ),
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            Skeleton(height: 220),
            SizedBox(height: 24),
            Skeleton(height: 220),
          ],
        ),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(outfitsProvider)),
      ),
    );
  }
}

class _OutfitTile extends StatelessWidget {
  const _OutfitTile({required this.outfit});
  final Outfit outfit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(outfit.occasion.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.4, color: theme.colorScheme.secondary)),
        const SizedBox(height: 4),
        Text(outfit.title, style: theme.textTheme.headlineSmall),
        if (outfit.note.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(outfit.note, style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: 12),
        LookStrip(products: outfit.products),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text('${outfit.products.length} вещ. · ${formatMoney(outfit.totalPrice)}',
                  style: theme.textTheme.titleSmall),
            ),
            FilledButton.tonal(
              onPressed: () => showAddLookSheet(context,
                  title: outfit.title, products: outfit.products),
              child: const Text('Взять образ'),
            ),
          ],
        ),
      ],
    );
  }
}
