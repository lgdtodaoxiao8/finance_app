import 'package:shared_preferences/shared_preferences.dart';

/// Thin, typed wrapper over [SharedPreferences] for app-level flags.
///
/// A single instance is loaded at startup and registered in the service
/// locator, so all reads here are synchronous — handy for launch-time gating
/// (e.g. deciding whether to show onboarding) without an async round-trip.
class AppPreferences {
  AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const _kOnboardingSeen = 'onboarding_seen';

  /// Whether the user has completed the first-run onboarding (marketing
  /// carousel + base-currency setup). Gates the launch flow.
  bool get onboardingSeen => _prefs.getBool(_kOnboardingSeen) ?? false;

  Future<void> setOnboardingSeen(bool value) =>
      _prefs.setBool(_kOnboardingSeen, value);
}
