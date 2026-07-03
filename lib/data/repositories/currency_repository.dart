import 'package:drift/drift.dart';
import 'package:finance_app/core/database/app_database.dart';
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
    // NOTE: this preserves the original app's rebasing behaviour verbatim.
    // The multiplier maths is known to be imperfect for chained rebases and is
    // slated for a deliberate fix with dedicated tests later.
    final base = await getBase();

    await _db.transaction(() async {
      if (base == null) {
        await (_db.update(_db.currencies)..where((c) => c.id.equals(id))).write(
          const CurrenciesCompanion(rateToBase: Value(1.0)),
        );
      } else {
        final multiplier = 1.0 / (base.currencyRateToBase ?? 1.0);
        await _db.customUpdate(
          'UPDATE currencies SET rate_to_base = rate_to_base * ? '
          'WHERE rate_to_base IS NOT NULL',
          variables: [Variable<double>(multiplier)],
          updates: {_db.currencies},
        );
      }

      await _db.update(_db.currencies).write(
        const CurrenciesCompanion(isBase: Value(false)),
      );
      await (_db.update(_db.currencies)..where((c) => c.id.equals(id))).write(
        const CurrenciesCompanion(isBase: Value(true)),
      );
    });
  }

  @override
  Stream<List<Currency>> watchAll() {
    return _db.select(_db.currencies).watch().map(
      (rows) => rows.map(_toDomain).toList(),
    );
  }
}
