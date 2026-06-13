import 'package:ezbookkeeping_desktop/core/models/scheduled_transaction.dart';
import 'package:sqflite/sqflite.dart';

class ScheduledTransactionDao {
  ScheduledTransactionDao(this._db);

  final Database _db;
  static const _table = 'scheduled_transactions';

  Future<List<ScheduledTransaction>> getAll({int? bookId}) async {
    final conditions = <String>['deleted_at IS NULL'];
    final args = <Object?>[];
    if (bookId != null) {
      conditions.add('book_id = ?');
      args.add(bookId);
    }
    final rows = await _db.query(
      _table,
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'next_run_at ASC, id ASC',
    );
    return rows.map(ScheduledTransaction.fromMap).toList();
  }

  Future<ScheduledTransaction?> getById(int id) async {
    final rows = await _db.query(
      _table,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ScheduledTransaction.fromMap(rows.first);
  }

  Future<List<ScheduledTransaction>> getDueBefore(DateTime before) async {
    final rows = await _db.query(
      _table,
      where:
          'deleted_at IS NULL AND is_paused = 0 AND next_run_at <= ?',
      whereArgs: [before.millisecondsSinceEpoch],
      orderBy: 'next_run_at ASC, id ASC',
    );
    return rows.map(ScheduledTransaction.fromMap).toList();
  }

  Future<int> insert(ScheduledTransaction item) async {
    return _db.insert(_table, item.toMap());
  }

  Future<int> update(ScheduledTransaction item) async {
    return _db.update(
      _table,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> softDelete(int id, DateTime deletedAt) async {
    return _db.update(
      _table,
      {
        'deleted_at': deletedAt.millisecondsSinceEpoch,
        'updated_at': deletedAt.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
