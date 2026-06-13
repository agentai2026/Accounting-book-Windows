import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ezbookkeeping_desktop/core/constants/database_constants.dart';
import 'package:ezbookkeeping_desktop/core/database/default_category_data.dart';
import 'package:ezbookkeeping_desktop/core/database/default_data.dart';
import 'package:ezbookkeeping_desktop/core/database/schema.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  static Future<void> initializeFfi() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _openDatabase();
    return _database!;
  }

  Future<String> getDatabasePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final folderPath = p.join(directory.path, DatabaseConstants.dbFolderName);
    final folder = Directory(folderPath);
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return p.join(folderPath, DatabaseConstants.dbFileName);
  }

  Future<Database> _openDatabase() async {
    final dbPath = await getDatabasePath();
    appLogger.i('数据库路径: $dbPath');

    return openDatabase(
      dbPath,
      version: DatabaseConstants.currentVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute('PRAGMA journal_mode = WAL');
        await db.execute('PRAGMA busy_timeout = 5000');
      },
      onCreate: (db, version) async {
        await _runMigration(db, 1);
        await _runMigration(db, 2);
        if (version >= 8) {
          await _runMigration(db, 8);
        }
        if (version >= 4) {
          await DefaultData.ensureDefaultAccounts(db);
        }
        await DefaultData.seed(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        for (var v = oldVersion + 1; v <= newVersion; v++) {
          await _runMigration(db, v);
        }
      },
    );
  }

  Future<void> _runMigration(Database db, int version) async {
    appLogger.i('执行数据库迁移 v$version');
    if (version == 1) {
      final statements = DatabaseSchema.v1Initial
          .split(';')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);
      for (final statement in statements) {
        await db.execute(statement);
      }
    }
    if (version == 2) {
      await DefaultCategoryData.migrateFromLegacyFlat(db);
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.update(
        'app_settings',
        {'value': '2', 'updated_at': now},
        where: 'key = ?',
        whereArgs: [DatabaseConstants.dbVersionKey],
      );
    }
    if (version == 3) {
      await _addColumnIfNotExists(
        db,
        table: 'transactions',
        column: 'timezone_utc_offset',
        definition: 'INTEGER',
      );
      await _setDbVersion(db, 3);
    }
    if (version == 4) {
      await DefaultData.ensureDefaultAccounts(db);
      await _setDbVersion(db, 4);
    }
    if (version == 5) {
      await _addColumnIfNotExists(
        db,
        table: 'transactions',
        column: 'comment',
        definition: 'TEXT',
      );
      await _setDbVersion(db, 5);
    }
    if (version == 6) {
      await _addColumnIfNotExists(
        db,
        table: 'transactions',
        column: 'payer',
        definition: 'TEXT',
      );
      await _setDbVersion(db, 6);
    }
    if (version == 7) {
      await db.execute('DROP TABLE IF EXISTS scheduled_transactions');
      await _setDbVersion(db, 7);
    }
    if (version == 8) {
      final statements = DatabaseSchema.v8ScheduledTransactions
          .split(';')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);
      for (final statement in statements) {
        if (statement.toUpperCase().contains('SCHEDULED_TRANSACTION_ID')) {
          await _addColumnIfNotExists(
            db,
            table: 'transactions',
            column: 'scheduled_transaction_id',
            definition: 'INTEGER',
          );
        } else {
          await db.execute(statement);
        }
      }
      await _setDbVersion(db, 8);
    }
    if (version == 9) {
      await _addColumnIfNotExists(
        db,
        table: 'loans',
        column: 'book_id',
        definition: 'INTEGER',
      );
      await _addColumnIfNotExists(
        db,
        table: 'loans',
        column: 'account_id',
        definition: 'INTEGER',
      );
      await _addColumnIfNotExists(
        db,
        table: 'loans',
        column: 'exclude_from_io',
        definition: 'INTEGER DEFAULT 1',
      );
      await _addColumnIfNotExists(
        db,
        table: 'loans',
        column: 'exclude_from_budget',
        definition: 'INTEGER DEFAULT 1',
      );
      await _setDbVersion(db, 9);
    }
  }

  Future<void> _setDbVersion(Database db, int version) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'app_settings',
      {'value': '$version', 'updated_at': now},
      where: 'key = ?',
      whereArgs: [DatabaseConstants.dbVersionKey],
    );
  }

  Future<void> _addColumnIfNotExists(
    Database db, {
    required String table,
    required String column,
    required String definition,
  }) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final exists = info.any((row) => row['name'] == column);
    if (exists) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
  }

  Future<int> getDbVersion() async {
    final db = await database;
    final result = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [DatabaseConstants.dbVersionKey],
    );
    if (result.isEmpty) return 0;
    return int.tryParse(result.first['value'] as String? ?? '0') ?? 0;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// 供迁移集成测试使用
  @visibleForTesting
  Future<void> runMigrationForTest(Database db, int version) {
    return _runMigration(db, version);
  }
}
