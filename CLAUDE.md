# AZIM STYLE — app for a personal stylist

Flutter (Android, iOS, Windows, web) + Riverpod 3 + go_router + Supabase.

## Rules
- Material is imported from `package:material_ui/material_ui.dart` (Flutter 3.50+), not `flutter/material.dart`.
- Feature-first: `lib/features/<feature>/{data,domain,presentation}`. Shared UI in `lib/core/widgets`.
- Every repository is an interface with a Supabase and a Mock implementation; the provider picks one via `Env.hasSupabase`. Without `--dart-define` keys the app runs in demo mode.
- Brand texts/contacts only in `lib/core/config/brand.dart`.
- Money is `int` in whole currency units; format with `formatMoney`.
- Prices/stock are never trusted from the app: orders go through the `place_order` RPC.
- Claude is called only from the `ai-stylist` Edge Function; the app falls back to `recommendLocally` on any error.
- UI copy is Russian.

## Commands
- `flutter analyze` — must be clean
- `flutter test` — unit + widget tests
- `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...`
- DB security tests: see README → «Проверка RLS».
