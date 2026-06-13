import 'package:flutter_test/flutter_test.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/receipt_scene.dart';
import 'package:ezbookkeeping_desktop/core/services/receipt_text_parser.dart';

void main() {
  const parser = ReceiptTextParser();

  test('解析银行收入转账截图', () {
    const text = '''
2月 / 2026
0.00 支出(元)    7,042.00 收入(元)
13日
转账-申屠浩侃
借记卡6579 08:54
+ ¥ 7,042.00
余额: ¥ 7,499.69
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.type, TransactionType.transfer);
    expect(result.amountCents, 704200);
    expect(result.description, contains('转账'));
    expect(result.accountName, '借记卡6579');
    expect(result.date?.month, 2);
    expect(result.date?.day, 13);
    expect(result.date?.hour, 8);
    expect(result.date?.minute, 54);
  });

  test('解析8月银行收入截图', () {
    const text = '''
8月 / 2025
0.00 支出(元)    913.60 收入(元)
15日
转账-申屠浩侃
+ ¥ 913.60
余额: ¥ 973.75
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.type, TransactionType.transfer);
    expect(result.amountCents, 91360);
    expect(result.date?.year, 2025);
    expect(result.date?.month, 8);
    expect(result.date?.day, 15);
  });

  test('OCR 漏掉带符号金额行时从月汇总行提取', () {
    const text = '''
2月 / 2026
0.00 支出(元)    7,042.00 收入(元)
13日
转账-申屠浩侃
借记卡6579 08:54
余额: ¥ 7,499.69
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.amountCents, 704200);
    expect(result.type, TransactionType.transfer);
  });

  test('OCR 数字中带空格', () {
    const text = '''
2月 / 2026
13日
转账-申屠浩侃
+ ¥ 7 042.00
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.amountCents, 704200);
  });

  test('OCR 把加号和金额拆成两行', () {
    const text = '''
2月 / 2026
13日
转账-申屠浩侃
+
￥ 7,042.00
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.amountCents, 704200);
  });

  test('OCR 把账户和时间拆成两行', () {
    const text = '''
2月 / 2026
13日
转账-申屠浩侃
借记卡6579
08:54
+ ¥ 7,042.00
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.accountName, '借记卡6579');
    expect(result.date?.hour, 8);
    expect(result.date?.minute, 54);
    expect(result.date?.month, 2);
    expect(result.date?.day, 13);
  });

  test('OCR 时间使用中文冒号', () {
    const text = '''
8月 / 2025
15日
借记卡6579 08：54
+ ¥ 913.60
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.date?.hour, 8);
    expect(result.date?.minute, 54);
  });

  test('微信支付识别付款给对方', () {
    const text = '''
支付成功
付款给 美团外卖
- ¥ 35.00
2026年1月15日 12:30:45
零钱
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.payer, '美团外卖');
    expect(result.type, TransactionType.expense);
    expect(result.date?.year, 2026);
    expect(result.date?.month, 1);
    expect(result.date?.day, 15);
    expect(result.date?.hour, 12);
    expect(result.date?.minute, 30);
    expect(result.date?.second, 45);
  });

  test('支付宝识别收款方', () {
    const text = '''
付款成功
收款方：麦当劳
- ¥ 28.50
2026年3月2日 18:20:10
支付宝
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.payer, '麦当劳');
    expect(result.date?.year, 2026);
    expect(result.date?.month, 3);
    expect(result.date?.day, 2);
    expect(result.date?.hour, 18);
    expect(result.date?.minute, 20);
  });

  test('微信收入转账识别对方姓名', () {
    const text = '''
张三
向你转账
+ ¥ 200.00
2026年2月1日 19:30:00
零钱
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.payer, '张三');
    expect(result.type, TransactionType.income);
    expect(result.date?.year, 2026);
    expect(result.date?.month, 2);
    expect(result.date?.day, 1);
    expect(result.date?.hour, 19);
    expect(result.date?.minute, 30);
  });

  test('对方账户标签分行显示', () {
    const text = '''
交易成功
对方账户
星巴克咖啡
- ¥ 42.00
支付宝
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.payer, '星巴克咖啡');
  });

  test('支付时间标签分行显示', () {
    const text = '''
支付成功
付款给 美团外卖
- ¥ 35.00
支付时间
2026年1月15日
12:30:45
零钱
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.date?.year, 2026);
    expect(result.date?.month, 1);
    expect(result.date?.day, 15);
    expect(result.date?.hour, 12);
    expect(result.date?.minute, 30);
    expect(result.date?.second, 45);
  });

  test('日期和时间无空格连接', () {
    const text = '''
付款成功
- ¥ 20.00
2026年3月2日18:20:10
支付宝
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.date?.hour, 18);
    expect(result.date?.minute, 20);
    expect(result.date?.day, 2);
  });

  test('账单列表行内月日时间', () {
    const text = '''
2月 / 2026
美团外卖
- ¥ 18.00
1月15日 12:30
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.date?.year, 2026);
    expect(result.date?.month, 1);
    expect(result.date?.day, 15);
    expect(result.date?.hour, 12);
    expect(result.date?.minute, 30);
  });

  test('OCR 用点号分隔时间', () {
    const text = '''
8月 / 2025
15日
借记卡6579 08.54
+ ¥ 913.60
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.date?.hour, 8);
    expect(result.date?.minute, 54);
  });

  test('场景分类后提取余额到备注', () {
    const text = '''
11月 / 2025
03日
转账-宋宁
+ ¥ 5,417.00
余额: ¥ 5,417.01
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.scene, ReceiptScene.bankMonthlyBill);
    expect(result.balanceCents, 541701);
    expect(result.description, '转账');
  });

  test('银行转账收入分类和标签', () {
    const text = '''
11月 / 2025
03日
转账-宋宁
借记卡6579 17:25
+ ¥ 5,417.00
余额: ¥ 5,417.01
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.categoryName, '银行转账');
    expect(result.tagNames, contains('转账'));
    expect(result.tagNames, contains('银行'));
    expect(result.payer, '宋宁');
    expect(result.description, '转账');
  });

  test('备注标签分行提取', () {
    const text = '''
支付成功
付款给 美团外卖
- ¥ 35.00
备注
午餐套餐
2026年1月15日 12:30:45
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.description, '午餐套餐');
    expect(result.payer, '美团外卖');
    expect(result.categoryName, '食品');
    expect(result.tagNames, contains('外卖'));
  });

  test('解析11月银行转账截图', () {
    const text = '''
11月 / 2025
0.00 支出(元)    5,417.00 收入(元)
03日
转账-宋宁
借记卡6579 17:25
+ ¥ 5,417.00
余额: ¥ 5,417.01
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.type, TransactionType.transfer);
    expect(result.amountCents, 541700);
    expect(result.payer, '宋宁');
    expect(result.accountName, '借记卡6579');
    expect(result.date?.year, 2025);
    expect(result.date?.month, 11);
    expect(result.date?.day, 3);
    expect(result.date?.hour, 17);
    expect(result.date?.minute, 25);
  });

  test('OCR 把年月拆成两行', () {
    const text = '''
11月
/ 2025
03日
借记卡6579 17:25
+ ¥ 100.00
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.date?.year, 2025);
    expect(result.date?.month, 11);
    expect(result.date?.day, 3);
    expect(result.date?.hour, 17);
  });

  test('没有月份标题时不应把03日和17:25配成今天', () {
    const text = '''
03日
17:25
+ ¥ 100.00
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.date, isNull);
  });

  test('OCR 裁切图缺少账户时间行时仍保留正确年月日', () {
    const text = '''
11月 / 2025
03日
转账-宋宁
+ ¥ 5,417.00
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.date?.year, 2025);
    expect(result.date?.month, 11);
    expect(result.date?.day, 3);
  });

  test('OCR 年月无斜杠空格', () {
    const text = '''
11月 2025
03日
借记卡6579 17:25
+ ¥ 100.00
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.date?.year, 2025);
    expect(result.date?.month, 11);
    expect(result.date?.day, 3);
    expect(result.date?.hour, 17);
  });

  test('OCR 把金额行和收入标签拆成两行', () {
    const text = '''
月12025 分析
5,417.00 0.00
支出(元) 收入(元)
03日
转账-宋宁
借记卡*6579 17:25 余额: ¥ 5,417.01
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.type, TransactionType.transfer);
    expect(result.amountCents, 541700);
    expect(result.payer, '宋宁');
    expect(result.accountName, '借记卡6579');
    expect(result.date?.year, 2025);
    expect(result.date?.month, 11);
    expect(result.date?.day, 3);
    expect(result.date?.hour, 17);
    expect(result.date?.minute, 25);
    expect(result.balanceCents, 541701);
  });

  test('OCR 仅识别出年份时不应把2025当金额', () {
    const text = '''
2025
支出(元) 收入(元)
03日
''';

    final result = parser.parse(text);
    expect(result, isNull);
  });

  test('OCR 年份行在汇总上方时仍从月汇总提取金额', () {
    const text = '''
月12025 分析
2025
5,417.00 0.00
支出(元) 收入(元)
03日
转账-宋宁
''';

    final result = parser.parseForRecognition(text);
    expect(result, isNotNull);
    expect(result!.amountCents, 541700);
    expect(result.type, TransactionType.income);
    expect(result.payer, '宋宁');
  });

  test('转账行前有图标前缀仍能识别对方', () {
    const text = '''
11月 / 2025
03日
●转账-宋宁
+ ¥ 5,417.00
''';

    final result = parser.parseForRecognition(text);
    expect(result, isNotNull);
    expect(result!.amountCents, 541700);
    expect(result.payer, '宋宁');
  });

  test('支付宝账单详情不误判为转账', () {
    const text = '''
03:07
<账单详情 全部账单
海艳好合通讯--齐海(*海)>
-1,688.00
交易成功
创建时间 2026-06-0911:35:14
付款方式 余额宝)
转账备注 xt红订金
支付奖励 立即领取1积分
再转一笔
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.type, TransactionType.expense);
    expect(result.amountCents, 168800);
    expect(result.date?.year, 2026);
    expect(result.date?.month, 6);
    expect(result.date?.day, 9);
    expect(result.date?.hour, 11);
    expect(result.date?.minute, 35);
    expect(result.date?.second, 14);
    expect(result.scene, ReceiptScene.alipayPayment);
    expect(result.tagNames, isNot(contains('转账')));
    expect(result.tagNames, contains('支出'));
    expect(result.payer, '海艳好合通讯--齐海');
    expect(result.description, 'xt红订金');
    expect(result.accountName, '余额宝');
  });

  test('支付宝账单 OCR 行内付款方式不误识别付款人', () {
    const text = '''
03:07
全部账单 账单详情
海艳好合通讯--齐海(*海)>
-1,688.00
交易成功
创建时间 2026-06-09 11:35:14
余额宝 > 付款方式
xt红订金 转账备注
对方账户
再转一笔
''';

    final result = parser.parseForRecognition(text);
    expect(result, isNotNull);
    expect(result!.payer, isNot('式'));
    expect(result.payer, contains('海艳好合通讯'));
    expect(result.description, 'xt红订金');
    expect(result.accountName, '余额宝');
  });

  test('支付宝话费充值不误把手机号和已收款当金额', () {
    const text = '''
AD手机话费充值服务商 15215561330已收款
¥ 200.00
报销时间
2024-05-06 19:05:15
收款时间
2024-05-06 19:05:02
支付宝
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.type, TransactionType.expense);
    expect(result.amountCents, 20000);
    expect(result.payer, contains('话费'));
    expect(result.date?.year, 2024);
    expect(result.date?.month, 5);
    expect(result.date?.day, 6);
    expect(result.date?.hour, 19);
    expect(result.categoryName, '电话费');
    expect(result.tagNames, isNot(contains('转账')));
    expect(result.tagNames, contains('话费'));
  });

  test('不会把余额误识别为交易金额', () {
    const text = '''
2026年6月3日 17:25:00
收入
+ ¥ 3.00
余额: ¥ 1,234.56
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.amountCents, 300);
  });

  test('支付宝账单详情创建时间粘连格式', () {
    const text = '''
03:07
账单详情
-¥1688.00
交易成功
创建时间 2026-06-0911:35:14
余额宝
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.date?.year, 2026);
    expect(result.date?.month, 6);
    expect(result.date?.day, 9);
    expect(result.date?.hour, 11);
    expect(result.date?.minute, 35);
    expect(result.date?.second, 14);
  });

  test('支付宝付款时间分行显示', () {
    const text = '''
03:07
-¥1688.00
付款时间
2024-08-09
11:35:14
招商银行储蓄卡
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.date?.year, 2024);
    expect(result.date?.month, 8);
    expect(result.date?.day, 9);
    expect(result.date?.hour, 11);
    expect(result.date?.minute, 35);
    expect(result.date?.second, 14);
  });

  test('OCR 用点号分隔时分秒', () {
    const text = '''
-¥1688.00
创建时间 2026-06-09 11.35.14
支付宝
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.date?.hour, 11);
    expect(result.date?.minute, 35);
    expect(result.date?.second, 14);
  });

  test('不会把手机状态栏时间当作交易时间', () {
    const text = '''
03:07
-¥1688.00
交易成功
支付宝
''';

    final result = parser.parse(text);
    expect(result, isNotNull);
    expect(result!.date, isNull);
  });

  group('AI 识图仅支出/收入', () {
    test('银行转账截图识别为收入而非转账', () {
      const text = '''
11月 / 2025
0.00 支出(元)    5,417.00 收入(元)
03日
转账-宋宁
借记卡6579 17:25
+ ¥ 5,417.00
余额: ¥ 5,417.01
''';

      final result = parser.parseForRecognition(text);
      expect(result, isNotNull);
      expect(result!.type, TransactionType.income);
      expect(result.type, isNot(TransactionType.transfer));
      expect(result.amountCents, 541700);
      expect(result.categoryName, '其他收入');
      expect(result.tagNames, contains('收入'));
      expect(result.tagNames, isNot(contains('转账')));
      expect(result.payer, '宋宁');
    });

    test('支付宝账单仍为支出', () {
      const text = '''
-1,688.00
交易成功
创建时间 2026-06-0911:35:14
转账备注 xt红订金
''';

      final result = parser.parseForRecognition(text);
      expect(result, isNotNull);
      expect(result!.type, TransactionType.expense);
      expect(result.tagNames, contains('支出'));
      expect(result.tagNames, isNot(contains('转账')));
    });

    test('手动指定转账类型会被忽略', () {
      const text = '''
+ ¥ 100.00
''';

      final result = parser.parseForRecognition(
        text,
        forceType: TransactionType.transfer,
      );
      expect(result, isNotNull);
      expect(result!.type, TransactionType.income);
    });
  });
}
