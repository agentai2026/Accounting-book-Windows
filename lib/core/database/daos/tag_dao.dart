import 'package:ezbookkeeping_desktop/core/models/tag.dart';
import 'package:sqflite/sqflite.dart';

class TagDao {
  TagDao(this._db);

  final Database _db;
  static const _table = 'tags';

  Future<List<Tag>> getAll() async {
    final rows = await _db.query(
      _table,
      where: 'deleted_at IS NULL',
      orderBy: 'name ASC',
    );
    return rows.map(Tag.fromMap).toList();
  }

  Future<Tag?> getById(int id) async {
    final rows = await _db.query(
      _table,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Tag.fromMap(rows.first);
  }

  Future<Tag?> findByName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final rows = await _db.query(
      _table,
      where: 'LOWER(name) = LOWER(?) AND deleted_at IS NULL',
      whereArgs: [trimmed],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Tag.fromMap(rows.first);
  }

  Future<Tag?> findByNameIncludingDeleted(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final rows = await _db.query(
      _table,
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [trimmed],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Tag.fromMap(rows.first);
  }

  Future<void> restore(int id, DateTime updatedAt) async {
    await _db.update(
      _table,
      {
        'deleted_at': null,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insert(Tag tag) async {
    return _db.insert(_table, tag.toMap());
  }

  Future<int> update(Tag tag) async {
    return _db.update(
      _table,
      tag.toMap(),
      where: 'id = ?',
      whereArgs: [tag.id],
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

  Future<int> countUsage(int tagId) async {
    final result = await _db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM transaction_tags tt
      INNER JOIN transactions tr ON tr.id = tt.transaction_id
      WHERE tt.tag_id = ?
        AND tr.deleted_at IS NULL
      ''',
      [tagId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 各标签被有效交易引用的次数
  Future<Map<int, int>> countUsageMap() async {
    final rows = await _db.rawQuery(
      '''
      SELECT tt.tag_id AS tag_id, COUNT(*) AS count
      FROM transaction_tags tt
      INNER JOIN transactions tr ON tr.id = tt.transaction_id
      WHERE tr.deleted_at IS NULL
      GROUP BY tt.tag_id
      ''',
    );
    return {
      for (final row in rows)
        row['tag_id'] as int: (row['count'] as num?)?.toInt() ?? 0,
    };
  }

  /// 清理指向已删除或不存在账单的标签关联
  Future<int> purgeOrphanedTransactionLinks() async {
    return _db.rawDelete(
      '''
      DELETE FROM transaction_tags
      WHERE NOT EXISTS (
        SELECT 1 FROM transactions tr
        WHERE tr.id = transaction_tags.transaction_id
          AND tr.deleted_at IS NULL
      )
      ''',
    );
  }

  Future<Map<int, List<String>>> getTagNamesByTransactionIds(
    List<int> transactionIds,
  ) async {
    if (transactionIds.isEmpty) return {};

    final placeholders = List.filled(transactionIds.length, '?').join(',');
    final rows = await _db.rawQuery(
      '''
      SELECT tt.transaction_id AS transaction_id, t.name AS name
      FROM transaction_tags tt
      INNER JOIN tags t ON t.id = tt.tag_id
      WHERE tt.transaction_id IN ($placeholders)
        AND t.deleted_at IS NULL
      ORDER BY t.name ASC
      ''',
      transactionIds,
    );

    final map = <int, List<String>>{};
    for (final row in rows) {
      final id = row['transaction_id'] as int;
      final name = row['name'] as String;
      map.putIfAbsent(id, () => []).add(name);
    }
    return map;
  }

  Future<List<int>> getTagIdsByTransactionId(int transactionId) async {
    final rows = await _db.query(
      'transaction_tags',
      columns: ['tag_id'],
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    return rows.map((row) => row['tag_id'] as int).toList();
  }

  Future<bool> linkTagToTransaction(
    int transactionId,
    int tagId, {
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? _db;
    final existing = await db.query(
      'transaction_tags',
      where: 'transaction_id = ? AND tag_id = ?',
      whereArgs: [transactionId, tagId],
      limit: 1,
    );
    if (existing.isNotEmpty) return false;
    await db.insert('transaction_tags', {
      'transaction_id': transactionId,
      'tag_id': tagId,
    });
    return true;
  }

  Future<bool> unlinkTagFromTransaction(
    int transactionId,
    int tagId, {
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? _db;
    final deleted = await db.delete(
      'transaction_tags',
      where: 'transaction_id = ? AND tag_id = ?',
      whereArgs: [transactionId, tagId],
    );
    return deleted > 0;
  }
}
