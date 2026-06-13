import 'dart:io';

import 'package:ezbookkeeping_desktop/core/constants/database_constants.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/account_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/category_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/transaction_dao.dart';
import 'package:ezbookkeeping_desktop/core/services/bookkeeping_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('清空本地数据库全部交易', () async {
    if (Platform.environment['CLEAR_TRANSACTIONS'] != '1') return;
    final docs = Platform.environment['USERPROFILE'];
    if (docs == null) {
      fail('无法定位用户文档目录');
    }
    final dbPath = p.join(
      docs,
      'Documents',
      DatabaseConstants.dbFolderName,
      DatabaseConstants.dbFileName,
    );
    if (!File(dbPath).existsSync()) {
      fail('数据库不存在: $dbPath');
    }

    final db = await databaseFactoryFfi.openDatabase(dbPath);
    final transactionDao = TransactionDao(db);
    final beforeCount = await transactionDao.count();
    if (beforeCount == 0) {
      await db.close();
      return;
    }

    final service = BookkeepingService(
      database: db,
      transactionDao: transactionDao,
      accountDao: AccountDao(db),
      categoryDao: CategoryDao(db),
    );

    final result = await service.deleteAllTransactions();
    final deleted = result.when(
      success: (count) => count,
      failure: (error) => fail('清空失败: ${error.message}'),
    );

    expect(deleted, beforeCount);
    expect(await transactionDao.count(), 0);

    await db.close();
  });
}
