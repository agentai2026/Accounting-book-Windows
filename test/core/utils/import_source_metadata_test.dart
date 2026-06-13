import 'package:flutter_test/flutter_test.dart';



import 'package:ezbookkeeping_desktop/core/utils/import_source_metadata.dart';

import 'package:ezbookkeeping_desktop/core/utils/transaction_display_utils.dart';

import 'package:ezbookkeeping_desktop/core/models/enums.dart';

import 'package:ezbookkeeping_desktop/core/models/transaction.dart';



void main() {

  test('encode and parse payment method and import source', () {

    final encoded = ImportSourceMetadata.encode(

      recordVia: TransactionRecordVia.import,

      categoryName: '商户消费',

      direction: '支出',

      status: '支付成功',

      paymentMethod: '农业银行储蓄卡(6579)',

      importSource: '支付宝',

    );

    expect(encoded, contains('via=import'));

    expect(encoded, contains('pay=农业银行储蓄卡(6579)'));

    expect(encoded, contains('src=支付宝'));



    final meta = ImportSourceMetadata.parse(encoded);

    expect(meta?.recordVia, TransactionRecordVia.import);

    expect(meta?.paymentMethod, '农业银行储蓄卡(6579)');

    expect(meta?.importSource, '支付宝');

  });



  test('resolveAccountLabel prefers import payment method', () {

    final now = DateTime.now();

    final t = Transaction(

      uuid: 'u1',

      bookId: 1,

      type: TransactionType.expense,

      amount: 1366,

      categoryId: 1,

      date: now,

      comment: ImportSourceMetadata.encode(

        recordVia: TransactionRecordVia.import,

        paymentMethod: '微信零钱',

        importSource: '微信',

      ),

      createdAt: now,

      updatedAt: now,

    );



    expect(

      TransactionDisplayUtils.resolveAccountLabel(

        transaction: t,

        mappedAccountName: '现金',

      ),

      '微信零钱',

    );

    expect(TransactionDisplayUtils.resolveImportSourceLabel(t), '微信');

    expect(

      TransactionDisplayUtils.resolveRecordMethodDetail(t),

      '微信账单导入',

    );

  });



  test('resolveRemark uses description not @src metadata', () {

    final now = DateTime.now();

    final t = Transaction(

      uuid: 'u2',

      bookId: 1,

      type: TransactionType.expense,

      amount: 100,

      categoryId: 1,

      date: now,

      description: 'HeroSMS top up',

      comment: '@src:via=import;cat=商户消费;dir=支出;pay=微信零钱;src=微信@',

      createdAt: now,

      updatedAt: now,

    );



    expect(TransactionDisplayUtils.resolveRemark(t), 'HeroSMS top up');

  });



  test('resolveRecordMethodDetail for manual and ai', () {

    final now = DateTime.now();



    final manual = Transaction(

      uuid: 'm1',

      bookId: 1,

      type: TransactionType.expense,

      amount: 100,

      categoryId: 1,

      date: now,

      comment: ImportSourceMetadata.encode(

        recordVia: TransactionRecordVia.manual,

        paymentMethod: '现金',

      ),

      createdAt: now,

      updatedAt: now,

    );

    expect(

      TransactionDisplayUtils.resolveRecordMethodDetail(manual),

      '手动记账',

    );



    final ai = Transaction(

      uuid: 'a1',

      bookId: 1,

      type: TransactionType.expense,

      amount: 100,

      categoryId: 1,

      date: now,

      comment: ImportSourceMetadata.encode(

        recordVia: TransactionRecordVia.ai,

        paymentMethod: '农业银行储蓄卡(6579)',

      ),

      createdAt: now,

      updatedAt: now,

    );

    expect(TransactionDisplayUtils.resolveRecordMethodDetail(ai), 'AI记账');

    expect(

      TransactionDisplayUtils.resolveAccountLabel(

        transaction: ai,

        mappedAccountName: '银行卡',

      ),

      '农业银行储蓄卡(6579)',

    );

  });



  test('resolveAccountLabel enriches generic bank card from remark', () {

    final now = DateTime.now();

    final t = Transaction(

      uuid: 'u3',

      bookId: 1,

      type: TransactionType.expense,

      amount: 100,

      categoryId: 1,

      date: now,

      description: '商业服务 · DeepSeek-API服务(132******17)',

      createdAt: now,

      updatedAt: now,

    );



    expect(

      TransactionDisplayUtils.resolveAccountLabel(

        transaction: t,

        mappedAccountName: '银行卡',

      ),

      '银行卡(0017)',

    );

  });



  test('resolveAccountLabel extracts full bank card from description', () {

    final now = DateTime.now();

    final t = Transaction(

      uuid: 'u4',

      bookId: 1,

      type: TransactionType.expense,

      amount: 146000,

      categoryId: 1,

      date: now,

      description: '勾GOU收款 农业银行储蓄卡(6579)',

      createdAt: now,

      updatedAt: now,

    );



    expect(

      TransactionDisplayUtils.resolveAccountLabel(

        transaction: t,

        mappedAccountName: '银行卡',

      ),

      '农业银行储蓄卡(6579)',

    );

  });



  test('wechat remark overrides wrongly stored alipay import source', () {
    final now = DateTime.now();
    final t = Transaction(
      uuid: 'u6',
      bookId: 1,
      type: TransactionType.income,
      amount: 900,
      categoryId: 1,
      date: now,
      description: '转账备注:微信转账',
      comment: '@src:via=import;pay=;src=支付宝@',
      createdAt: now,
      updatedAt: now,
    );

    expect(TransactionDisplayUtils.resolveImportSourceLabel(t), '微信');
    expect(
      TransactionDisplayUtils.resolveRecordMethodDetail(t),
      '微信账单导入',
    );
    expect(
      TransactionDisplayUtils.resolveAccountLabel(
        transaction: t,
        mappedAccountName: '现金',
      ),
      '微信零钱',
    );
  });

  test('legacy import without via still shows platform import', () {

    final now = DateTime.now();

    final t = Transaction(

      uuid: 'u5',

      bookId: 1,

      type: TransactionType.expense,

      amount: 100,

      categoryId: 1,

      date: now,

      comment: '@src:cat=商户消费;pay=农业银行储蓄卡(6579);src=支付宝@',

      createdAt: now,

      updatedAt: now,

    );



    expect(

      TransactionDisplayUtils.resolveRecordMethodDetail(t),

      '支付宝账单导入',

    );

    expect(

      TransactionDisplayUtils.resolveAccountLabel(

        transaction: t,

        mappedAccountName: '银行卡',

      ),

      '农业银行储蓄卡(6579)',

    );

  });

}


