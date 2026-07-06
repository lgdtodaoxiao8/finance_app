import 'package:drift/drift.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/sync/sync_metadata.dart';
import 'package:finance_app/data/models/transaction_details.dart';

/// Access to transactions joined with their related entities.
abstract class TransactionRepository {
  /// One-shot fetch, newest handling done by the caller.
  Future<List<TransactionDetails>> getAllWithDetails();

  /// Reactive stream that re-emits whenever any involved table changes.
  Stream<List<TransactionDetails>> watchAllWithDetails();

  /// Inserts a transaction and returns its new id.
  Future<int> add({
    required int accountId,
    int? accountDestinationId,
    required int categoryId,
    required int currencyId,
    required double amount,
    required DateTime date,
    String? note,
    required String type,
  });

  /// Updates an existing transaction.
  Future<void> update({
    required int id,
    required int accountId,
    int? accountDestinationId,
    required int categoryId,
    required int currencyId,
    required double amount,
    required DateTime date,
    String? note,
    required String type,
  });

  Future<void> delete(int id);
}

class DriftTransactionRepository implements TransactionRepository {
  DriftTransactionRepository(this._db);

  final AppDatabase _db;

  static const String _detailsSql = '''
    SELECT t.id, t.amount, t.date, t.note, t.type, t.is_canceled,
           t.account_id, t.account_destination_id,
           t.category_id, t.currency_id,
           a.name as account_name, a.icon_code_point as account_icon_code,
           a_des.name as account_destination_name,
           a_des.icon_code_point as account_destination_icon_code,
           c.name as category_name,
           c.color as category_color,
           c.icon_color as category_icon_color,
           c.icon_code_point as category_icon_code,
           cur.name as currency_name,
           cur.code as currency_code,
           cur.rate_to_base as currency_rate_to_base
    FROM transactions t
    JOIN accounts a ON t.account_id = a.id
    LEFT JOIN accounts a_des ON t.account_destination_id = a_des.id
    JOIN categories c ON t.category_id = c.id
    JOIN currencies cur ON t.currency_id = cur.id
    ORDER BY t.date ASC
  ''';

  Set<ResultSetImplementation> get _readsFrom => {
    _db.transactions,
    _db.accounts,
    _db.categories,
    _db.currencies,
  };

  @override
  Future<List<TransactionDetails>> getAllWithDetails() async {
    final rows = await _db
        .customSelect(_detailsSql, readsFrom: _readsFrom)
        .get();
    return rows.map((row) => TransactionDetails.fromMap(row.data)).toList();
  }

  @override
  Stream<List<TransactionDetails>> watchAllWithDetails() {
    return _db.customSelect(_detailsSql, readsFrom: _readsFrom).watch().map(
      (rows) =>
          rows.map((row) => TransactionDetails.fromMap(row.data)).toList(),
    );
  }

  @override
  Future<int> add({
    required int accountId,
    int? accountDestinationId,
    required int categoryId,
    required int currencyId,
    required double amount,
    required DateTime date,
    String? note,
    required String type,
  }) {
    return _db.into(_db.transactions).insert(
      TransactionsCompanion.insert(
        accountId: Value(accountId),
        accountDestinationId: accountDestinationId == null
            ? const Value.absent()
            : Value(accountDestinationId),
        categoryId: Value(categoryId),
        currencyId: Value(currencyId),
        amount: Value(amount),
        date: Value(date.toUtc().toIso8601String()),
        note: Value(note),
        type: Value(type),
        isCanceled: const Value(false),
      ),
    );
  }

  @override
  Future<void> update({
    required int id,
    required int accountId,
    int? accountDestinationId,
    required int categoryId,
    required int currencyId,
    required double amount,
    required DateTime date,
    String? note,
    required String type,
  }) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        accountId: Value(accountId),
        accountDestinationId: Value(accountDestinationId),
        categoryId: Value(categoryId),
        currencyId: Value(currencyId),
        amount: Value(amount),
        date: Value(date.toUtc().toIso8601String()),
        note: Value(note),
        type: Value(type),
        updatedAt: Value(nowMs()),
      ),
    );
  }

  @override
  Future<void> delete(int id) async {
    await _db.transaction(() async {
      final row = await (_db.select(
        _db.transactions,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      await _db.recordTombstone(SyncEntity.transactions, row?.uuid);
      await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
    });
  }
}
