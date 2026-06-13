import 'dart:io';

import 'package:ezbookkeeping_desktop/core/constants/database_constants.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/account_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/book_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/category_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/tag_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/transaction_dao.dart';
import 'package:ezbookkeeping_desktop/core/services/account_service.dart';
import 'package:ezbookkeeping_desktop/core/services/bookkeeping_service.dart';
import 'package:ezbookkeeping_desktop/core/services/category_service.dart';
import 'package:ezbookkeeping_desktop/core/services/demo_transaction_seed_service.dart';
import 'package:ezbookkeeping_desktop/core/services/tag_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('向本地数据库写入演示交易', () async {
    if (Platform.environment['DEMO_SEED'] != '1') return;
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

    final accountDao = AccountDao(db);
    final categoryDao = CategoryDao(db);
    final accounts = await accountDao.getAll();
    final categories = await categoryDao.getAll();
    final childCount = categories.where((c) => c.parentId != null).length;
    if (accounts.isEmpty) {
      fail('数据库中没有账户，请先在应用中创建账户');
    }
    if (childCount == 0) {
      fail('数据库中没有二级分类，请先在应用中添加默认分类');
    }

    final existingCount = await TransactionDao(db).count();
    if (existingCount >= 100) {
      return;
    }

    final service = DemoTransactionSeedService(
      database: db,
      bookkeepingService: BookkeepingService(
        database: db,
        transactionDao: TransactionDao(db),
        accountDao: AccountDao(db),
        categoryDao: CategoryDao(db),
      ),
      accountService: AccountService(AccountDao(db)),
      categoryService: CategoryService(CategoryDao(db)),
      tagService: TagService(TagDao(db)),
      bookDao: BookDao(db),
      accountDao: AccountDao(db),
      categoryDao: CategoryDao(db),
      tagDao: TagDao(db),
    );

    final result = await service.seed(targetCount: 100 - existingCount);
    final created = result.when(
      success: (count) => count,
      failure: (error) => fail('生成失败: ${error.message}'),
    );
    expect(created, greaterThanOrEqualTo(90));

    final count = await TransactionDao(db).count();
    expect(count, greaterThanOrEqualTo(created));

    await db.close();
  });
}
