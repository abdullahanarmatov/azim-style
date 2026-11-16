import 'package:flutter_test/flutter_test.dart';

import 'package:azim_style/features/catalog/data/mock_catalog.dart';
import 'package:azim_style/features/catalog/domain/product.dart';
import 'package:azim_style/features/quiz/domain/recommendation_engine.dart';
import 'package:azim_style/features/quiz/domain/style_profile.dart';

void main() {
  Product byId(String id) => demoProducts.firstWhere((p) => p.id == id);

  test('every look fits the budget and uses only in-stock items', () {
    const profile = StyleProfile(
        gender: 'male', occasions: {'work'}, styles: {'classic'}, budget: 120000);
    final rec = recommendLocally(profile, demoProducts);

    expect(rec.looks, isNotEmpty);
    for (final look in rec.looks) {
      final items = look.productIds.map(byId).toList();
      expect(items.fold(0, (s, p) => s + p.price), lessThanOrEqualTo(120000));
      expect(items.every((p) => p.inStock), isTrue);
      expect(items.map((p) => p.category),
          containsAll([ProductCategory.tops, ProductCategory.bottoms, ProductCategory.shoes]));
    }
  });

  test('prefers items matching the chosen style', () {
    const profile = StyleProfile(
        gender: 'male', occasions: {'everyday'}, styles: {'street'}, budget: 1000000);
    final first = recommendLocally(profile, demoProducts).looks.first;
    final tags = first.productIds.map(byId).expand((p) => p.styleTags);
    expect(tags.where((t) => t == 'street').length, greaterThanOrEqualTo(2));
  });

  test('looks differ from each other', () {
    const profile = StyleProfile(
        gender: 'male', occasions: {'work'}, styles: {'minimal'}, budget: 1000000);
    final looks = recommendLocally(profile, demoProducts).looks;
    expect(looks.length, greaterThan(1));
    expect(looks[0].productIds.toSet(), isNot(equals(looks[1].productIds.toSet())));
  });

  test('returns a helpful message when nothing fits', () {
    const profile = StyleProfile(
        gender: 'male', occasions: {'work'}, styles: {'classic'}, budget: 1000);
    final rec = recommendLocally(profile, demoProducts);
    expect(rec.looks, isEmpty);
    expect(rec.summary, contains('стилисту'));
  });
}
