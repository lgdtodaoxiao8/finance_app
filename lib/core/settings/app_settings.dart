import 'package:flutter/material.dart';

/// How the app picks its colour scheme.
enum AppThemeMode {
  system,
  light,
  dark;

  ThemeMode get material => switch (this) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };

  static AppThemeMode fromName(String? name) => AppThemeMode.values.firstWhere(
    (m) => m.name == name,
    orElse: () => AppThemeMode.system,
  );
}

/// Immutable snapshot of every user preference. Persisted as key/value rows in
/// the Drift `Settings` table and synced to the cloud (see [SettingsService]).
///
/// Adding a preference: add a field here, a key in [SettingsService], and a
/// setter — the storage + sync are generic, so nothing else changes.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.languageCode,
    this.weekStartsMonday = true,
    this.hideAmounts = false,
  });

  /// Light / dark / follow-system.
  final AppThemeMode themeMode;

  /// UI language: `'en'`, `'ru'`, or null to follow the device locale.
  final String? languageCode;

  /// First day of the week for period grouping / charts (Mon vs Sun).
  final bool weekStartsMonday;

  /// Mask balances and amounts in the UI (shoulder-surfing privacy).
  final bool hideAmounts;

  /// Resolved locale, or null to follow the system.
  Locale? get locale => languageCode == null ? null : Locale(languageCode!);

  AppSettings copyWith({
    AppThemeMode? themeMode,
    String? languageCode,
    bool clearLanguage = false,
    bool? weekStartsMonday,
    bool? hideAmounts,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      languageCode: clearLanguage ? null : (languageCode ?? this.languageCode),
      weekStartsMonday: weekStartsMonday ?? this.weekStartsMonday,
      hideAmounts: hideAmounts ?? this.hideAmounts,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.themeMode == themeMode &&
      other.languageCode == languageCode &&
      other.weekStartsMonday == weekStartsMonday &&
      other.hideAmounts == hideAmounts;

  @override
  int get hashCode =>
      Object.hash(themeMode, languageCode, weekStartsMonday, hideAmounts);
}
