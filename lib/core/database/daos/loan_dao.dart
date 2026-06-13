import 'package:ezbookkeeping_desktop/core/models/loan.dart';
import 'package:sqflite/sqflite.dart';

class LoanDao {
  LoanDao(this._db);

  final Database _db;
  static const _table = 'loans';

  Future<List<Loan>> getAll({int? bookId}) async {
    if (bookId == null) {
      return getAllUnfiltered();
    }
    final rows = await _db.query(
      _table,
      where: 'deleted_at IS NULL AND (book_id IS NULL OR book_id = ?)',
      whereArgs: [bookId],
      orderBy: 'date DESC',
    );
    return rows.map(Loan.fromMap).toList();
  }

  Future<List<Loan>> getAllUnfiltered() async {
    final rows = await _db.query(
      _table,
      where: 'deleted_at IS NULL',
      orderBy: 'date DESC',
    );
    return rows.map(Loan.fromMap).toList();
  }

  Future<Loan?> getById(int id) async {
    final rows = await _db.query(
      _table,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Loan.fromMap(rows.first);
  }

  Future<int> insert(Loan loan) async {
    return _db.insert(_table, loan.toMap());
  }

  Future<int> update(Loan loan) async {
    return _db.update(
      _table,
      loan.toMap(),
      where: 'id = ?',
      whereArgs: [loan.id],
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
