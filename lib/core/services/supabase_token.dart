import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';

/// Supplies the Firebase ID token that Supabase uses to pick a Postgres role.
///
/// Supabase maps the token's `role` claim to a Postgres role. Firebase tokens
/// only carry `role: authenticated` after the blocking functions in
/// `functions/index.js` are deployed (new sign-ins) or
/// `functions/backfill-role-claim.js` has been run (existing users), AND the
/// user's token has been refreshed. Without it every request runs as `anon`
/// and PostgREST answers `42501 permission denied`.
///
/// This helper makes that failure obvious and self-healing where possible:
///  1. If the cached token has no `role: authenticated`, force one refresh
///     (the claim may have been added after the token was issued).
///  2. If it is still missing, log one clear message pointing at the fix.
class SupabaseToken {
  SupabaseToken._();

  static bool _warned = false;

  /// True when [jwt] carries `role: authenticated`. Never throws.
  @visibleForTesting
  static bool hasAuthenticatedRole(String? jwt) {
    if (jwt == null) return false;
    final parts = jwt.split('.');
    if (parts.length != 3) return false;
    try {
      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final claims = jsonDecode(payload);
      return claims is Map && claims['role'] == 'authenticated';
    } catch (_) {
      return false;
    }
  }

  /// Returns the bearer token for the signed-in user, or null when signed out
  /// (requests then go out as `anon`, enough for the public catalog).
  static Future<String?> fetch() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) {
      _warned = false;
      return null;
    }

    var token = await user.getIdToken();
    if (hasAuthenticatedRole(token)) {
      _warned = false;
      return token;
    }

    // Claim may have been granted after this token was minted.
    try {
      token = await user.getIdToken(true);
    } catch (_) {
      // Offline or throttled: fall through with the cached token.
    }
    if (!hasAuthenticatedRole(token) && !_warned) {
      _warned = true;
      debugPrint(
        '[Supabase] Firebase ID token has no role=authenticated claim, so '
        'every request runs as anon and RLS will refuse it. Fix: deploy '
        'functions/index.js (blocking functions) and run '
        'functions/backfill-role-claim.js once, then sign out and back in. '
        'See SECURITY.md > Supabase step 2.',
      );
    }
    return token;
  }
}
