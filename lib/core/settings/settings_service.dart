import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/settings/app_settings.dart';
import 'package:finance_app/core/sync/sync_metadata.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:flutter/foundation.dart';

/// Single source of truth for user preferences, backed by the Drift `Settings`
/// key/value table and exposed reactively via [settings].
///
/// Writes stamp `updated_at` and land in a synced table, so every preference
/// automatically propagates to the cloud (and to other devices) through the
/// existing [SyncService] — no per-setting sync code. The [settings] notifier
/// also updates when a cloud pull changes the table.
class SettingsService {
  SettingsService(this._db);

  final AppDatabase _db;

  // Storage keys. Stable strings — do not rename without a migration.
  static const _kThemeMode = 'theme_mode';
  static const _kLanguage = 'language';
  static const _kWeekStart = 'week_start';
  static const _kHideAmounts = 'hide_amounts';
  static const _kCurrencyConfig = 'currency_config';

  /// Current preferences. Listen to rebuild anything that depends on them.
  final ValueNotifier<AppSettings> settings = ValueNotifier<AppSettings>(
    const AppSettings(),
  );

  StreamSubscription<List<SettingRow>>? _sub;

  /// Loads preferences once (call before `runApp` so the first frame already
  /// has the right theme + locale), then keeps [settings] in sync with the
  /// table so cloud pulls are reflected live.
  Future<void> load() async {
    settings.value = _parse(await _db.select(_db.settings).get());
    _sub = _db.select(_db.settings).watch().listen((rows) {
      settings.value = _parse(rows);
      // Apply a base-currency/rates change that arrived from another device.
      _reconcileCurrencyConfig(rows);
    });
  }

  AppSettings _parse(List<SettingRow> rows) {
    final map = {for (final r in rows) r.key: r.value};
    return AppSettings(
      themeMode: AppThemeMode.fromName(map[_kThemeMode]),
      languageCode: _language(map[_kLanguage]),
      weekStartsMonday: (map[_kWeekStart] ?? 'mon') != 'sun',
      hideAmounts: map[_kHideAmounts] == 'true',
    );
  }

  String? _language(String? v) =>
      (v == null || v.isEmpty || v == 'system') ? null : v;

  // ---- typed setters -------------------------------------------------------

  Future<void> setThemeMode(AppThemeMode mode) =>
      _write(_kThemeMode, mode.name);

  /// [code] is `'en'` / `'ru'`, or null to follow the device locale.
  Future<void> setLanguage(String? code) =>
      _write(_kLanguage, code ?? 'system');

  Future<void> setWeekStartsMonday(bool monday) =>
      _write(_kWeekStart, monday ? 'mon' : 'sun');

  Future<void> setHideAmounts(bool hide) =>
      _write(_kHideAmounts, hide ? 'true' : 'false');

  // ---- base currency + rates -----------------------------------------------

  /// Serializes the current currency config (base + rates) into a synced
  /// preference. Call after the user changes the base currency or a rate.
  Future<void> recordCurrencyConfig() async {
    final snapshot = await getIt<CurrencyRepository>().configSnapshot();
    await _write(_kCurrencyConfig, jsonEncode(snapshot.toJson()));
  }

  /// If the synced currency config differs from what's stored locally, apply it
  /// (a change from another device). No-op for configs we just wrote ourselves,
  /// so this is safe to run on every settings emission.
  Future<void> _reconcileCurrencyConfig(List<SettingRow> rows) async {
    final raw = rows
        .cast<SettingRow?>()
        .firstWhere((r) => r?.key == _kCurrencyConfig, orElse: () => null)
        ?.value;
    if (raw == null || raw.isEmpty) return;
    try {
      final remote = CurrencyConfig.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      final repo = getIt<CurrencyRepository>();
      final local = await repo.configSnapshot();
      if (!local.matches(remote)) await repo.applyConfig(remote);
    } catch (e) {
      debugPrint('SettingsService._reconcileCurrencyConfig failed: $e');
    }
  }

  Future<void> _write(String key, String value) async {
    await _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion.insert(
            key: key,
            value: Value(value),
            updatedAt: Value(nowMs()),
          ),
        );
    // Reflect immediately; the watch stream will re-confirm.
    settings.value = _parse(await _db.select(_db.settings).get());
  }

  void dispose() {
    _sub?.cancel();
    settings.dispose();
  }
}
