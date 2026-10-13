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

  /// Project URL only — no /rest/v1 suffix.
  static const _urlFallback = 'https://pbsruiwuehcyrvnghxwa.supabase.co';

  /// Publishable key (safe in the app). Never put the secret key here.
  static const _anonFallback = 'sb_publishable_r6SF9l-Gfl-FFEBGCnvs2Q_5DkiTzlX';

  static bool get isConfigured =>
      url.startsWith('https://') && anonKey.isNotEmpty && anonKey != 'YOUR_ANON_KEY';
}
