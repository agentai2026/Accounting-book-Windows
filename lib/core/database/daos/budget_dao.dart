import 'package:ezbookkeeping_desktop/core/models/budget.dart';
import 'package:sqflite/sqflite.dart';

class BudgetDao {
  BudgetDao(this._db);

  final Database _db;
  static const _table = 'budgets';

  Future<List<Budget>> getAll({int? bookId}) async {
    final rows = await _db.query(
      _table,
      where: bookId != null
          ? 'book_id = ? AND deleted_at IS NULL'
          : 'deleted_at IS NULL',
      whereArgs: bookId != null ? [bookId] : null,
      orderBy: 'id DESC',
    );
    return rows.map(Budget.fromMap).toList();
  }

  Future<int> insert(Budget budget) async {
    return _db.insert(_table, budget.toMap());
  }

  Future<int> update(Budget budget) async {
    return _db.update(
      _table,
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<Budget?> getById(int id) async {
    final rows = await _db.query(
      _table,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Budget.fromMap(rows.first);
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
