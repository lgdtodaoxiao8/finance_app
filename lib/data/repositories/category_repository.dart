import 'package:solar_icons/solar_icons.dart';
import 'package:drift/drift.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/sync/sync_metadata.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/core/app_icons.dart';

abstract class CategoryRepository {
  Future<List<Category>> getAll();

  Future<int> add({
    required String name,
    required int color,
    required int iconColor,
    required int iconCodePoint,
    required String kind,
  });

  /// Number of transactions using this category — used to block deletion of a
  /// category still in use.
  Future<void> update({
    required int id,
    required String name,
    required int color,
    required int iconColor,
    required int iconCodePoint,
    required String kind,
  });

  Future<int> transactionCount(int categoryId);

  Future<void> delete(int id);

  Stream<List<Category>> watchAll();
}

class DriftCategoryRepository implements CategoryRepository {
  DriftCategoryRepository(this._db);

  final AppDatabase _db;

  Category _toDomain(CategoryRow row) => Category(
    categoryId: row.id,
    categoryName: row.name ?? '',
    categoryColor: Color(row.color ?? Colors.grey.toARGB32()),
    categoryIconColor: Color(row.iconColor ?? Colors.white.toARGB32()),
    categoryIcon: appIconData(
      row.iconCodePoint ?? SolarIconsBold.questionCircle.codePoint,
    ),
    categoryKind: row.kind,
  );

  @override
  Future<List<Category>> getAll() async {
    final rows = await _db.select(_db.categories).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<int> add({
    required String name,
    required int color,
    required int iconColor,
    required int iconCodePoint,
    required String kind,
  }) {
    return _db
        .into(_db.categories)
        .insert(
          CategoriesCompanion.insert(
            name: Value(name),
            color: Value(color),
            iconColor: Value(iconColor),
            iconCodePoint: Value(iconCodePoint),
            kind: Value(kind),
          ),
        );
  }

  @override
  Future<void> update({
    required int id,
    required String name,
    required int color,
    required int iconColor,
    required int iconCodePoint,
    required String kind,
  }) async {
    await (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(name),
        color: Value(color),
        iconColor: Value(iconColor),
        iconCodePoint: Value(iconCodePoint),
        kind: Value(kind),
        // Stamped so cloud sync (LWW on updated_at) picks the edit up.
        updatedAt: Value(nowMs()),
      ),
    );
  }

  @override
  Future<int> transactionCount(int categoryId) async {
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM transactions WHERE category_id = ?',
          variables: [Variable<int>(categoryId)],
          readsFrom: {_db.transactions},
        )
        .getSingle();
    return row.read<int>('c');
  }

  @override
  Future<void> delete(int id) async {
    await _db.transaction(() async {
      final row = await (_db.select(
        _db.categories,
      )..where((c) => c.id.equals(id))).getSingleOrNull();
      await _db.recordTombstone(SyncEntity.categories, row?.uuid);
      await (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
    });
  }

  @override
  Stream<List<Category>> watchAll() {
    return _db
        .select(_db.categories)
        .watch()
        .map(
          (rows) => rows.map(_toDomain).toList(),
        );
  }
}
