import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:finance_app/core/sync/sync_metadata.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Sync metadata shared by user-generated, syncable tables: a stable global
/// [uuid] (cross-device identity) and [updatedAt] (last-write-wins clock).
/// Both are nullable so the columns can be added to existing tables during
/// migration and backfilled; new rows always get values via [clientDefault].
mixin SyncColumns on Table {
  TextColumn get uuid => text().clientDefault(newUuid).nullable()();
  IntColumn get updatedAt =>
      integer().named('updated_at').clientDefault(nowMs).nullable()();
}

/// Currencies known to the app. A single currency is flagged [isBase]
/// (rate 1.0); every other currency stores its [rateToBase] once the user
/// provides an exchange rate.
@DataClassName('CurrencyRow')
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
@DataClassName('AccountRow')
class Accounts extends Table with SyncColumns {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().nullable()();
  IntColumn get currencyId =>
      integer().named('currency_id').nullable().references(Currencies, #id)();
  IntColumn get iconCodePoint =>
      integer().named('icon_code_point').nullable()();

  /// Account purpose: 'general' (spending — cash/bank/card), 'savings' (savings
  /// or deposit, may earn interest) or 'investment' (brokerage/crypto/funds,
  /// value tracked manually). Defaults to general for existing rows.
  TextColumn get kind => text().withDefault(const Constant('general'))();

  /// Annual interest rate in percent for a savings/deposit account (e.g. 3.5).
  RealColumn get interestRate => real().named('interest_rate').nullable()();

  /// Deposit term end date (ISO-8601 date) for a fixed-term deposit.
  TextColumn get maturityDate => text().named('maturity_date').nullable()();

  /// Manually-tracked current market value of an investment account. Net worth
  /// uses THIS instead of the contribution balance; the gap is the return.
  /// Market moves stay out of income/expense analytics — they aren't earnings.
  RealColumn get currentValue => real().named('current_value').nullable()();
}

/// Spending / income categories with their own color + icon. Each category is
/// hard-typed as [kind] 'expense' or 'income': it can only be used for that
/// kind of transaction, and each quick-add widget only offers its own kind.
@DataClassName('CategoryRow')
class Categories extends Table with SyncColumns {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().nullable()();
  IntColumn get color => integer().nullable()();
  IntColumn get iconColor => integer().named('icon_color').nullable()();
  IntColumn get iconCodePoint =>
      integer().named('icon_code_point').nullable()();

  /// 'expense' | 'income'. Defaults to expense so existing rows and inserts
  /// that predate typing stay valid.
  TextColumn get kind => text().withDefault(const Constant('expense'))();
}

/// A single financial operation: expense, income or transfer.
///
/// Named [TransactionRow] to avoid clashing with the domain `Transaction`
/// model. `date` is kept as an ISO-8601 TEXT column to match the existing
/// storage format.
@DataClassName('TransactionRow')
class Transactions extends Table with SyncColumns {
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
  BoolColumn get isCanceled => boolean().named('is_canceled').nullable()();

  /// Snapshot of the transaction currency's rate-to-base AT THE TIME the
  /// transaction was created/last edited. Base conversion (`amountInBase`) reads
  /// THIS, not the currency's live rate, so a later exchange-rate correction
  /// never re-values historical transactions. A base-currency CHANGE does
  /// re-express these (they scale by the same factor) — that's a unit change.
  RealColumn get rateToBase => real().named('rate_to_base').nullable()();
}

/// A monthly spending limit. [categoryId] null means the OVERALL budget (a cap
/// on total spending); otherwise it's a per-category limit. [amount] is in the
/// base currency.
@DataClassName('BudgetRow')
class Budgets extends Table with SyncColumns {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId =>
      integer().named('category_id').nullable().references(Categories, #id)();
  RealColumn get amount => real().nullable()();
}

/// A savings goal / jar ("под подушкой") — money the user has set aside toward
/// a target. Standalone real money (not an account): [savedAmount] counts toward
/// net worth. [targetAmount]/[deadline] are optional aspirations.
@DataClassName('GoalRow')
class Goals extends Table with SyncColumns {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().nullable()();
  RealColumn get targetAmount => real().named('target_amount').nullable()();
  RealColumn get savedAmount =>
      real().named('saved_amount').withDefault(const Constant(0))();
  IntColumn get color => integer().nullable()();
  IntColumn get iconCodePoint => integer().named('icon_code_point').nullable()();
  TextColumn get deadline => text().nullable()();
}

/// Records local deletions of syncable rows so the deletion can be pushed to
/// the backend (and thus propagated to other devices). Cleared once pushed.
class Tombstones extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entity => text()();
  TextColumn get uuid => text()();
  IntColumn get deletedAt =>
      integer().named('deleted_at').clientDefault(nowMs)();
}

/// App-level user preferences as a synced key-value store. [key] is the stable
/// per-user identity (no uuid needed); sync is keyed on (user_id, key) with
/// last-write-wins on [updatedAt]. Values are text — JSON for structured
/// settings. Adding a new preference is just a new key, nothing schema-level.
@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();
  IntColumn get updatedAt =>
      integer().named('updated_at').clientDefault(nowMs)();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Currencies,
    Accounts,
    Categories,
    Transactions,
    Budgets,
    Goals,
    Tombstones,
    Settings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// In-memory database for tests.
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Add sync metadata to the user-generated tables and give existing
        // rows a stable uuid + a current updatedAt so they sync cleanly.
        await m.addColumn(accounts, accounts.uuid);
        await m.addColumn(accounts, accounts.updatedAt);
        await m.addColumn(categories, categories.uuid);
        await m.addColumn(categories, categories.updatedAt);
        await m.addColumn(transactions, transactions.uuid);
        await m.addColumn(transactions, transactions.updatedAt);
        await m.createTable(tombstones);

        await _backfillSyncMetadata(accounts);
        await _backfillSyncMetadata(categories);
        await _backfillSyncMetadata(transactions);
      }
      if (from < 3) {
        // Synced app preferences (theme, language, week start, …).
        await m.createTable(settings);
      }
      if (from < 4) {
        // Hard income/expense typing on categories. New column defaults to
        // 'expense'; backfill categories that are used mostly in income
        // transactions so existing income categories (Salary, …) type right.
        await m.addColumn(categories, categories.kind);
        await customStatement(
          "UPDATE categories SET kind = 'income' WHERE id IN ("
          '  SELECT category_id FROM transactions'
          '  WHERE category_id IS NOT NULL'
          '  GROUP BY category_id'
          "  HAVING SUM(CASE WHEN type = 'income' THEN 1 ELSE 0 END) >"
          "         SUM(CASE WHEN type = 'expense' THEN 1 ELSE 0 END)"
          ')',
        );
      }
      if (from < 5) {
        // Freeze each transaction's base-conversion rate: snapshot the
        // currency's CURRENT rate onto the transaction so a future rate
        // correction can't rewrite history. (No historical rates exist, so the
        // current rate is the best backfill.)
        await m.addColumn(transactions, transactions.rateToBase);
        await customStatement(
          'UPDATE transactions SET rate_to_base = ('
          '  SELECT c.rate_to_base FROM currencies c '
          '  WHERE c.id = transactions.currency_id'
          ') WHERE rate_to_base IS NULL',
        );
      }
      if (from < 6) {
        // Account kinds + savings/investment fields. Existing accounts default
        // to 'general' (spending); the rest are null until the user sets them.
        await m.addColumn(accounts, accounts.kind);
        await m.addColumn(accounts, accounts.interestRate);
        await m.addColumn(accounts, accounts.maturityDate);
        await m.addColumn(accounts, accounts.currentValue);
      }
      if (from < 7) {
        // Monthly budgets (overall + per-category).
        await m.createTable(budgets);
      }
      if (from < 8) {
        // Savings goals / jars.
        await m.createTable(goals);
      }
    },
  );

  /// Records a deletion so sync can propagate it. No-op if [uuid] is null
  /// (row predates sync metadata and was never pushed).
  Future<void> recordTombstone(String entity, String? uuid) async {
    if (uuid == null) return;
    await into(tombstones).insert(
      TombstonesCompanion.insert(entity: entity, uuid: uuid),
    );
  }

  /// Assigns a uuid + updatedAt to any pre-existing rows missing them.
  Future<void> _backfillSyncMetadata(TableInfo table) async {
    final now = nowMs();
    final rows = await customSelect(
      'SELECT id FROM ${table.actualTableName} WHERE uuid IS NULL',
    ).get();
    for (final row in rows) {
      await customUpdate(
        'UPDATE ${table.actualTableName} SET uuid = ?, updated_at = ? '
        'WHERE id = ?',
        variables: [
          Variable<String>(newUuid()),
          Variable<int>(now),
          Variable<int>(row.read<int>('id')),
        ],
        updates: {table},
      );
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'finance.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
