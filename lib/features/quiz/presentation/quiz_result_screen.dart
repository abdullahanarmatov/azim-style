import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/money.dart';
import '../../../core/widgets/state_views.dart';
import '../../catalog/domain/product.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../../outfits/presentation/add_look_sheet.dart';
import '../../outfits/presentation/look_strip.dart';
import '../domain/style_profile.dart';
import 'quiz_providers.dart';

class QuizResultScreen extends ConsumerWidget {
  const QuizResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(recommendationProvider);
    final catalog = ref.watch(productsProvider(null));

    return Scaffold(
      appBar: AppBar(title: const Text('Ваши образы')),
      body: switch ((result, catalog)) {
        (AsyncData(value: final rec), AsyncData(value: final products)) =>
          _ResultBody(recommendation: rec, catalog: products),
        (AsyncError(:final error), _) || (_, AsyncError(:final error)) => ErrorView(
            error: error,
            onRetry: () {
              ref.invalidate(recommendationProvider);
              ref.invalidate(productsProvider(null));
            },
          ),
        _ => const _Thinking(),
      },
    );
  }
}

class _Thinking extends StatelessWidget {
  const _Thinking();

  @override
  Widget build(BuildContext context) => const MessageView(
        icon: Icons.auto_awesome_outlined,
        title: 'Подбираем образы…',
        message: 'Смотрим наличие, размеры и бюджет',
      );
}

class _ResultBody extends ConsumerWidget {
  const _ResultBody({required this.recommendation, required this.catalog});
  final Recommendation recommendation;
  final List<Product> catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final byId = {for (final p in catalog) p.id: p};
    final size = ref.read(quizProvider).topSize;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(recommendation.summary, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 24),
        for (final look in recommendation.looks)
          Builder(builder: (context) {
            final items = [
              for (final id in look.productIds) ?byId[id],
            ];
            if (items.isEmpty) return const SizedBox.shrink();
            final total = items.fold(0, (s, p) => s + p.price);
            return Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(look.title, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(look.reason, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  LookStrip(products: items),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: Text(formatMoney(total), style: theme.textTheme.titleMedium)),
                      FilledButton.tonal(
                        onPressed: () => showAddLookSheet(context,
                            title: look.title, products: items, preferredSize: size),
                        child: const Text('Взять образ'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        OutlinedButton.icon(
          onPressed: () => context.push(Uri(path: '/chat', queryParameters: {
            'text': 'Прошёл анкету. Помогите выбрать между образами: '
                '${recommendation.looks.map((l) => l.title).join(', ')}.',
          }).toString()),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Обсудить со стилистом'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            ref.read(quizProvider.notifier).reset();
            context.pop();
          },
          child: const Text('Пройти анкету заново'),
        ),
      ],
    );
  }
}
