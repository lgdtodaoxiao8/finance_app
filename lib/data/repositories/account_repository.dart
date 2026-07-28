import 'package:drift/drift.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/sync/sync_metadata.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:finance_app/core/app_icons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

abstract class AccountRepository {
  Future<List<Account>> getAll();

  Future<int> add({
    required String name,
    required int currencyId,
    required int iconCodePoint,
  });

  /// Number of transactions referencing this account (as source or
  /// destination) — used to block deletion of an account still in use.
  Future<void> update({
    required int id,
    required String name,
    required int currencyId,
    required int iconCodePoint,
  });

  Future<int> transactionCount(int accountId);

  Future<void> delete(int id);

  Stream<List<Account>> watchAll();
}

class DriftAccountRepository implements AccountRepository {
  DriftAccountRepository(this._db);

  final AppDatabase _db;

  Account _toDomain(AccountRow row) => Account(
    accountId: row.id,
    accountName: row.name ?? '',
    currencyId: row.currencyId ?? 0,
    accountIcon: appIconData(
      row.iconCodePoint ?? PhosphorIconsFill.wallet.codePoint,
    ),
  );

  @override
  Future<List<Account>> getAll() async {
    final rows = await _db.select(_db.accounts).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<int> add({
    required String name,
    required int currencyId,
    required int iconCodePoint,
  }) {
    return _db
        .into(_db.accounts)
        .insert(
          AccountsCompanion.insert(
            name: Value(name),
            currencyId: Value(currencyId),
            iconCodePoint: Value(iconCodePoint),
          ),
        );
  }

  @override
  Future<void> update({
    required int id,
    required String name,
    required int currencyId,
    required int iconCodePoint,
  }) async {
    await (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        name: Value(name),
        currencyId: Value(currencyId),
        iconCodePoint: Value(iconCodePoint),
        // Stamped so cloud sync (LWW on updated_at) picks the edit up.
        updatedAt: Value(nowMs()),
      ),
    );
  }

  @override
  Future<int> transactionCount(int accountId) async {
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM transactions '
          'WHERE account_id = ? OR account_destination_id = ?',
          variables: [Variable<int>(accountId), Variable<int>(accountId)],
          readsFrom: {_db.transactions},
        )
        .getSingle();
    return row.read<int>('c');
  }

  @override
  Future<void> delete(int id) async {
    await _db.transaction(() async {
      final row = await (_db.select(
        _db.accounts,
      )..where((a) => a.id.equals(id))).getSingleOrNull();
      await _db.recordTombstone(SyncEntity.accounts, row?.uuid);
      await (_db.delete(_db.accounts)..where((a) => a.id.equals(id))).go();
    });
  }

  @override
  Stream<List<Account>> watchAll() {
    return _db
        .select(_db.accounts)
        .watch()
        .map(
          (rows) => rows.map(_toDomain).toList(),
        );
  }
}
