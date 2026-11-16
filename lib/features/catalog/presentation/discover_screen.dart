import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/config/brand.dart';
import '../../../core/config/env.dart';
import '../../../core/utils/links.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/stylist_avatar.dart';
import '../domain/product.dart';
import 'catalog_providers.dart';

const _gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 220,
  mainAxisSpacing: 20,
  crossAxisSpacing: 12,
  childAspectRatio: 0.62,
);

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(selectedCategoryProvider);
    final products = ref.watch(productsProvider(category));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(productsProvider(category).future),
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(floating: true, title: Text(Brand.appName)),
            if (!Env.hasSupabase)
              const SliverToBoxAdapter(child: _DemoBanner()),
            const SliverToBoxAdapter(child: _StylistHero()),
            SliverToBoxAdapter(child: _CategoryBar(selected: category)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: products.when(
                data: (items) => items.isEmpty
                    ? const SliverFillRemaining(
                        hasScrollBody: false,
                        child: MessageView(
                          icon: Icons.inventory_2_outlined,
                          title: 'Здесь пока пусто',
                          message: 'Новые поступления скоро появятся.',
                        ),
                      )
                    : SliverGrid.builder(
                        gridDelegate: _gridDelegate,
                        itemCount: items.length,
                        itemBuilder: (_, i) => ProductCard(product: items[i]),
                      ),
                loading: () => SliverGrid.builder(
                  gridDelegate: _gridDelegate,
                  itemCount: 6,
                  itemBuilder: (_, _) => const Skeleton(),
                ),
                error: (e, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorView(
                    error: e,
                    onRetry: () => ref.invalidate(productsProvider(category)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(
          'Демо-режим: данные тестовые, заказы не отправляются.',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
}

class _StylistHero extends StatelessWidget {
  const _StylistHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Card(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const StylistAvatar(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(Brand.stylistName, style: theme.textTheme.titleMedium),
                        Text(Brand.stylistTagline,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Instagram ${Brand.instagramHandle}',
                    onPressed: openInstagram,
                    icon: const Icon(Icons.camera_alt_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Соберу образ под вас за 2 минуты',
                  style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('Ответьте на 6 вопросов — получите готовые луки из того, '
                  'что есть в наличии, с ценами.',
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.push('/quiz'),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Подобрать образ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBar extends ConsumerWidget {
  const _CategoryBar({required this.selected});
  final ProductCategory? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(selectedCategoryProvider.notifier);
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip('Все', selected == null, () => notifier.select(null)),
          for (final c in ProductCategory.values)
            _chip(c.label, selected == c, () => notifier.select(c)),
        ],
      ),
    );
  }

  Widget _chip(String label, bool on, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(label: Text(label), selected: on, onSelected: (_) => onTap()),
      );
}
