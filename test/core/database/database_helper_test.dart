import 'package:ezbookkeeping_desktop/core/database/schema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('数据库 Schema 创建成功', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        final statements = DatabaseSchema.v1Initial
            .split(';')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty);
        for (final statement in statements) {
          await database.execute(statement);
        }
      },
    );

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
    );
    final tableNames = tables.map((t) => t['name'] as String).toList();

    expect(tableNames, contains('books'));
    expect(tableNames, contains('accounts'));
    expect(tableNames, contains('categories'));
    expect(tableNames, contains('transactions'));
    expect(tableNames, contains('app_settings'));

    await db.close();
  });
}
