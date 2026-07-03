import 'package:drift/drift.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:flutter/material.dart';

abstract class AccountRepository {
  Future<List<Account>> getAll();

  Future<int> add({
    required String name,
    required int currencyId,
    required int iconCodePoint,
  });

  Stream<List<Account>> watchAll();
}

class DriftAccountRepository implements AccountRepository {
  DriftAccountRepository(this._db);

  final AppDatabase _db;

  Account _toDomain(AccountRow row) => Account(
    accountId: row.id,
    accountName: row.name ?? '',
    currencyId: row.currencyId ?? 0,
    accountIcon: IconData(
      row.iconCodePoint ?? Icons.account_balance_wallet_rounded.codePoint,
      fontFamily: 'MaterialIcons',
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
    return _db.into(_db.accounts).insert(
      AccountsCompanion.insert(
        name: Value(name),
        currencyId: Value(currencyId),
        iconCodePoint: Value(iconCodePoint),
      ),
    );
  }

  @override
  Stream<List<Account>> watchAll() {
    return _db.select(_db.accounts).watch().map(
      (rows) => rows.map(_toDomain).toList(),
    );
  }
}
