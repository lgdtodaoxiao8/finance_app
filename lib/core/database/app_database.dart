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
}

/// Spending / income categories with their own color + icon.
@DataClassName('CategoryRow')
class Categories extends Table with SyncColumns {
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
    Tombstones,
    Settings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// In-memory database for tests.
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 3;

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
