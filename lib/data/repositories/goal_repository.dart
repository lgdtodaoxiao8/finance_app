import 'package:drift/drift.dart';
import 'package:finance_app/core/app_icons.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/sync/sync_metadata.dart';
import 'package:finance_app/features/goals/data/goal.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

abstract class GoalRepository {
  Future<List<Goal>> getAll();
  Stream<List<Goal>> watchAll();

  Future<int> add({
    required String name,
    double? targetAmount,
    double savedAmount,
    required int color,
    required int iconCodePoint,
    DateTime? deadline,
  });

  Future<void> update({
    required int id,
    required String name,
    double? targetAmount,
    required int color,
    required int iconCodePoint,
    DateTime? deadline,
  });

  /// Adds [delta] to the saved amount (negative to withdraw), clamped at 0.
  Future<void> adjustSaved(int id, double delta);

  Future<void> delete(int id);
}

class DriftGoalRepository implements GoalRepository {
  DriftGoalRepository(this._db);

  final AppDatabase _db;

  Goal _toDomain(GoalRow r) => Goal(
    id: r.id,
    name: r.name ?? '',
    targetAmount: r.targetAmount,
    savedAmount: r.savedAmount,
    color: r.color != null ? Color(r.color!) : Colors.blue,
    icon: appIconData(r.iconCodePoint ?? SolarIconsBold.moneyBag.codePoint),
    deadline: r.deadline == null ? null : DateTime.tryParse(r.deadline!),
  );

  @override
  Future<List<Goal>> getAll() async {
    final rows = await _db.select(_db.goals).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<List<Goal>> watchAll() =>
      _db.select(_db.goals).watch().map((rows) => rows.map(_toDomain).toList());

  @override
  Future<int> add({
    required String name,
    double? targetAmount,
    double savedAmount = 0,
    required int color,
    required int iconCodePoint,
    DateTime? deadline,
  }) {
    return _db
        .into(_db.goals)
        .insert(
          GoalsCompanion.insert(
            name: Value(name),
            targetAmount: Value(targetAmount),
            savedAmount: Value(savedAmount),
            color: Value(color),
            iconCodePoint: Value(iconCodePoint),
            deadline: Value(deadline?.toIso8601String()),
          ),
        );
  }

  @override
  Future<void> update({
    required int id,
    required String name,
    double? targetAmount,
    required int color,
    required int iconCodePoint,
    DateTime? deadline,
  }) async {
    await (_db.update(_db.goals)..where((g) => g.id.equals(id))).write(
      GoalsCompanion(
        name: Value(name),
        targetAmount: Value(targetAmount),
        color: Value(color),
        iconCodePoint: Value(iconCodePoint),
        deadline: Value(deadline?.toIso8601String()),
        updatedAt: Value(nowMs()),
      ),
    );
  }

  @override
  Future<void> adjustSaved(int id, double delta) async {
    await _db.transaction(() async {
      final row = await (_db.select(
        _db.goals,
      )..where((g) => g.id.equals(id))).getSingleOrNull();
      if (row == null) return;
      final next = (row.savedAmount + delta).clamp(0.0, double.infinity);
      await (_db.update(_db.goals)..where((g) => g.id.equals(id))).write(
        GoalsCompanion(savedAmount: Value(next), updatedAt: Value(nowMs())),
      );
    });
  }

  @override
  Future<void> delete(int id) async {
    await _db.transaction(() async {
      final row = await (_db.select(
        _db.goals,
      )..where((g) => g.id.equals(id))).getSingleOrNull();
      await _db.recordTombstone(SyncEntity.goals, row?.uuid);
      await (_db.delete(_db.goals)..where((g) => g.id.equals(id))).go();
    });
  }
}
