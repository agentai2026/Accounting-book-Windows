import 'package:flutter_test/flutter_test.dart';

import 'package:ezbookkeeping_desktop/core/ai/index.dart';

List<OcrBlock> _blocks(List<(String text, double top, double height)> items) {
  return [
    for (var i = 0; i < items.length; i++)
      OcrBlock(
        text: items[i].$1,
        score: 0.92,
        box: [10, items[i].$2, 210, items[i].$2 + items[i].$3],
      ),
  ];
}

void main() {
  final parser = BillParser();

  test('parseBillFromOCR 小票实付', () {
    final bill = parser.parseBillFromOCR(
      _blocks([
        ('星巴克咖啡', 10, 28),
        ('2026-03-15 14:30', 40, 18),
        ('实付 38.00', 230, 24),
      ]),
    );

    expect(bill, isNotNull);
    expect(bill!.amount, 38.0);
    expect(bill.type, BillType.expense);
    expect(bill.merchant, '星巴克咖啡');
    expect(bill.category, '食品');
    expect(bill.confidence, greaterThan(70));
  });

  test('parseBillFromOCR 支付宝支出截图', () {
    final bill = parser.parseBillFromOCR(
      _blocks([
        ('<账单详情', 10, 20),
        ('-1,688.00', 80, 30),
        ('交易成功', 120, 18),
        ('创建时间 2026-06-0911:35:14', 150, 18),
        ('转账备注 xt红订金', 180, 18),
      ]),
    );

    expect(bill, isNotNull);
    expect(bill!.amount, 1688.0);
    expect(bill.type, BillType.expense);
    expect(bill.platform, BillPlatform.alipay);
  });

  test('parseBillFromOCR 退款为收入', () {
    final bill = parser.parseBillFromOCR(
      _blocks([
        ('京东自营', 10, 20),
        ('退款成功', 50, 18),
        ('实退 128.50', 100, 22),
      ]),
    );

    expect(bill, isNotNull);
    expect(bill!.type, BillType.income);
    expect(bill.amount, 128.5);
  });

  test('parseBillFromOCR 微信山姆支付截图', () {
    final bill = parser.parseBillFromOCR(
      _blocks([
        ('17:40', 5, 14),
        ('全部账单', 8, 16),
        ('CLUB', 40, 18),
        ('山姆会员商店SamsCLUB', 55, 28),
        ('-400.30', 95, 32),
        ('当前状态 支付成功', 140, 18),
        ('支付时间 2024年10月25日12:30:16', 165, 18),
        ('商品 商品', 190, 18),
        ('商户全称 沃尔玛（中国）投资有限公司', 215, 18),
        ('收单机构 财付通支付科技有限公司', 240, 18),
        ('支付方式 招商银行信用卡(1094)', 265, 18),
        ('交易单号 4200002444202410253562580380', 290, 18),
        ('商户单号 X2526331726738894756x000', 315, 18),
      ]),
    );

    expect(bill, isNotNull);
    expect(bill!.amount, 400.30);
    expect(bill.type, BillType.expense);
    expect(bill.platform, BillPlatform.wechat);
    expect(bill.merchant, isNotEmpty);
    expect(bill.merchant, isNot('17:40'));
  });

  test('parseBillFromOCR 支付宝转账截图付款人', () {
    final bill = parser.parseBillFromOCR(
      _blocks([
        ('03:07', 5, 14),
        ('全部账单 账单详情', 20, 16),
        ('海艳好合通讯--齐海(*海)>', 55, 28),
        ('-1,688.00', 95, 32),
        ('交易成功', 140, 18),
        ('创建时间 2026-06-09 11:35:14', 165, 18),
        ('余额宝 > 付款方式', 190, 18),
        ('xt红订金 转账备注', 215, 18),
      ]),
    );

    expect(bill, isNotNull);
    expect(bill!.amount, 1688.0);
    expect(bill.type, BillType.expense);
    expect(bill.merchant, isNot('式'));
    expect(bill.merchant, contains('海艳好合通讯'));
  });

  test('置信度低于70为手动编辑级别', () {
    final bill = parser.parseBillFromOCR(
      _blocks([
        ('88.00', 300, 30),
      ]),
    );

    expect(bill, isNotNull);
    expect(bill!.autoEntryLevel, BillAutoEntryLevel.manual);
  });

  test('parseBillFromOCR 黄太爷纸质小票', () {
    final bill = parser.parseBillFromOCR(
      _blocks([
        ('结账单', 10, 18),
        ('黄太爷自选焖锅（中大产学研店）', 28, 22),
        ('【堂食】', 52, 20),
        ('取单号：58', 75, 16),
        ('下单时间：2024-11-13 12:20:58', 95, 16),
        ('结账时间：2024-11-13 12:21:01', 115, 16),
        ('实付：51.9元', 200, 22),
        ('微信支付：51.9', 225, 18),
      ]),
    );

    expect(bill, isNotNull);
    expect(bill!.amount, 51.9);
    expect(bill.type, BillType.expense);
    expect(bill.merchant, contains('黄太爷'));
    expect(bill.merchant, isNot('【堂食】'));
  });

  test('parseBillFromOCR 银行空账单不应误识别', () {
    final bill = parser.parseBillFromOCR(
      _blocks([
        ('月12025', 10, 18),
        ('0.00 0.00', 35, 18),
        ('支出(元) 收入(元)', 55, 18),
        ('无收支记录', 75, 18),
      ]),
    );

    expect(bill, isNull);
  });
}
