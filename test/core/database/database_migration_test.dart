import 'dart:io';

import 'package:ezbookkeeping_desktop/core/constants/database_constants.dart';
import 'package:ezbookkeeping_desktop/core/database/database_helper.dart';
import 'package:ezbookkeeping_desktop/core/database/default_data.dart';
import 'package:ezbookkeeping_desktop/core/database/schema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('fresh install reaches schema version 9', () async {
    final dir = await Directory.systemTemp.createTemp('ezb_db_v9_');
    final dbPath = p.join(dir.path, DatabaseConstants.dbFileName);

    final db = await openDatabase(
      dbPath,
      version: DatabaseConstants.currentVersion,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await database.execute('PRAGMA journal_mode = WAL');
        await database.execute('PRAGMA busy_timeout = 5000');
      },
      onCreate: (database, version) async {
        final helper = DatabaseHelper.instance;
        await helper.runMigrationForTest(database, 1);
        await helper.runMigrationForTest(database, 2);
        if (version >= 8) {
          await helper.runMigrationForTest(database, 8);
        }
        if (version >= 4) {
          await DefaultData.ensureDefaultAccounts(database);
        }
        await DefaultData.seed(database);
      },
    );

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
    );
    final tableNames = tables.map((row) => row['name'] as String).toList();

    expect(tableNames, contains('scheduled_transactions'));
    expect(tableNames, contains('loans'));

    final txInfo = await db.rawQuery('PRAGMA table_info(transactions)');
    final txColumns = txInfo.map((row) => row['name'] as String).toSet();
    expect(txColumns, contains('timezone_utc_offset'));
    expect(txColumns, contains('comment'));
    expect(txColumns, contains('payer'));

    final loanInfo = await db.rawQuery('PRAGMA table_info(loans)');
    final loanColumns = loanInfo.map((row) => row['name'] as String).toSet();
    expect(loanColumns, contains('book_id'));
    expect(loanColumns, contains('account_id'));

    await db.close();
    await dir.delete(recursive: true);
  });

  test('upgrade from v1 schema to v9', () async {
    final dir = await Directory.systemTemp.createTemp('ezb_db_upgrade_');
    final dbPath = p.join(dir.path, DatabaseConstants.dbFileName);
    final helper = DatabaseHelper.instance;

    var db = await openDatabase(
      dbPath,
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        await helper.runMigrationForTest(database, 1);
        await DefaultData.seed(database);
      },
    );
    await db.close();

    db = await openDatabase(
      dbPath,
      version: DatabaseConstants.currentVersion,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        for (var v = oldVersion + 1; v <= newVersion; v++) {
          await helper.runMigrationForTest(database, v);
        }
      },
    );

    final versionRow = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [DatabaseConstants.dbVersionKey],
    );
    expect(versionRow.first['value'], '9');

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
    );
    final tableNames = tables.map((row) => row['name'] as String).toList();
    expect(tableNames, contains('scheduled_transactions'));

    await db.close();
    await dir.delete(recursive: true);
  });
}
