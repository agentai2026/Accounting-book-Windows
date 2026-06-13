import 'package:ezbookkeeping_desktop/core/constants/database_constants.dart';
import 'package:ezbookkeeping_desktop/core/constants/default_account_presets.dart';
import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class DefaultData {
  DefaultData._();

  static const _uuid = Uuid();

  /// Adds missing preset accounts for existing databases (e.g. after upgrade).
  static Future<void> ensureDefaultAccounts(Database db) async {
    final bookRows = await db.query(
      'books',
      where: 'deleted_at IS NULL',
      orderBy: 'sort_order ASC',
      limit: 1,
    );
    if (bookRows.isEmpty) return;

    final bookId = bookRows.first['id'] as int;
    final existingRows = await db.query(
      'accounts',
      columns: ['name', 'sort_order'],
      where: 'book_id = ? AND deleted_at IS NULL',
      whereArgs: [bookId],
    );
    final existingNames =
        existingRows.map((row) => row['name'] as String).toSet();
    var nextSortOrder = existingRows
        .map((row) => row['sort_order'] as int? ?? 0)
        .fold<int>(-1, (max, value) => value > max ? value : max);

    final now = DateTime.now();
    for (final item in kDefaultAccountPresets) {
      if (existingNames.contains(item.name)) continue;
      nextSortOrder += 1;
      await db.insert('accounts', Account(
        uuid: _uuid.v4(),
        bookId: bookId,
        name: item.name,
        type: item.type,
        balance: 0,
        currency: item.currency,
        icon: item.icon,
        sortOrder: nextSortOrder,
        createdAt: now,
        updatedAt: now,
      ).toMap());
    }

    for (final item in kDefaultAccountPresets) {
      await db.update(
        'accounts',
        {
          'icon': item.icon,
          'updated_at': now.millisecondsSinceEpoch,
        },
        where:
            'book_id = ? AND name = ? AND deleted_at IS NULL AND (icon IS NULL OR icon = \'\')',
        whereArgs: [bookId, item.name],
      );
      await db.update(
        'accounts',
        {
          'type': item.type.value,
          'updated_at': now.millisecondsSinceEpoch,
        },
        where:
            'book_id = ? AND name = ? AND deleted_at IS NULL AND type = ?',
        whereArgs: [bookId, item.name, AccountType.none.value],
      );
    }
  }

  static Future<void> seed(Database db) async {
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    final bookUuid = _uuid.v4();
    final bookId =     await db.insert('books', {
      'uuid': bookUuid,
      'name': '默认账本',
      'color': '#2196F3',
      'sort_order': 0,
      'created_at': nowMs,
      'updated_at': nowMs,
    });

    await db.insert('app_settings', {
      'key': 'db_version',
      'value': '${DatabaseConstants.currentVersion}',
      'updated_at': nowMs,
    });

    await db.insert('app_settings', {
      'key': 'default_book_uuid',
      'value': bookUuid,
      'updated_at': nowMs,
    });
  }
}
