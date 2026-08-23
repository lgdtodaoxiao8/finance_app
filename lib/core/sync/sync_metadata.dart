import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Stable, cross-device identity for a syncable row. Generated locally on
/// insert and preserved through sync so the same logical row matches on every
/// device.
String newUuid() => _uuid.v4();

/// Millisecond timestamp used for last-write-wins conflict resolution.
int nowMs() => DateTime.now().millisecondsSinceEpoch;

/// Names of the syncable entities. Also used as remote table names and as the
/// `entity` discriminator in the local tombstones table.
class SyncEntity {
  SyncEntity._();
  static const accounts = 'accounts';
  static const categories = 'categories';
  static const transactions = 'transactions';
  static const budgets = 'budgets';
}
