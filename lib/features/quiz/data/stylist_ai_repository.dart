import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../catalog/data/catalog_repository.dart';
import '../domain/recommendation_engine.dart';
import '../domain/style_profile.dart';

abstract interface class StylistAiRepository {
  Future<Recommendation> recommend(StyleProfile profile);
}

final stylistAiRepositoryProvider = Provider<StylistAiRepository>((ref) {
  final local = LocalStylistAi(ref.watch(catalogRepositoryProvider));
  if (!Env.hasSupabase) return local;
  return SupabaseStylistAi(Supabase.instance.client, fallback: local);
});

/// Rule-based recommendations from the current catalog.
class LocalStylistAi implements StylistAiRepository {
  LocalStylistAi(this._catalog);
  final CatalogRepository _catalog;

  @override
  Future<Recommendation> recommend(StyleProfile profile) async =>
      recommendLocally(profile, await _catalog.fetchProducts());
}

/// Calls the `ai-stylist` Edge Function (Claude on the server side; the API
/// key never ships inside the app). Falls back to [LocalStylistAi] on error.
class SupabaseStylistAi implements StylistAiRepository {
  SupabaseStylistAi(this._db, {required this.fallback});
  final SupabaseClient _db;
  final StylistAiRepository fallback;

  @override
  Future<Recommendation> recommend(StyleProfile profile) async {
    try {
      final res = await _db.functions
          .invoke('ai-stylist', body: {'profile': profile.toJson()});
      final data = res.data as Map<String, dynamic>;
      final looks = [
        for (final l in data['looks'] as List)
          RecommendedLook.fromJson(l as Map<String, dynamic>),
      ];
      if (looks.isEmpty) return await fallback.recommend(profile);
      return Recommendation(summary: data['summary'] as String, looks: looks);
    } catch (e) {
      debugPrint('ai-stylist failed, using local fallback: $e');
      return await fallback.recommend(profile);
    }
  }
}
