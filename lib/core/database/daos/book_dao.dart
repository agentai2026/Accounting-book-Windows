import 'package:ezbookkeeping_desktop/core/models/book.dart';
import 'package:sqflite/sqflite.dart';

class BookDao {
  BookDao(this._db);

  final Database _db;
  static const _table = 'books';

  Future<List<Book>> getAll() async {
    final rows = await _db.query(
      _table,
      where: 'deleted_at IS NULL',
      orderBy: 'sort_order ASC, id ASC',
    );
    return rows.map(Book.fromMap).toList();
  }

  Future<Book?> getById(int id) async {
    final rows = await _db.query(
      _table,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Book.fromMap(rows.first);
  }

  Future<Book?> getByUuid(String uuid) async {
    final rows = await _db.query(
      _table,
      where: 'uuid = ? AND deleted_at IS NULL',
      whereArgs: [uuid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Book.fromMap(rows.first);
  }

  Future<int> insert(Book book) async {
    return _db.insert(_table, book.toMap());
  }

  Future<int> update(Book book) async {
    return _db.update(
      _table,
      book.toMap(),
      where: 'id = ?',
      whereArgs: [book.id],
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

  Future<int> countTransactions(int bookId) async {
    final result = await _db.rawQuery(
      '''
      SELECT COUNT(*) as count FROM transactions
      WHERE book_id = ? AND deleted_at IS NULL
      ''',
      [bookId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> maxSortOrder() async {
    final result = await _db.rawQuery(
      '''
      SELECT COALESCE(MAX(sort_order), -1) as max_order FROM $_table
      WHERE deleted_at IS NULL
      ''',
    );
    return Sqflite.firstIntValue(result) ?? -1;
  }
}
