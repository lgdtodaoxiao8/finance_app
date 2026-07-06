import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/sync/sync_metadata.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  test('inserted syncable rows get a uuid and updatedAt', () async {
    final repo = DriftCategoryRepository(db);
    final id = await repo.add(
      name: 'Coffee',
      color: 1,
      iconColor: 2,
      iconCodePoint: 3,
    );

    final row = await (db.select(
      db.categories,
    )..where((c) => c.id.equals(id))).getSingle();

    expect(row.uuid, isNotNull);
    expect(row.uuid, isNotEmpty);
    expect(row.updatedAt, isNotNull);
  });

  test('deleting a syncable row records a tombstone with its uuid', () async {
    final repo = DriftCategoryRepository(db);
    final id = await repo.add(
      name: 'Coffee',
      color: 1,
      iconColor: 2,
      iconCodePoint: 3,
    );
    final row = await (db.select(
      db.categories,
    )..where((c) => c.id.equals(id))).getSingle();

    await repo.delete(id);

    final tombstones = await db.select(db.tombstones).get();
    expect(tombstones, hasLength(1));
    expect(tombstones.single.entity, SyncEntity.categories);
    expect(tombstones.single.uuid, row.uuid);

    // The row itself is gone locally.
    final remaining = await db.select(db.categories).get();
    expect(remaining, isEmpty);
  });
}
