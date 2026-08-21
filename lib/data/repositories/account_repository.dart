import 'package:solar_icons/solar_icons.dart';
import 'package:drift/drift.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/sync/sync_metadata.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:finance_app/core/app_icons.dart';

abstract class AccountRepository {
  Future<List<Account>> getAll();

  Future<Account?> getById(int id);

  Future<int> add({
    required String name,
    required int currencyId,
    required int iconCodePoint,
    String kind,
    double? interestRate,
    DateTime? maturityDate,
    double? currentValue,
  });

  Future<void> update({
    required int id,
    required String name,
    required int currencyId,
    required int iconCodePoint,
    String kind,
    double? interestRate,
    DateTime? maturityDate,
    double? currentValue,
  });

  /// Sets an investment account's current market value (the "update value"
  /// action). Stamps updated_at so the change syncs.
  Future<void> setCurrentValue(int id, double value);

  /// Number of transactions referencing this account (as source or
  /// destination) — used to block deletion of an account still in use.
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
      row.iconCodePoint ?? SolarIconsBold.wallet.codePoint,
    ),
    accountKind: row.kind,
    interestRate: row.interestRate,
    maturityDate: row.maturityDate == null
        ? null
        : DateTime.tryParse(row.maturityDate!),
    currentValue: row.currentValue,
  );

  @override
  Future<List<Account>> getAll() async {
    final rows = await _db.select(_db.accounts).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<Account?> getById(int id) async {
    final row = await (_db.select(
      _db.accounts,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<int> add({
    required String name,
    required int currencyId,
    required int iconCodePoint,
    String kind = 'general',
    double? interestRate,
    DateTime? maturityDate,
    double? currentValue,
  }) {
    return _db
        .into(_db.accounts)
        .insert(
          AccountsCompanion.insert(
            name: Value(name),
            currencyId: Value(currencyId),
            iconCodePoint: Value(iconCodePoint),
            kind: Value(kind),
            interestRate: Value(interestRate),
            maturityDate: Value(maturityDate?.toIso8601String()),
            currentValue: Value(currentValue),
          ),
        );
  }

  @override
  Future<void> update({
    required int id,
    required String name,
    required int currencyId,
    required int iconCodePoint,
    String kind = 'general',
    double? interestRate,
    DateTime? maturityDate,
    double? currentValue,
  }) async {
    await (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        name: Value(name),
        currencyId: Value(currencyId),
        iconCodePoint: Value(iconCodePoint),
        kind: Value(kind),
        interestRate: Value(interestRate),
        maturityDate: Value(maturityDate?.toIso8601String()),
        currentValue: Value(currentValue),
        // Stamped so cloud sync (LWW on updated_at) picks the edit up.
        updatedAt: Value(nowMs()),
      ),
    );
  }

  @override
  Future<void> setCurrentValue(int id, double value) async {
    await (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        currentValue: Value(value),
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
