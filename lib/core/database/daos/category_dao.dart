import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:sqflite/sqflite.dart';

class CategoryDao {
  CategoryDao(this._db);

  final Database _db;
  static const _table = 'categories';

  Future<List<Category>> getAll({CategoryType? type}) async {
    final rows = await _db.query(
      _table,
      where: type != null
          ? 'type = ? AND deleted_at IS NULL'
          : 'deleted_at IS NULL',
      whereArgs: type != null ? [type.value] : null,
      orderBy: 'sort_order ASC, id ASC',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<Category?> getById(int id) async {
    final rows = await _db.query(
      _table,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  Future<Category?> getByUuid(String uuid) async {
    final rows = await _db.query(
      _table,
      where: 'uuid = ? AND deleted_at IS NULL',
      whereArgs: [uuid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  Future<int> insert(Category category) async {
    return _db.insert(_table, category.toMap());
  }

  Future<int> update(Category category) async {
    return _db.update(
      _table,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
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

  Future<int> countUsage(int categoryId) async {
    final result = await _db.rawQuery(
      '''
      SELECT COUNT(*) as count FROM transactions
      WHERE deleted_at IS NULL AND category_id = ?
      ''',
      [categoryId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countChildren(int parentId) async {
    final result = await _db.rawQuery(
      '''
      SELECT COUNT(*) as count FROM $_table
      WHERE parent_id = ? AND deleted_at IS NULL
      ''',
      [parentId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> updateSortOrders(List<int> orderedIds) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction((txn) async {
      for (var i = 0; i < orderedIds.length; i++) {
        await txn.update(
          _table,
          {
            'sort_order': i,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [orderedIds[i]],
        );
      }
    });
  }

  Future<int> maxSortOrder({
    required CategoryType type,
    int? parentId,
  }) async {
    final conditions = <String>['type = ?', 'deleted_at IS NULL'];
    final args = <Object?>[type.value];

    if (parentId == null) {
      conditions.add('parent_id IS NULL');
    } else {
      conditions.add('parent_id = ?');
      args.add(parentId);
    }

    final result = await _db.rawQuery(
      '''
      SELECT COALESCE(MAX(sort_order), -1) as max_order FROM $_table
      WHERE ${conditions.join(' AND ')}
      ''',
      args,
    );
    return Sqflite.firstIntValue(result) ?? -1;
  }
}
