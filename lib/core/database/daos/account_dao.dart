import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:sqflite/sqflite.dart';

class AccountDao {
  AccountDao(this._db);

  final Database _db;
  static const _table = 'accounts';

  Future<List<Account>> getAll({int? bookId}) async {
    final rows = await _db.query(
      _table,
      where: bookId != null
          ? 'book_id = ? AND deleted_at IS NULL'
          : 'deleted_at IS NULL',
      whereArgs: bookId != null ? [bookId] : null,
      orderBy: 'sort_order ASC, id ASC',
    );
    return rows.map(Account.fromMap).toList();
  }

  Future<Account?> getById(int id) async {
    final rows = await _db.query(
      _table,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Account.fromMap(rows.first);
  }

  Future<Account?> getByUuid(String uuid) async {
    final rows = await _db.query(
      _table,
      where: 'uuid = ? AND deleted_at IS NULL',
      whereArgs: [uuid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Account.fromMap(rows.first);
  }

  Future<int> insert(Account account) async {
    return _db.insert(_table, account.toMap());
  }

  Future<int> update(Account account) async {
    return _db.update(
      _table,
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> updateBalance(int id, int balance, DateTime updatedAt) async {
    return _db.update(
      _table,
      {
        'balance': balance,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
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

  Future<int> countUsage(int accountId) async {
    final result = await _db.rawQuery(
      '''
      SELECT COUNT(*) as count FROM transactions
      WHERE deleted_at IS NULL
        AND (from_account_id = ? OR to_account_id = ?)
      ''',
      [accountId, accountId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> maxSortOrder({required int bookId}) async {
    final result = await _db.rawQuery(
      '''
      SELECT COALESCE(MAX(sort_order), -1) as max_order FROM $_table
      WHERE book_id = ? AND deleted_at IS NULL
      ''',
      [bookId],
    );
    return Sqflite.firstIntValue(result) ?? -1;
  }
}
