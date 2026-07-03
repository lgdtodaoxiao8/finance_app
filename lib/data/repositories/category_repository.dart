import 'package:drift/drift.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:flutter/material.dart';

abstract class CategoryRepository {
  Future<List<Category>> getAll();

  Future<int> add({
    required String name,
    required int color,
    required int iconColor,
    required int iconCodePoint,
  });

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
    categoryIcon: IconData(
      row.iconCodePoint ?? Icons.help_outline.codePoint,
      fontFamily: 'MaterialIcons',
    ),
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
  }) {
    return _db.into(_db.categories).insert(
      CategoriesCompanion.insert(
        name: Value(name),
        color: Value(color),
        iconColor: Value(iconColor),
        iconCodePoint: Value(iconCodePoint),
      ),
    );
  }

  @override
  Stream<List<Category>> watchAll() {
    return _db.select(_db.categories).watch().map(
      (rows) => rows.map(_toDomain).toList(),
    );
  }
}
