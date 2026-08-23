import 'package:drift/drift.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/sync/sync_metadata.dart';
import 'package:finance_app/features/budget/data/budget.dart';

/// Monthly budgets: one optional overall limit (categoryId null) plus any number
/// of per-category limits. Keyed by category, so setting a budget upserts.
abstract class BudgetRepository {
  Future<List<Budget>> getAll();
  Stream<List<Budget>> watchAll();

  /// Sets (creates or updates) the limit for [categoryId] (null = overall).
  Future<void> setBudget({int? categoryId, required double amount});

  /// Removes the limit for [categoryId] (null = overall), if any.
  Future<void> removeBudget({int? categoryId});
}

class DriftBudgetRepository implements BudgetRepository {
  DriftBudgetRepository(this._db);

  final AppDatabase _db;

  Budget _toDomain(BudgetRow r) =>
      Budget(id: r.id, categoryId: r.categoryId, amount: r.amount ?? 0);

  Expression<bool> _match(Budgets b, int? categoryId) => categoryId == null
      ? b.categoryId.isNull()
      : b.categoryId.equals(categoryId);

  @override
  Future<List<Budget>> getAll() async {
    final rows = await _db.select(_db.budgets).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<List<Budget>> watchAll() =>
      _db.select(_db.budgets).watch().map((rows) => rows.map(_toDomain).toList());

  @override
  Future<void> setBudget({int? categoryId, required double amount}) async {
    final existing = await (_db.select(
      _db.budgets,
    )..where((b) => _match(b, categoryId))).getSingleOrNull();
    if (existing != null) {
      await (_db.update(_db.budgets)..where((b) => b.id.equals(existing.id)))
          .write(
            BudgetsCompanion(amount: Value(amount), updatedAt: Value(nowMs())),
          );
    } else {
      await _db
          .into(_db.budgets)
          .insert(
            BudgetsCompanion.insert(
              categoryId: Value(categoryId),
              amount: Value(amount),
            ),
          );
    }
  }

  @override
  Future<void> removeBudget({int? categoryId}) async {
    await _db.transaction(() async {
      final existing = await (_db.select(
        _db.budgets,
      )..where((b) => _match(b, categoryId))).getSingleOrNull();
      if (existing == null) return;
      await _db.recordTombstone(SyncEntity.budgets, existing.uuid);
      await (_db.delete(_db.budgets)..where((b) => b.id.equals(existing.id)))
          .go();
    });
  }
}
