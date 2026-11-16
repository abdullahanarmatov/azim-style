import '../../outfits/domain/outfit.dart';
import '../domain/product.dart';
import 'catalog_repository.dart';

/// Demo catalog used when no backend is configured.
class MockCatalogRepository implements CatalogRepository {
  MockCatalogRepository({this.latency = const Duration(milliseconds: 350)});

  final Duration latency;

  @override
  Future<List<Product>> fetchProducts({ProductCategory? category}) async {
    await Future<void>.delayed(latency);
    return category == null
        ? demoProducts
        : demoProducts.where((p) => p.category == category).toList();
  }

  @override
  Future<Product?> getProduct(String id) async {
    await Future<void>.delayed(latency);
    for (final p in demoProducts) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<List<Outfit>> fetchOutfits() async {
    await Future<void>.delayed(latency);
    return demoOutfits;
  }
}

Product _p(String id, String title, String brand, int price,
        ProductCategory c, List<String> sizes, int stock, List<String> tags,
        List<String> colors, String description) =>
    Product(
      id: id,
      title: title,
      brand: brand,
      price: price,
      category: c,
      sizes: sizes,
      stock: stock,
      styleTags: tags,
      colors: colors,
      description: description,
    );

const _apparel = ['S', 'M', 'L', 'XL'];
const _shoes = ['40', '41', '42', '43', '44'];
const _one = ['One size'];

final demoProducts = <Product>[
  _p('p1', 'Пальто из шерсти', 'Atelier', 89900, ProductCategory.outerwear,
      _apparel, 4, ['classic', 'minimal', 'smart'], ['camel', 'beige'],
      'Прямой силуэт, 80% шерсть. Закрывает сезон с октября по март.'),
  _p('p2', 'Бомбер нейлоновый', 'Urban Line', 42900, ProductCategory.outerwear,
      _apparel, 6, ['street', 'casual'], ['black'],
      'Лёгкий утеплитель, трикотажные манжеты.'),
  _p('p3', 'Оксфорд-рубашка', 'Atelier', 18900, ProductCategory.tops,
      _apparel, 12, ['classic', 'smart', 'casual'], ['white', 'blue'],
      'Плотный хлопок, носится и с брюками, и с джинсами.'),
  _p('p4', 'Водолазка тонкая', 'Merino Co', 22900, ProductCategory.tops,
      _apparel, 8, ['minimal', 'smart', 'classic'], ['black', 'beige'],
      'Мериносовая шерсть, не колется, держит форму.'),
  _p('p5', 'Футболка оверсайз', 'Urban Line', 9900, ProductCategory.tops,
      _apparel, 20, ['street', 'casual', 'minimal'], ['white', 'black'],
      'Плотный хлопок 240 г/м², спущенное плечо.'),
  _p('p6', 'Худи с начёсом', 'Urban Line', 24900, ProductCategory.tops,
      _apparel, 0, ['street', 'casual'], ['grey'],
      'Временно нет в наличии — стилист подберёт аналог.'),
  _p('p7', 'Брюки со стрелками', 'Atelier', 27900, ProductCategory.bottoms,
      ['46', '48', '50', '52'], 7, ['classic', 'smart', 'minimal'],
      ['grey', 'black'], 'Шерстяная смесь, посадка regular.'),
  _p('p8', 'Джинсы прямые', 'Denim Lab', 25900, ProductCategory.bottoms,
      ['30', '31', '32', '33', '34'], 10, ['casual', 'street', 'classic'],
      ['blue'], 'Неэластичный деним 13 oz.'),
  _p('p9', 'Карго-брюки', 'Urban Line', 21900, ProductCategory.bottoms,
      _apparel, 5, ['street', 'casual'], ['black', 'khaki'],
      'Свободный крой, регулируемый низ.'),
  _p('p10', 'Лоферы кожаные', 'Atelier', 45900, ProductCategory.shoes,
      _shoes, 3, ['classic', 'smart', 'minimal'], ['black', 'brown'],
      'Гладкая кожа, кожаная подкладка.'),
  _p('p11', 'Кеды белые', 'Court', 29900, ProductCategory.shoes, _shoes, 9,
      ['casual', 'minimal', 'street'], ['white'],
      'Минималистичные кеды, подходят почти ко всему.'),
  _p('p12', 'Кожаный ремень', 'Atelier', 12900, ProductCategory.accessories,
      _one, 15, ['classic', 'smart', 'minimal'], ['black', 'brown'],
      'Матовая пряжка, ширина 3 см.'),
];

Product _byId(String id) => demoProducts.firstWhere((p) => p.id == id);

final demoOutfits = <Outfit>[
  Outfit(
    id: 'o1',
    title: 'Офис без галстука',
    occasion: 'Работа',
    note: 'Собранно, но не формально — для встреч и переговоров.',
    products: [_byId('p4'), _byId('p7'), _byId('p10'), _byId('p12')],
  ),
  Outfit(
    id: 'o2',
    title: 'Город на выходных',
    occasion: 'Повседневно',
    note: 'База, которая сочетается со всем гардеробом.',
    products: [_byId('p3'), _byId('p8'), _byId('p11')],
  ),
  Outfit(
    id: 'o3',
    title: 'Стритвир вечер',
    occasion: 'Встреча с друзьями',
    note: 'Объём сверху, удобный низ.',
    products: [_byId('p2'), _byId('p5'), _byId('p9'), _byId('p11')],
  ),
  Outfit(
    id: 'o4',
    title: 'Холодный сезон',
    occasion: 'Свидание',
    note: 'Пальто цвета кэмел делает образ дороже.',
    products: [_byId('p1'), _byId('p4'), _byId('p8'), _byId('p10')],
  ),
];
