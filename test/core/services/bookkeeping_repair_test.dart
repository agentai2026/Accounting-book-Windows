import 'package:ezbookkeeping_desktop/core/database/daos/account_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/category_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/transaction_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/schema.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/services/bookkeeping_service.dart';
import 'package:ezbookkeeping_desktop/core/utils/import_source_metadata.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> _openTestDatabase() async {
  return openDatabase(
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
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('repairImportedTransactionAccounts', () {
    late Database db;
    late BookkeepingService service;
    late int bookId;
    late int cashAccountId;
    late int wechatAccountId;
    late int categoryId;

    setUp(() async {
      db = await _openTestDatabase();
      service = BookkeepingService(
        database: db,
        transactionDao: TransactionDao(db),
        accountDao: AccountDao(db),
        categoryDao: CategoryDao(db),
      );

      final now = DateTime.now().millisecondsSinceEpoch;
      bookId = await db.insert('books', {
        'uuid': 'book-repair-test',
        'name': '测试账本',
        'created_at': now,
        'updated_at': now,
      });

      cashAccountId = await db.insert('accounts', {
        'uuid': 'acc-cash',
        'book_id': bookId,
        'name': '现金',
        'type': AccountType.cash.value,
        'balance': 0,
        'created_at': now,
        'updated_at': now,
      });

      wechatAccountId = await db.insert('accounts', {
        'uuid': 'acc-wechat',
        'book_id': bookId,
        'name': '微信',
        'type': AccountType.wechat.value,
        'balance': 0,
        'created_at': now,
        'updated_at': now,
      });

      categoryId = await db.insert('categories', {
        'uuid': 'cat-food',
        'name': '餐饮',
        'type': CategoryType.expense.value,
        'created_at': now,
        'updated_at': now,
      });
    });

    tearDown(() async {
      await db.close();
    });

    test('无 @src 元数据时根据 payer 修正支出账户', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final txId = await db.insert('transactions', {
        'uuid': 'tx-legacy-1',
        'book_id': bookId,
        'type': TransactionType.expense.value,
        'amount': 2500,
        'category_id': categoryId,
        'from_account_id': cashAccountId,
        'date': now,
        'payer': '微信零钱',
        'description': '午餐',
        'created_at': now,
        'updated_at': now,
      });

      final repair = await service.repairImportedTransactionAccounts(
        bookId: bookId,
      );
      final repaired = repair.when(
        success: (count) => count,
        failure: (e) => fail(e.message),
      );
      expect(repaired, 1);

      final row = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [txId],
      );
      expect(row.single['from_account_id'], wechatAccountId);
      expect(
        ImportSourceMetadata.parse(row.single['comment'] as String?)
            ?.paymentMethod,
        '微信零钱',
      );
    });

    test('repairAndRecalculateAccountBalances 重算余额', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert('transactions', {
        'uuid': 'tx-legacy-2',
        'book_id': bookId,
        'type': TransactionType.expense.value,
        'amount': 1000,
        'category_id': categoryId,
        'from_account_id': cashAccountId,
        'date': now,
        'payer': '微信零钱',
        'created_at': now,
        'updated_at': now,
      });

      final result = await service.repairAndRecalculateAccountBalances(
        bookId: bookId,
      );
      final data = result.when(
        success: (v) => v,
        failure: (e) => fail(e.message),
      );
      expect(data.repaired, 1);
      expect(data.accountCount, 2);

      final wechat = await db.query(
        'accounts',
        where: 'id = ?',
        whereArgs: [wechatAccountId],
      );
      final cash = await db.query(
        'accounts',
        where: 'id = ?',
        whereArgs: [cashAccountId],
      );
      expect(wechat.single['balance'], -1000);
      expect(cash.single['balance'], 0);
    });

    test('有 @src 元数据时仍按 pay 字段修复', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final metadata = ImportSourceMetadata.encode(
        recordVia: TransactionRecordVia.import,
        paymentMethod: '花呗',
        importSource: '支付宝',
      );
      final huabeiId = await db.insert('accounts', {
        'uuid': 'acc-huabei',
        'book_id': bookId,
        'name': '花呗',
        'type': AccountType.creditCard.value,
        'balance': 0,
        'created_at': now,
        'updated_at': now,
      });

      final txId = await db.insert('transactions', {
        'uuid': 'tx-meta-1',
        'book_id': bookId,
        'type': TransactionType.expense.value,
        'amount': 500,
        'category_id': categoryId,
        'from_account_id': cashAccountId,
        'date': now,
        'comment': metadata,
        'created_at': now,
        'updated_at': now,
      });

      final repair = await service.repairImportedTransactionAccounts(
        bookId: bookId,
      );
      expect(
        repair.when(success: (c) => c, failure: (e) => fail(e.message)),
        1,
      );

      final row = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [txId],
      );
      expect(row.single['from_account_id'], huabeiId);
    });
  });
}
