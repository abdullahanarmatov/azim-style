/// Build-time configuration passed via `--dart-define`.
///
/// Without SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY the app runs in demo mode on
/// in-memory mock data, so the UI can be shown without a backend.
class Env {
  const Env._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
