import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../outfits/domain/outfit.dart';
import '../domain/product.dart';
import 'mock_catalog.dart';

abstract interface class CatalogRepository {
  Future<List<Product>> fetchProducts({ProductCategory? category});
  Future<Product?> getProduct(String id);
  Future<List<Outfit>> fetchOutfits();
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  if (Env.hasSupabase) {
    return SupabaseCatalogRepository(Supabase.instance.client);
  }
  return MockCatalogRepository();
});

class SupabaseCatalogRepository implements CatalogRepository {
  SupabaseCatalogRepository(this._db);
  final SupabaseClient _db;

  @override
  Future<List<Product>> fetchProducts({ProductCategory? category}) async {
    var query = _db.from('products').select().eq('is_active', true);
    if (category != null) query = query.eq('category', category.name);
    final rows = await query.order('created_at', ascending: false);
    return rows.map(Product.fromJson).toList();
  }

  @override
  Future<Product?> getProduct(String id) async {
    final row = await _db.from('products').select().eq('id', id).maybeSingle();
    return row == null ? null : Product.fromJson(row);
  }

  @override
  Future<List<Outfit>> fetchOutfits() async {
    final rows = await _db
        .from('outfits')
        .select('*, outfit_items(position, products(*))')
        .eq('is_published', true)
        .order('created_at', ascending: false)
        .order('position', referencedTable: 'outfit_items');
    return rows.map(Outfit.fromJson).toList();
  }
}
