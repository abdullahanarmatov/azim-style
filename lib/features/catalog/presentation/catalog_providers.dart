import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../outfits/domain/outfit.dart';
import '../data/catalog_repository.dart';
import '../domain/product.dart';

final selectedCategoryProvider =
    NotifierProvider<SelectedCategory, ProductCategory?>(SelectedCategory.new);

class SelectedCategory extends Notifier<ProductCategory?> {
  @override
  ProductCategory? build() => null;
  void select(ProductCategory? c) => state = c;
}

final productsProvider =
    FutureProvider.autoDispose.family<List<Product>, ProductCategory?>(
  (ref, category) =>
      ref.watch(catalogRepositoryProvider).fetchProducts(category: category),
);

final productProvider = FutureProvider.autoDispose.family<Product?, String>(
  (ref, id) => ref.watch(catalogRepositoryProvider).getProduct(id),
);

final outfitsProvider = FutureProvider.autoDispose<List<Outfit>>(
  (ref) => ref.watch(catalogRepositoryProvider).fetchOutfits(),
);
