import '../../../core/utils/money.dart';
import '../../catalog/domain/product.dart';
import 'quiz_options.dart';
import 'style_profile.dart';

/// Deterministic, offline look builder.
///
/// Used in demo mode and as a fallback when the AI stylist is unreachable,
/// so the client always gets an answer instead of an error.
Recommendation recommendLocally(
  StyleProfile profile,
  List<Product> catalog, {
  int maxLooks = 3,
}) {
  final budget = profile.budget ?? 1 << 30;
  final available = catalog.where((p) => p.inStock).toList();

  int score(Product p) =>
      2 * p.styleTags.where(profile.styles.contains).length +
      p.colors.where(profile.colors.contains).length;

  List<Product> best(ProductCategory c) {
    final list = available.where((p) => p.category == c).toList()
      ..sort((a, b) {
        final s = score(b).compareTo(score(a));
        return s != 0 ? s : a.price.compareTo(b.price);
      });
    return list.take(4).toList();
  }

  final tops = best(ProductCategory.tops);
  final bottoms = best(ProductCategory.bottoms);
  final shoes = best(ProductCategory.shoes);

  final combos = <({List<Product> items, int score, int total})>[];
  for (final t in tops) {
    for (final b in bottoms) {
      for (final s in shoes) {
        final items = [t, b, s];
        final total = t.price + b.price + s.price;
        if (total <= budget) {
          combos.add((items: items, score: items.fold(0, (a, p) => a + score(p)), total: total));
        }
      }
    }
  }
  combos.sort((a, b) {
    final s = b.score.compareTo(a.score);
    return s != 0 ? s : a.total.compareTo(b.total);
  });

  // Prefer looks that differ from each other in at least two pieces.
  final chosen = <List<Product>>[];
  for (final c in combos) {
    if (chosen.length >= maxLooks) break;
    final distinct = chosen.every(
        (prev) => c.items.where((p) => !prev.contains(p)).length >= 2);
    if (distinct) chosen.add(List.of(c.items));
  }

  // Top up with outerwear when the budget allows it.
  final outer = best(ProductCategory.outerwear);
  for (final look in chosen) {
    final spent = look.fold(0, (a, p) => a + p.price);
    for (final o in outer) {
      if (spent + o.price <= budget && score(o) > 0) {
        look.insert(0, o);
        break;
      }
    }
  }

  final styleNames = profile.styles.map(QuizOptions.styleLabel).join(', ');
  final looks = [
    for (var i = 0; i < chosen.length; i++)
      RecommendedLook(
        title: _titles[i % _titles.length],
        reason: 'Под ваш стиль${styleNames.isEmpty ? '' : ': ${styleNames.toLowerCase()}'}'
            ' · итого ${formatMoney(chosen[i].fold(0, (a, p) => a + p.price))}',
        productIds: chosen[i].map((p) => p.id).toList(),
      ),
  ];

  return Recommendation(
    summary: looks.isEmpty
        ? 'Под этот бюджет готовых образов пока нет. Напишите стилисту — он '
            'подберёт вещи вручную.'
        : 'Собрали ${looks.length} ${_plural(looks.length)} из того, что есть '
            'в наличии. Стилист проверит подбор и ответит в чате.',
    looks: looks,
  );
}

const _titles = ['Основной образ', 'Альтернатива', 'Смелый вариант'];

String _plural(int n) => switch (n) {
      1 => 'образ',
      2 || 3 || 4 => 'образа',
      _ => 'образов',
    };
