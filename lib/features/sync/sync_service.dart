import 'package:drift/drift.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/features/auth/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Bidirectional sync between the local Drift database and Supabase Postgres.
///
/// Model (v1): a full mirror on every run. We push every local row (upsert is
/// idempotent, keyed on `user_id,uuid`) plus any tombstones, then pull every
/// remote row and merge with last-write-wins on `updated_at`. Data volumes for
/// a personal finance app are small, so a full pass keeps the logic simple and
/// robust (no fragile cursors). FK identity crosses devices via row `uuid`;
/// currencies are matched by their stable `code` (deterministic seed data), so
/// they need no uuid and aren't pushed.
class SyncService {
  SyncService(this._db, this._auth);

  final AppDatabase _db;
  final AuthService _auth;

  final ValueNotifier<bool> isSyncing = ValueNotifier<bool>(false);

  bool get _canSync => _auth.isAvailable && _auth.isSignedIn;

  SupabaseClient get _client => Supabase.instance.client;
  String get _userId => _client.auth.currentUser!.id;

  /// Runs a full push + pull. Safe to call opportunistically (sign-in, resume,
  /// manual button); no-ops when there's no account/backend or a run is active.
  Future<void> sync() async {
    if (!_canSync || isSyncing.value) return;
    isSyncing.value = true;
    try {
      await _push();
      await _pull();
    } catch (e, st) {
      debugPrint('SyncService.sync error: $e\n$st');
      rethrow;
    } finally {
      isSyncing.value = false;
    }
  }

  // ---------------------------------------------------------------- push ----

  Future<void> _push() async {
    final currencyCodeById = await _currencyCodeById();
    final accountUuidById = await _accountUuidById();
    final categoryUuidById = await _categoryUuidById();

    final categories = await _db.select(_db.categories).get();
    if (categories.isNotEmpty) {
      await _client.from('categories').upsert([
        for (final c in categories)
          {
            'user_id': _userId,
            'uuid': c.uuid,
            'name': c.name,
            'color': c.color,
            'icon_color': c.iconColor,
            'icon_code_point': c.iconCodePoint,
            'updated_at': c.updatedAt,
            'deleted': false,
          },
      ], onConflict: 'user_id,uuid');
    }

    final accounts = await _db.select(_db.accounts).get();
    if (accounts.isNotEmpty) {
      await _client.from('accounts').upsert([
        for (final a in accounts)
          {
            'user_id': _userId,
            'uuid': a.uuid,
            'name': a.name,
            'currency_code': currencyCodeById[a.currencyId],
            'icon_code_point': a.iconCodePoint,
            'updated_at': a.updatedAt,
            'deleted': false,
          },
      ], onConflict: 'user_id,uuid');
    }

    final txns = await _db.select(_db.transactions).get();
    if (txns.isNotEmpty) {
      await _client.from('transactions').upsert([
        for (final t in txns)
          {
            'user_id': _userId,
            'uuid': t.uuid,
            'account_uuid': accountUuidById[t.accountId],
            'account_destination_uuid': accountUuidById[t.accountDestinationId],
            'category_uuid': categoryUuidById[t.categoryId],
            'currency_code': currencyCodeById[t.currencyId],
            'amount': t.amount,
            'date': t.date,
            'note': t.note,
            'type': t.type,
            'is_canceled': t.isCanceled ?? false,
            'updated_at': t.updatedAt,
            'deleted': false,
          },
      ], onConflict: 'user_id,uuid');
    }

    await _pushTombstones();
  }

  /// Marks deleted rows `deleted=true` remotely (so other devices learn of the
  /// deletion), then clears the local tombstones.
  Future<void> _pushTombstones() async {
    final tombstones = await _db.select(_db.tombstones).get();
    if (tombstones.isEmpty) return;
    for (final t in tombstones) {
      await _client.from(t.entity).upsert({
        'user_id': _userId,
        'uuid': t.uuid,
        'updated_at': t.deletedAt,
        'deleted': true,
      }, onConflict: 'user_id,uuid');
    }
    await _db.delete(_db.tombstones).go();
  }

  // ---------------------------------------------------------------- pull ----
  // Order matters: referenced rows (categories, accounts) before transactions.

  Future<void> _pull() async {
    await _pullCategories();
    await _pullAccounts();
    await _pullTransactions();
  }

  Future<void> _pullCategories() async {
    final rows = await _client.from('categories').select();
    for (final r in rows) {
      final uuid = r['uuid'] as String;
      if (r['deleted'] == true) {
        await (_db.delete(
          _db.categories,
        )..where((c) => c.uuid.equals(uuid))).go();
        continue;
      }
      final remoteUpdated = (r['updated_at'] as num?)?.toInt() ?? 0;
      final existing = await (_db.select(
        _db.categories,
      )..where((c) => c.uuid.equals(uuid))).getSingleOrNull();
      if (existing != null && (existing.updatedAt ?? 0) >= remoteUpdated) {
        continue;
      }
      final companion = CategoriesCompanion(
        uuid: Value(uuid),
        name: Value(r['name'] as String?),
        color: Value((r['color'] as num?)?.toInt()),
        iconColor: Value((r['icon_color'] as num?)?.toInt()),
        iconCodePoint: Value((r['icon_code_point'] as num?)?.toInt()),
        updatedAt: Value(remoteUpdated),
      );
      if (existing == null) {
        await _db.into(_db.categories).insert(companion);
      } else {
        await (_db.update(
          _db.categories,
        )..where((c) => c.id.equals(existing.id))).write(companion);
      }
    }
  }

  Future<void> _pullAccounts() async {
    final currencyIdByCode = await _currencyIdByCode();
    final rows = await _client.from('accounts').select();
    for (final r in rows) {
      final uuid = r['uuid'] as String;
      if (r['deleted'] == true) {
        await (_db.delete(
          _db.accounts,
        )..where((a) => a.uuid.equals(uuid))).go();
        continue;
      }
      final remoteUpdated = (r['updated_at'] as num?)?.toInt() ?? 0;
      final existing = await (_db.select(
        _db.accounts,
      )..where((a) => a.uuid.equals(uuid))).getSingleOrNull();
      if (existing != null && (existing.updatedAt ?? 0) >= remoteUpdated) {
        continue;
      }
      final companion = AccountsCompanion(
        uuid: Value(uuid),
        name: Value(r['name'] as String?),
        currencyId: Value(currencyIdByCode[r['currency_code'] as String?]),
        iconCodePoint: Value((r['icon_code_point'] as num?)?.toInt()),
        updatedAt: Value(remoteUpdated),
      );
      if (existing == null) {
        await _db.into(_db.accounts).insert(companion);
      } else {
        await (_db.update(
          _db.accounts,
        )..where((a) => a.id.equals(existing.id))).write(companion);
      }
    }
  }

  Future<void> _pullTransactions() async {
    final currencyIdByCode = await _currencyIdByCode();
    final accountIdByUuid = await _accountIdByUuid();
    final categoryIdByUuid = await _categoryIdByUuid();

    final rows = await _client.from('transactions').select();
    for (final r in rows) {
      final uuid = r['uuid'] as String;
      if (r['deleted'] == true) {
        await (_db.delete(
          _db.transactions,
        )..where((t) => t.uuid.equals(uuid))).go();
        continue;
      }
      final remoteUpdated = (r['updated_at'] as num?)?.toInt() ?? 0;
      final existing = await (_db.select(
        _db.transactions,
      )..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
      if (existing != null && (existing.updatedAt ?? 0) >= remoteUpdated) {
        continue;
      }
      final companion = TransactionsCompanion(
        uuid: Value(uuid),
        accountId: Value(accountIdByUuid[r['account_uuid'] as String?]),
        accountDestinationId: Value(
          accountIdByUuid[r['account_destination_uuid'] as String?],
        ),
        categoryId: Value(categoryIdByUuid[r['category_uuid'] as String?]),
        currencyId: Value(currencyIdByCode[r['currency_code'] as String?]),
        amount: Value((r['amount'] as num?)?.toDouble()),
        date: Value(r['date'] as String?),
        note: Value(r['note'] as String?),
        type: Value(r['type'] as String?),
        isCanceled: Value(r['is_canceled'] as bool? ?? false),
        updatedAt: Value(remoteUpdated),
      );
      if (existing == null) {
        await _db.into(_db.transactions).insert(companion);
      } else {
        await (_db.update(
          _db.transactions,
        )..where((t) => t.id.equals(existing.id))).write(companion);
      }
    }
  }

  // ------------------------------------------------------------- lookups ----

  Future<Map<int, String?>> _currencyCodeById() async {
    final rows = await _db.select(_db.currencies).get();
    return {for (final c in rows) c.id: c.code};
  }

  Future<Map<String?, int>> _currencyIdByCode() async {
    final rows = await _db.select(_db.currencies).get();
    return {for (final c in rows) c.code: c.id};
  }

  Future<Map<int, String?>> _accountUuidById() async {
    final rows = await _db.select(_db.accounts).get();
    return {for (final a in rows) a.id: a.uuid};
  }

  Future<Map<String?, int>> _accountIdByUuid() async {
    final rows = await _db.select(_db.accounts).get();
    return {for (final a in rows) a.uuid: a.id};
  }

  Future<Map<int, String?>> _categoryUuidById() async {
    final rows = await _db.select(_db.categories).get();
    return {for (final c in rows) c.id: c.uuid};
  }

  Future<Map<String?, int>> _categoryIdByUuid() async {
    final rows = await _db.select(_db.categories).get();
    return {for (final c in rows) c.uuid: c.id};
  }
}
