import 'package:finance_app/core/preferences/app_preferences.dart';
import 'package:flutter/foundation.dart';

/// Single source of truth for the user's premium entitlement.
///
/// Purchases happen on the website (to avoid App Store fees); the backend owns
/// the real entitlement and sync writes it into [AppPreferences]. This service
/// exposes it reactively so any widget can gate on it via [isPremium].
class SubscriptionService {
  SubscriptionService(this._prefs)
    : isPremium = ValueNotifier<bool>(_prefs.isPremium);

  final AppPreferences _prefs;

  /// Reactive premium flag — listen to rebuild gated UI when it changes.
  final ValueNotifier<bool> isPremium;

  /// Mirror the entitlement locally (called by sync once the account is known,
  /// and usable from a debug toggle while the backend isn't wired up yet).
  Future<void> setPremium(bool value) async {
    await _prefs.setPremium(value);
    isPremium.value = value;
  }
}
