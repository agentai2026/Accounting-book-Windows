import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ezbookkeeping_desktop/core/database/daos/account_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/category_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/transaction_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/database_helper.dart';
import 'package:ezbookkeeping_desktop/core/database/default_category_data.dart';
import 'package:ezbookkeeping_desktop/core/database/default_data.dart';
import 'package:ezbookkeeping_desktop/core/database/schema.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/import_preview_row.dart';
import 'package:ezbookkeeping_desktop/core/services/bookkeeping_service.dart';
import 'package:ezbookkeeping_desktop/core/services/export_service.dart';
import 'package:ezbookkeeping_desktop/core/services/import_column_mapping_config.dart';
import 'package:ezbookkeeping_desktop/core/services/transaction_import_service.dart';

Future<Database> _openTestDatabase() async {
  return openDatabase(
    inMemoryDatabasePath,
    version: 1,
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    },
    onCreate: (db, version) async {
      for (final statement in DatabaseSchema.v1Initial
          .split(';')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)) {
        await db.execute(statement);
      }
      await DefaultData.seed(db);
      await DefaultCategoryData.seedAll(db);
      await DefaultData.ensureDefaultAccounts(db);
    },
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late TransactionImportService service;
  late int bookId;
  late Database db;

  setUp(() async {
    db = await _openTestDatabase();
    final dbHelper = DatabaseHelper.instance;
    final transactionDao = TransactionDao(db);
    final accountDao = AccountDao(db);
    final categoryDao = CategoryDao(db);
    service = TransactionImportService(
      bookkeeping: BookkeepingService(
        database: db,
        transactionDao: transactionDao,
        accountDao: accountDao,
        categoryDao: categoryDao,
      ),
      accountDao: accountDao,
      categoryDao: categoryDao,
      exportService: ExportService(
        transactionDao: transactionDao,
        accountDao: accountDao,
        categoryDao: categoryDao,
        databaseHelper: dbHelper,
      ),
    );
    final books = await db.query('books', limit: 1);
    bookId = books.first['id'] as int;
  });

  tearDown(() async {
    await db.close();
  });

  Future<ImportParseResult> parseRows(List<List<String>> rows) async {
    final mapping = ImportColumnMappingConfig.autoDetect(
      rows: rows,
      headerRowIndex: 0,
    );
    final result = await service.parseFromMappedRows(
      bookId: bookId,
      rawRows: rows,
      mapping: mapping,
    );
    expect(result.isSuccess, isTrue, reason: result.when(
      success: (_) => '',
      failure: (e) => e.message,
    ));
    return result.when(success: (d) => d, failure: (_) => throw StateError(''));
  }

  test('微信支付成功行可解析为可导入', () async {
    const rows = [
      [
        '交易时间',
        '交易类型',
        '交易对方',
        '商品',
        '收/支',
        '金额(元)',
        '支付方式',
        '当前状态',
      ],
      [
        '2026/06/10 12:30:00',
        '商户消费',
        '山姆会员商店',
        '商品',
        '支出',
        '400.30',
        '招商银行信用卡',
        '支付成功',
      ],
    ];

    final data = await parseRows(rows);
    expect(data.skippedByRule, 0);
    expect(data.rows.where((r) => r.valid).length, 1);
    expect(data.rows.first.type, TransactionType.expense);
    expect(data.rows.first.amountCents, 40030);
  });

  test('本应用导出格式无状态列可解析', () async {
    const rows = [
      ['日期', '类型', '金额', '分类', '账户', '付款人', '备注'],
      ['2026/06/10 12:30', '支出', '35.00', '食品', '微信', '美团', '午餐'],
    ];

    final data = await parseRows(rows);
    expect(data.skippedByRule, 0);
    expect(data.rows.where((r) => r.valid).length, 1);
  });

  test('交易关闭仍被规则跳过', () async {
    const rows = [
      ['交易时间', '收/支', '金额(元)', '交易状态', '交易分类'],
      ['2026/06/10 12:30', '支出', '10.00', '交易关闭', '餐饮'],
    ];

    final data = await parseRows(rows);
    expect(data.skippedByRule, 1);
    expect(data.rows.where((r) => r.valid).length, 0);
    expect(data.skippedCount, 1);
    expect(data.rows.single.skipReason, '交易关闭');
    expect(data.rows.single.amountCents, 1000);
  });
}
