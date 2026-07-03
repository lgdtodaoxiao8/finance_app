import 'package:drift/drift.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/di/injector.dart';

/// Backwards-compatible facade over the Drift [AppDatabase].
///
/// The old sqflite implementation exposed a map-based API that the current
/// screens still call. During the Phase 2 BLoC migration these calls are
/// replaced by typed repositories feature-by-feature, and this facade is
/// deleted once nothing depends on it. Until then it delegates everything to
/// Drift so there is a single source of truth.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  AppDatabase get _db => getIt<AppDatabase>();

  /// Kept for API compatibility: screens `await db.database` to ensure the DB
  /// is ready. Drift opens lazily on first query, so this is a no-op await.
  Future<void> get database async {}

  // ----------------------- helpers -----------------------

  Variable _toVariable(dynamic value) {
    if (value == null) return const Variable<String>(null);
    if (value is int) return Variable<int>(value);
    if (value is double) return Variable<double>(value);
    if (value is bool) return Variable<bool>(value);
    return Variable<String>(value.toString());
  }

  Future<List<Map<String, dynamic>>> _rawQuery(
    String sql, [
    List<Variable> variables = const [],
  ]) async {
    final rows = await _db.customSelect(sql, variables: variables).get();
    return rows.map((row) => row.data).toList();
  }

  // ----------------------- currencies -----------------------

  Future<List<Map<String, dynamic>>> getCurrenciesWithRate() {
    return _rawQuery('SELECT * FROM currencies WHERE rate_to_base IS NOT NULL');
  }

  Future<List<Map<String, dynamic>>> getCurrenciesWithNullRate() {
    return _rawQuery('SELECT * FROM currencies WHERE rate_to_base IS NULL');
  }

  Future<List<Map<String, dynamic>>> getDefaultCurrency() {
    return _rawQuery('SELECT * FROM currencies WHERE is_base = 1 LIMIT 1');
  }

  Future<List<Map<String, dynamic>>> getCurrencyRate(int id) {
    return _rawQuery(
      'SELECT rate_to_base FROM currencies WHERE id = ?',
      [Variable<int>(id)],
    );
  }

  Future<List<Map<String, dynamic>>> getAllCurrencies() {
    return _rawQuery('SELECT * FROM currencies');
  }

  Future<String> getCurrencySymbol(int id) async {
    final rows = await _rawQuery(
      'SELECT symbol FROM currencies WHERE id = ? LIMIT 1',
      [Variable<int>(id)],
    );
    if (rows.isEmpty) return '';
    return (rows.first['symbol'] as String?) ?? '';
  }

  Future<void> makeCurrencyBase(int newId) async {
    final oldBaseCurrency = await getDefaultCurrency();

    if (oldBaseCurrency.isEmpty) {
      await _db.customUpdate(
        'UPDATE currencies SET rate_to_base = 1.0 WHERE id = ?',
        variables: [Variable<int>(newId)],
        updates: {_db.currencies},
      );
    } else {
      final double multiplier =
          1.0 / (oldBaseCurrency.first['rate_to_base'] as num);

      await _db.customUpdate(
        'UPDATE currencies SET rate_to_base = rate_to_base * ? '
        'WHERE rate_to_base IS NOT NULL',
        variables: [Variable<double>(multiplier)],
        updates: {_db.currencies},
      );
    }

    await _db.transaction(() async {
      await _db.customUpdate(
        'UPDATE currencies SET is_base = 0',
        updates: {_db.currencies},
      );
      await _db.customUpdate(
        'UPDATE currencies SET is_base = 1 WHERE id = ?',
        variables: [Variable<int>(newId)],
        updates: {_db.currencies},
      );
    });
  }

  Future<void> setNewRate(double rate, int id) async {
    await _db.customUpdate(
      'UPDATE currencies SET rate_to_base = ? WHERE id = ?',
      variables: [Variable<double>(rate), Variable<int>(id)],
      updates: {_db.currencies},
    );
  }

  // ----------------------- generic -----------------------

  Future<int?> insert(String table, Map<String, dynamic> data) async {
    final columns = data.keys.toList();
    final placeholders = List.filled(columns.length, '?').join(', ');
    final sql =
        'INSERT OR REPLACE INTO $table (${columns.join(', ')}) '
        'VALUES ($placeholders)';
    return _db.customInsert(
      sql,
      variables: data.values.map(_toVariable).toList(),
    );
  }

  Future<List<Map<String, dynamic>>> getAll(String table) {
    return _rawQuery('SELECT * FROM $table');
  }

  Future<List<Map<String, dynamic>>> getTransactionsWithDetails() {
    return _rawQuery('''
      SELECT t.id, t.amount, t.date, t.note, t.type, t.is_canceled,
             a.name as account_name, a.icon_code_point as account_icon_code,
             a_des.name as account_destination_name,
             a_des.icon_code_point as account_destination_icon_code,
             c.name as category_name,
             c.color as category_color,
             c.icon_color as category_icon_color,
             c.icon_code_point as category_icon_code,
             cur.name as currency_name,
             cur.code as currency_code
      FROM transactions t
      JOIN accounts a ON t.account_id = a.id
      LEFT JOIN accounts a_des ON t.account_destination_id = a_des.id
      JOIN categories c ON t.category_id = c.id
      JOIN currencies cur ON t.currency_id = cur.id
      ORDER BY t.date ASC
    ''');
  }

  // ----------------------- maintenance -----------------------

  Future<void> deleteTable(String tableName) async {
    await _db.customStatement('DELETE FROM $tableName');
  }

  /// Wipes every row (used by the dev-only reset path).
  Future<void> deleteDatabaseFile() async {
    await _db.transaction(() async {
      for (final table in _db.allTables) {
        await _db.delete(table).go();
      }
    });
  }
}
