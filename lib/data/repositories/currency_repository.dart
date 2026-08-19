import 'package:drift/drift.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/sync/sync_metadata.dart';
import 'package:finance_app/models/main_model.dart';

/// Access to currencies and the base-currency / exchange-rate logic.
abstract class CurrencyRepository {
  Future<List<Currency>> getAll();

  /// Currencies usable for accounts/transactions (have an exchange rate).
  Future<List<Currency>> getWithRate();

  /// Currencies still missing an exchange rate.
  Future<List<Currency>> getWithoutRate();

  /// The current base currency, or null if none is set yet.
  Future<Currency?> getBase();

  Future<double?> getRate(int id);

  /// Sets [rate] as the currency's exchange rate to base.
  Future<void> setRate(int id, double rate);

  /// Makes the currency [id] the base currency, rebasing existing rates.
  Future<void> makeBase(int id);

  Stream<List<Currency>> watchAll();

  /// Snapshot of the base-currency code + every currency's rate-to-base, for
  /// cross-device sync (matched by currency code, which is deterministic seed).
  Future<CurrencyConfig> configSnapshot();

  /// Applies a synced [config] by writing each rate + the base flag directly.
  /// No rebasing math — the rates are already normalized — so it's idempotent
  /// and safe to re-apply.
  Future<void> applyConfig(CurrencyConfig config);
}

/// The synced currency state: which code is base + absolute rate-to-base by
/// code. Serialized into the `currency_config` preference.
class CurrencyConfig {
  const CurrencyConfig({required this.baseCode, required this.rates});

  final String? baseCode;
  final Map<String, double> rates;

  Map<String, dynamic> toJson() => {'base': baseCode, 'rates': rates};

  factory CurrencyConfig.fromJson(Map<String, dynamic> json) => CurrencyConfig(
    baseCode: json['base'] as String?,
    rates: {
      for (final e in (json['rates'] as Map? ?? {}).entries)
        e.key as String: (e.value as num).toDouble(),
    },
  );

  /// Equal ignoring float noise (rates compared to 6 decimals).
  bool matches(CurrencyConfig other) {
    if (baseCode != other.baseCode) return false;
    if (rates.length != other.rates.length) return false;
    for (final e in rates.entries) {
      final o = other.rates[e.key];
      if (o == null) return false;
      if ((e.value - o).abs() > 1e-6) return false;
    }
    return true;
  }
}

class DriftCurrencyRepository implements CurrencyRepository {
  DriftCurrencyRepository(this._db);

  final AppDatabase _db;

  Currency _toDomain(CurrencyRow row) => Currency(
    currencyId: row.id,
    currencyName: row.name ?? '',
    currencyCode: row.code ?? '',
    currencySymbol: row.symbol ?? '',
    currencyRateToBase: row.rateToBase,
    isBaseCurrency: row.isBase,
  );

  @override
  Future<List<Currency>> getAll() async {
    final rows = await _db.select(_db.currencies).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<Currency>> getWithRate() async {
    final rows = await (_db.select(
      _db.currencies,
    )..where((c) => c.rateToBase.isNotNull())).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<Currency>> getWithoutRate() async {
    final rows = await (_db.select(
      _db.currencies,
    )..where((c) => c.rateToBase.isNull())).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<Currency?> getBase() async {
    final row = await (_db.select(
      _db.currencies,
    )..where((c) => c.isBase.equals(true))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<double?> getRate(int id) async {
    final row = await (_db.select(
      _db.currencies,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    return row?.rateToBase;
  }

  @override
  Future<void> setRate(int id, double rate) async {
    await (_db.update(_db.currencies)..where((c) => c.id.equals(id))).write(
      CurrenciesCompanion(rateToBase: Value(rate)),
    );
  }

  @override
  Future<void> makeBase(int id) async {
    // rate_to_base(C) = value of 1 unit of C expressed in the base currency.
    // When currency X becomes the new base, every rate must be re-expressed in
    // X units: new_rate(C) = old_rate(C) / old_rate(X). Dividing all rates by
    // X's current rate also makes X itself exactly 1.0.
    final base = await getBase();
    final newBaseRate = await getRate(id);

    await _db.transaction(() async {
      if (base == null || newBaseRate == null || newBaseRate == 0) {
        // First-time setup (or a rate-less pick): X simply anchors at 1.0.
        await (_db.update(_db.currencies)..where((c) => c.id.equals(id))).write(
          const CurrenciesCompanion(rateToBase: Value(1.0)),
        );
      } else {
        final multiplier = 1.0 / newBaseRate;
        await _db.customUpdate(
          'UPDATE currencies SET rate_to_base = rate_to_base * ? '
          'WHERE rate_to_base IS NOT NULL',
          variables: [Variable<double>(multiplier)],
          updates: {_db.currencies},
        );
        // Re-express every transaction's FROZEN rate in the new base too — a
        // base change is a unit change, so they all scale by the same factor.
        // (A plain rate correction via setRate leaves these untouched, so
        // history there stays frozen.) Bump updated_at so it syncs.
        await _db.customUpdate(
          'UPDATE transactions SET rate_to_base = rate_to_base * ?, '
          'updated_at = ? WHERE rate_to_base IS NOT NULL',
          variables: [Variable<double>(multiplier), Variable<int>(nowMs())],
          updates: {_db.transactions},
        );
      }

      await _db
          .update(_db.currencies)
          .write(
            const CurrenciesCompanion(isBase: Value(false)),
          );
      await (_db.update(_db.currencies)..where((c) => c.id.equals(id))).write(
        const CurrenciesCompanion(isBase: Value(true)),
      );
    });
  }

  @override
  Stream<List<Currency>> watchAll() {
    return _db
        .select(_db.currencies)
        .watch()
        .map(
          (rows) => rows.map(_toDomain).toList(),
        );
  }

  @override
  Future<CurrencyConfig> configSnapshot() async {
    final rows = await _db.select(_db.currencies).get();
    String? baseCode;
    final rates = <String, double>{};
    for (final r in rows) {
      if (r.isBase) baseCode = r.code;
      if (r.rateToBase != null && r.code != null) {
        rates[r.code!] = r.rateToBase!;
      }
    }
    return CurrencyConfig(baseCode: baseCode, rates: rates);
  }

  @override
  Future<void> applyConfig(CurrencyConfig config) async {
    await _db.transaction(() async {
      for (final entry in config.rates.entries) {
        await (_db.update(
          _db.currencies,
        )..where((c) => c.code.equals(entry.key))).write(
          CurrenciesCompanion(rateToBase: Value(entry.value)),
        );
      }
      // Reset every base flag, then set the one from the synced config.
      await _db
          .update(
            _db.currencies,
          )
          .write(const CurrenciesCompanion(isBase: Value(false)));
      final baseCode = config.baseCode;
      if (baseCode != null) {
        await (_db.update(
          _db.currencies,
        )..where((c) => c.code.equals(baseCode))).write(
          const CurrenciesCompanion(isBase: Value(true)),
        );
      }
    });
  }
}
