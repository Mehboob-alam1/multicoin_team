import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Starts Supabase after Firebase. Uses the Firebase ID token so RLS can key
/// rows by Firebase uid (`auth.jwt()->>'sub'`). Enable Firebase as a
/// third-party auth provider in the Supabase dashboard.
class SupabaseBootstrap {
  static bool _inited = false;

  static bool get isReady => _inited && SupabaseConfig.isConfigured;

  static Future<void> init() async {
    if (_inited) return;
    if (!SupabaseConfig.isConfigured) {
      debugPrint('Supabase skipped: paste URL + anon key in lib/config/supabase_config.dart');
      return;
    }
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
        accessToken: () async {
          try {
            return await FirebaseAuth.instance.currentUser?.getIdToken();
          } catch (_) {
            return null;
          }
        },
      );
      _inited = true;
      debugPrint('Supabase ready');
    } catch (e) {
      debugPrint('Supabase init: $e');
    }
  }

  static SupabaseClient? get client {
    if (!isReady) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}
