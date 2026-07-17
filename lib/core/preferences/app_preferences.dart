import 'dart:convert';

import 'package:finance_app/features/widget_config/data/widget_shortcut.dart';
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
  static const _kPremium = 'is_premium';
  static const _kAiSig = 'ai_insights_sig';
  static const _kAiJson = 'ai_insights_json';
  static const _kWidgetShortcuts = 'widget_shortcuts';

  /// Whether the user has completed the first-run onboarding (marketing
  /// carousel + base-currency setup). Gates the launch flow.
  bool get onboardingSeen => _prefs.getBool(_kOnboardingSeen) ?? false;

  Future<void> setOnboardingSeen(bool value) =>
      _prefs.setBool(_kOnboardingSeen, value);

  /// Locally cached premium entitlement. The source of truth is the user's
  /// account on the backend; sync mirrors it here so gating works offline.
  bool get isPremium => _prefs.getBool(_kPremium) ?? false;

  Future<void> setPremium(bool value) => _prefs.setBool(_kPremium, value);

  // --- Cached AI insights (so we don't re-hit the paid API for unchanged
  // data). [signature] is a fingerprint of the spending the insights were
  // computed from; [json] is the raw AI response. ---
  String? get aiInsightsSignature => _prefs.getString(_kAiSig);
  String? get aiInsightsJson => _prefs.getString(_kAiJson);

  Future<void> setAiInsightsCache(String signature, String json) async {
    await _prefs.setString(_kAiSig, signature);
    await _prefs.setString(_kAiJson, json);
  }

  // --- Home-screen widget shortcuts (per-device; the widget layout is not
  // synced across devices). Stored as a JSON array of [WidgetShortcut]. ---
  List<WidgetShortcut> getWidgetShortcuts() {
    final raw = _prefs.getString(_kWidgetShortcuts);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final shortcuts = [
        for (final e in list)
          WidgetShortcut.fromJson(e as Map<String, dynamic>),
      ]..sort((a, b) => a.order.compareTo(b.order));
      return shortcuts;
    } catch (_) {
      return const [];
    }
  }

  Future<void> setWidgetShortcuts(List<WidgetShortcut> shortcuts) {
    final json = jsonEncode([for (final s in shortcuts) s.toJson()]);
    return _prefs.setString(_kWidgetShortcuts, json);
  }
}
