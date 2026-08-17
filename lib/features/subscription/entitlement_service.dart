import 'package:finance_app/features/auth/auth_service.dart';
import 'package:finance_app/features/subscription/subscription_service.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Bridges the backend's premium entitlement into the local
/// [SubscriptionService].
///
/// Subscriptions are bought on the website (to avoid App Store fees); the
/// billing webhook writes the user's entitlement into the `entitlements` table
/// server-side. The app can only READ its own row, so this service fetches it
/// whenever the account is known and mirrors it into [SubscriptionService],
/// which persists it for offline gating.
///
/// It runs for any SIGNED-IN user — not only premium ones — because a free user
/// who just upgraded on the web must be able to learn they became premium.
/// (Cloud sync is premium-gated and so can't carry this itself.)
class EntitlementService {
  EntitlementService(this._auth, this._subscription);

  final AuthService _auth;
  final SubscriptionService _subscription;

  /// Tracks whether we've observed a signed-in account, so we can tell a real
  /// sign-out (drop the entitlement) from the never-signed-in startup state
  /// (leave any locally set value — e.g. a debug toggle — alone).
  bool _sawUser = false;

  /// Starts watching the account. Call after [AuthService.bind]. No-op when the
  /// backend isn't configured.
  void bind() {
    if (!_auth.isAvailable) return;
    _auth.currentUser.addListener(_onUserChanged);
    _sawUser = _auth.isSignedIn;
    refresh();
  }

  void _onUserChanged() {
    if (_auth.isSignedIn) {
      _sawUser = true;
      refresh();
    } else if (_sawUser) {
      // A genuine sign-out: we can no longer verify the entitlement, so drop
      // it. A premium set while signed out (debug toggle) never reaches here.
      _sawUser = false;
      _subscription.setPremium(false);
    }
  }

  /// Reads the current user's entitlement from the backend and mirrors it
  /// locally. Best-effort: on any error (offline, table missing) the last known
  /// value is kept so gating keeps working.
  Future<void> refresh() async {
    if (!_auth.isAvailable || !_auth.isSignedIn) return;
    final userId = _auth.currentUser.value!.id;
    try {
      final row = await Supabase.instance.client
          .from('entitlements')
          .select('is_premium')
          .eq('user_id', userId)
          .maybeSingle();
      final premium = (row?['is_premium'] as bool?) ?? false;
      await _subscription.setPremium(premium);
    } catch (e) {
      debugPrint('EntitlementService.refresh error: $e');
    }
  }

  void dispose() {
    _auth.currentUser.removeListener(_onUserChanged);
  }
}
