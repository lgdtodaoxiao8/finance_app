import 'dart:convert';

import 'package:finance_app/features/widget_config/data/widget_group.dart';
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
  static const _kWidgetGroups = 'widget_groups';

  /// Stable id of the always-present default group (migrated from the legacy
  /// single shortcut list). Kept constant so old widget instances keep working.
  static const defaultWidgetGroupId = 'default';

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

  // --- Home-screen widget groups (per-device; the widget layout is not
  // synced across devices). Each group is a named set of shortcuts; a widget
  // instance binds to one group via iOS "Edit Widget". Stored as a JSON array
  // of [WidgetGroup] under [_kWidgetGroups]. ---

  /// All configured groups. On first read after the multi-group upgrade, the
  /// legacy single shortcut list is migrated into a "default" group so old
  /// widget instances keep their categories.
  List<WidgetGroup> getWidgetGroups() {
    final raw = _prefs.getString(_kWidgetGroups);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        final groups = [
          for (final e in list) WidgetGroup.fromJson(e as Map<String, dynamic>),
        ];
        if (groups.isNotEmpty) return groups;
      } catch (_) {
        // fall through to migration / default
      }
    }
    return [
      WidgetGroup(
        id: defaultWidgetGroupId,
        name: '',
        shortcuts: _legacyShortcuts(),
      ),
    ];
  }

  Future<void> setWidgetGroups(List<WidgetGroup> groups) {
    final json = jsonEncode([for (final g in groups) g.toJson()]);
    return _prefs.setString(_kWidgetGroups, json);
  }

  /// Reads the pre-multigroup shortcut list (used once to seed the default
  /// group).
  List<WidgetShortcut> _legacyShortcuts() {
    final raw = _prefs.getString(_kWidgetShortcuts);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list)
          WidgetShortcut.fromJson(e as Map<String, dynamic>),
      ]..sort((a, b) => a.order.compareTo(b.order));
    } catch (_) {
      return const [];
    }
  }
}
