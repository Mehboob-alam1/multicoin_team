/// Paste your Supabase project URL and anon key here after you create the project.
/// You can also pass `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.
///
/// Until both values are set, the app stays fully local (Firebase Auth / FCM / RC
/// still run). Run `supabase/schema.sql` in the Supabase SQL editor once.
class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _urlFallback,
  );
  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _anonFallback,
  );

  /// Paste project URL, e.g. https://xxxx.supabase.co
  static const _urlFallback = '';

  /// Paste the anon (public) key from Project Settings → API.
  static const _anonFallback = '';

  static bool get isConfigured =>
      url.startsWith('https://') && anonKey.isNotEmpty && anonKey != 'YOUR_ANON_KEY';
}
