import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Currencies known to the app. A single currency is flagged [isBase]
/// (rate 1.0); every other currency stores its [rateToBase] once the user
/// provides an exchange rate.
class Currencies extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().nullable()();
  TextColumn get code => text().nullable()();
  TextColumn get symbol => text().nullable()();
  RealColumn get rateToBase => real().named('rate_to_base').nullable()();
  BoolColumn get isBase =>
      boolean().named('is_base').withDefault(const Constant(false))();
}

/// User money accounts (cash, bank, card, ...), each tied to a currency.
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().nullable()();
  IntColumn get currencyId =>
      integer().named('currency_id').nullable().references(Currencies, #id)();
  IntColumn get iconCodePoint =>
      integer().named('icon_code_point').nullable()();
}

/// Spending / income categories with their own color + icon.
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().nullable()();
  IntColumn get color => integer().nullable()();
  IntColumn get iconColor => integer().named('icon_color').nullable()();
  IntColumn get iconCodePoint =>
      integer().named('icon_code_point').nullable()();
}

/// A single financial operation: expense, income or transfer.
///
/// Named [TransactionRow] to avoid clashing with the domain `Transaction`
/// model. `date` is kept as an ISO-8601 TEXT column to match the existing
/// storage format.
@DataClassName('TransactionRow')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('sourceTransactions')
  IntColumn get accountId =>
      integer().named('account_id').nullable().references(Accounts, #id)();
  @ReferenceName('destinationTransactions')
  IntColumn get accountDestinationId => integer()
      .named('account_destination_id')
      .nullable()
      .references(Accounts, #id)();
  IntColumn get categoryId =>
      integer().named('category_id').nullable().references(Categories, #id)();
  IntColumn get currencyId =>
      integer().named('currency_id').nullable().references(Currencies, #id)();
  RealColumn get amount => real().nullable()();
  TextColumn get date => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get type => text().nullable()();
  BoolColumn get isCanceled =>
      boolean().named('is_canceled').nullable()();
}

@DriftDatabase(tables: [Currencies, Accounts, Categories, Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// In-memory database for tests.
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'finance.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
