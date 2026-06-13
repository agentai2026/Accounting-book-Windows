import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/receipt_scene.dart';

/// AI 识图基准测试用例（模拟 OCR 文本 → 期望解析结果）
class AiRecognitionBenchmarkCase {
  const AiRecognitionBenchmarkCase({
    required this.id,
    required this.category,
    required this.ocrText,
    this.shouldParse = true,
    this.type,
    this.amountCents,
    this.payerContains,
    this.payerExact,
    this.descriptionContains,
    this.accountName,
    this.scene,
    this.year,
    this.month,
    this.day,
    this.hour,
    this.minute,
  });

  final String id;
  final String category;
  final String ocrText;
  final bool shouldParse;
  final TransactionType? type;
  final int? amountCents;
  final String? payerContains;
  final String? payerExact;
  final String? descriptionContains;
  final String? accountName;
  final ReceiptScene? scene;
  final int? year;
  final int? month;
  final int? day;
  final int? hour;
  final int? minute;
}

/// 全部基准用例（≥200 条）
List<AiRecognitionBenchmarkCase> buildAiRecognitionBenchmarkCases() {
  return [
    ..._bankCases(),
    ..._wechatPaymentCases(),
    ..._wechatTransferCases(),
    ..._alipayCases(),
    ..._paperReceiptCases(),
    ..._ocrEdgeCases(),
    ..._negativeCases(),
    ..._extendedCases(),
  ];
}

List<AiRecognitionBenchmarkCase> _bankCases() {
  const names = ['宋宁', '申屠浩侃', '张三', '李四', '王五', '赵六', '陈七', '刘八'];
  const amounts = [91360, 541700, 704200, 120000, 5000, 9999, 100000, 250050];
  final cases = <AiRecognitionBenchmarkCase>[];

  for (var i = 0; i < 8; i++) {
    final m = (i % 12) + 1;
    final d = (i % 28) + 1;
    cases.add(AiRecognitionBenchmarkCase(
      id: 'bank_income_$i',
      category: '银行月账单-收入',
      ocrText: '''
${m}月 / 2025
0.00 支出(元)    ${(amounts[i] / 100).toStringAsFixed(2)} 收入(元)
${d.toString().padLeft(2, '0')}日
转账-${names[i]}
借记卡6579 ${(8 + i).toString().padLeft(2, '0')}:${(10 + i).toString().padLeft(2, '0')}
+ ¥ ${(amounts[i] / 100).toStringAsFixed(2)}
余额: ¥ ${((amounts[i] + 100) / 100).toStringAsFixed(2)}
''',
      type: TransactionType.income,
      amountCents: amounts[i],
      payerContains: names[i],
      accountName: '借记卡6579',
      scene: ReceiptScene.bankMonthlyBill,
      year: 2025,
      month: m,
      day: d,
      hour: 8 + i,
      minute: 10 + i,
    ));
  }

  for (var i = 0; i < 4; i++) {
    cases.add(AiRecognitionBenchmarkCase(
      id: 'bank_expense_$i',
      category: '银行月账单-支出',
      ocrText: '''
3月 / 2026
${(100 + i * 50).toStringAsFixed(2)} 支出(元)    0.00 收入(元)
${(5 + i).toString().padLeft(2, '0')}日
美团外卖
- ¥ ${(18.5 + i).toStringAsFixed(2)}
''',
      type: TransactionType.expense,
      amountCents: ((18.5 + i) * 100).round(),
      payerContains: '美团',
      scene: ReceiptScene.bankMonthlyBill,
      year: 2026,
      month: 3,
      day: 5 + i,
    ));
  }

  cases.addAll([
    const AiRecognitionBenchmarkCase(
      id: 'bank_income_nov_song',
      category: '银行月账单-收入',
      ocrText: '''
11月 / 2025
03日
转账-宋宁
+ ¥ 5,417.00
余额: ¥ 5,417.01
''',
      type: TransactionType.income,
      amountCents: 541700,
      payerExact: '宋宁',
      scene: ReceiptScene.bankMonthlyBill,
      year: 2025,
      month: 11,
      day: 3,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'bank_split_sign_amount',
      category: '银行月账单-收入',
      ocrText: '''
2月 / 2026
13日
转账-申屠浩侃
+
￥ 7,042.00
''',
      type: TransactionType.income,
      amountCents: 704200,
      payerContains: '申屠',
      year: 2026,
      month: 2,
      day: 13,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'bank_space_in_amount',
      category: '银行月账单-收入',
      ocrText: '''
2月 / 2026
13日
转账-申屠浩侃
+ ¥ 7 042.00
''',
      type: TransactionType.income,
      amountCents: 704200,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'bank_missing_amount_line',
      category: '银行月账单-收入',
      ocrText: '''
2月 / 2026
0.00 支出(元)    7,042.00 收入(元)
13日
转账-申屠浩侃
借记卡6579 08:54
余额: ¥ 7,499.69
''',
      type: TransactionType.income,
      amountCents: 704200,
    ),
  ]);

  return cases;
}

List<AiRecognitionBenchmarkCase> _wechatPaymentCases() {
  const merchants = [
    '美团外卖',
    '星巴克咖啡',
    '滴滴出行',
    '京东自营',
    '山姆会员商店',
    '麦当劳',
    '肯德基',
    '盒马鲜生',
  ];
  final cases = <AiRecognitionBenchmarkCase>[];

  for (var i = 0; i < merchants.length; i++) {
    final amount = ((i + 1) * 12.5 * 100).round();
    cases.add(AiRecognitionBenchmarkCase(
      id: 'wechat_pay_$i',
      category: '微信支付',
      ocrText: '''
支付成功
付款给 ${merchants[i]}
- ¥ ${(amount / 100).toStringAsFixed(2)}
2026年${(i % 6) + 1}月${(i % 28) + 1}日 ${10 + i}:30:00
零钱
''',
      type: TransactionType.expense,
      amountCents: amount,
      payerExact: merchants[i],
      accountName: '零钱',
      scene: ReceiptScene.wechatPayment,
      year: 2026,
      month: (i % 6) + 1,
      day: (i % 28) + 1,
      hour: 10 + i,
      minute: 30,
    ));
  }

  cases.addAll([
    const AiRecognitionBenchmarkCase(
      id: 'wechat_sams_club',
      category: '微信支付',
      ocrText: '''
17:40
全部账单
山姆会员商店SamsCLUB
-400.30
当前状态 支付成功
支付时间 2024年10月25日12:30:16
支付方式 招商银行信用卡(1094)
''',
      type: TransactionType.expense,
      amountCents: 40030,
      payerContains: '山姆',
      scene: ReceiptScene.wechatPayment,
      year: 2024,
      month: 10,
      day: 25,
      hour: 12,
      minute: 30,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'wechat_pay_time_split',
      category: '微信支付',
      ocrText: '''
支付成功
付款给 美团外卖
- ¥ 35.00
支付时间
2026年1月15日
12:30:45
零钱
''',
      type: TransactionType.expense,
      amountCents: 3500,
      payerExact: '美团外卖',
      year: 2026,
      month: 1,
      day: 15,
      hour: 12,
      minute: 30,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'wechat_large_expense',
      category: '微信支付',
      ocrText: '''
支付成功
付款给 装修公司
- ¥ 28,800.00
2025年12月1日 09:00:00
招商银行信用卡(8821)
''',
      type: TransactionType.expense,
      amountCents: 2880000,
      payerContains: '装修',
    ),
    const AiRecognitionBenchmarkCase(
      id: 'wechat_small_expense',
      category: '微信支付',
      ocrText: '''
支付成功
付款给 便利店
- ¥ 3.50
2026年3月3日 07:15:00
零钱
''',
      type: TransactionType.expense,
      amountCents: 350,
      payerContains: '便利店',
    ),
    const AiRecognitionBenchmarkCase(
      id: 'wechat_qr_pay',
      category: '微信支付',
      ocrText: '''
支付成功
扫二维码付款-老张水果店
- ¥ 16.80
2026年4月10日 18:22:00
零钱
''',
      type: TransactionType.expense,
      amountCents: 1680,
      payerContains: '老张水果',
    ),
  ]);

  for (var i = 0; i < 6; i++) {
    cases.add(AiRecognitionBenchmarkCase(
      id: 'wechat_pay_var_$i',
      category: '微信支付',
      ocrText: '''
支付成功
商户名称：测试商户$i
- ¥ ${(99 + i).toStringAsFixed(2)}
2026年5月${i + 1}日 14:00:00
零钱
''',
      type: TransactionType.expense,
      amountCents: (99 + i) * 100,
      payerContains: '测试商户$i',
    ));
  }

  return cases;
}

List<AiRecognitionBenchmarkCase> _wechatTransferCases() {
  const names = ['张三', '李四', '王五', '赵六', '钱七', '孙八', '周九', '吴十'];
  final cases = <AiRecognitionBenchmarkCase>[];

  for (var i = 0; i < names.length; i++) {
    cases.add(AiRecognitionBenchmarkCase(
      id: 'wechat_transfer_in_$i',
      category: '微信转账-收入',
      ocrText: '''
${names[i]}
向你转账
+ ¥ ${((i + 1) * 100).toStringAsFixed(2)}
2026年2月${i + 1}日 19:30:00
零钱
''',
      type: TransactionType.income,
      amountCents: (i + 1) * 10000,
      payerExact: names[i],
      scene: ReceiptScene.wechatTransferIncome,
      year: 2026,
      month: 2,
      day: i + 1,
      hour: 19,
      minute: 30,
    ));
  }

  for (var i = 0; i < 4; i++) {
    cases.add(AiRecognitionBenchmarkCase(
      id: 'wechat_transfer_out_$i',
      category: '微信转账-支出',
      ocrText: '''
转账给 同事${i + 1}
- ¥ ${(50 + i * 10).toStringAsFixed(2)}
2026年6月${i + 1}日 20:00:00
零钱
''',
      type: TransactionType.expense,
      amountCents: (50 + i * 10) * 100,
      payerContains: '同事',
    ));
  }

  return cases;
}

List<AiRecognitionBenchmarkCase> _alipayCases() {
  final cases = <AiRecognitionBenchmarkCase>[];

  cases.add(const AiRecognitionBenchmarkCase(
    id: 'alipay_haiyan_1688',
    category: '支付宝账单',
    ocrText: '''
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
''',
    type: TransactionType.expense,
    amountCents: 168800,
    payerContains: '海艳好合通讯',
    descriptionContains: 'xt红订金',
    accountName: '余额宝',
    scene: ReceiptScene.alipayPayment,
    year: 2026,
    month: 6,
    day: 9,
    hour: 11,
    minute: 35,
  ));

  const merchants = ['麦当劳', '淘宝店铺', '饿了么', '高德打车', '盒马', '苏宁'];
  for (var i = 0; i < merchants.length; i++) {
    cases.add(AiRecognitionBenchmarkCase(
      id: 'alipay_pay_$i',
      category: '支付宝账单',
      ocrText: '''
账单详情
${merchants[i]}
- ¥ ${(20 + i * 5).toStringAsFixed(2)}
交易成功
创建时间 2026-0${(i % 9) + 1}-${(i + 10).toString().padLeft(2, '0')} 15:20:00
付款方式 花呗
''',
      type: TransactionType.expense,
      amountCents: (20 + i * 5) * 100,
      payerContains: merchants[i],
      accountName: '花呗',
      scene: ReceiptScene.alipayPayment,
    ));
  }

  for (var i = 0; i < 6; i++) {
    cases.add(AiRecognitionBenchmarkCase(
      id: 'alipay_refund_$i',
      category: '支付宝账单',
      ocrText: '''
账单详情
退款商户$i
+ ¥ ${(30 + i).toStringAsFixed(2)}
退款成功
创建时间 2026-03-${(i + 1).toString().padLeft(2, '0')} 10:00:00
支付宝
''',
      type: TransactionType.income,
      amountCents: (30 + i) * 100,
      payerContains: '退款商户',
    ));
  }

  cases.addAll([
    const AiRecognitionBenchmarkCase(
      id: 'alipay_phone_recharge',
      category: '支付宝账单',
      ocrText: '''
AD手机话费充值服务商 15215561330已收款
¥ 200.00
2024-05-06 19:05:15
支付宝
''',
      type: TransactionType.expense,
      amountCents: 20000,
      payerContains: '话费',
    ),
    const AiRecognitionBenchmarkCase(
      id: 'alipay_counterparty_label',
      category: '支付宝账单',
      ocrText: '''
交易成功
对方账户
星巴克咖啡
- ¥ 42.00
支付宝
''',
      type: TransactionType.expense,
      amountCents: 4200,
      payerExact: '星巴克咖啡',
    ),
    const AiRecognitionBenchmarkCase(
      id: 'alipay_datetime_sticky',
      category: '支付宝账单',
      ocrText: '''
账单详情
-1688.00
交易成功
创建时间 2026-06-0911:35:14
付款方式 余额宝
''',
      type: TransactionType.expense,
      amountCents: 168800,
      year: 2026,
      month: 6,
      day: 9,
      hour: 11,
      minute: 35,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'alipay_yuebao_account',
      category: '支付宝账单',
      ocrText: '''
付款成功
收款方：盒马鲜生
- ¥ 88.00
2026年3月2日 18:20:10
余额宝
''',
      type: TransactionType.expense,
      amountCents: 8800,
      payerExact: '盒马鲜生',
      accountName: '余额宝',
    ),
  ]);

  for (var i = 0; i < 8; i++) {
    cases.add(AiRecognitionBenchmarkCase(
      id: 'alipay_bill_var_$i',
      category: '支付宝账单',
      ocrText: '''
<账单详情
收款方 测试店$i
- ¥ ${(100 + i * 11).toStringAsFixed(2)}
交易成功
创建时间 2026-07-${(i + 1).toString().padLeft(2, '0')} 08:${(i + 10).toString().padLeft(2, '0')}:00
付款方式 支付宝
''',
      type: TransactionType.expense,
      amountCents: (100 + i * 11) * 100,
      payerContains: '测试店',
    ));
  }

  return cases;
}

List<AiRecognitionBenchmarkCase> _paperReceiptCases() {
  const shops = ['星巴克咖啡', '瑞幸咖啡', '全家便利店', '7-Eleven', '肯德基', '必胜客'];
  final cases = <AiRecognitionBenchmarkCase>[];

  for (var i = 0; i < shops.length; i++) {
    cases.add(AiRecognitionBenchmarkCase(
      id: 'receipt_$i',
      category: '纸质小票',
      ocrText: '''
${shops[i]}
2026-03-${(i + 1).toString().padLeft(2, '0')} 14:30
商品A  ${(10 + i).toStringAsFixed(2)}
商品B  ${(5 + i).toStringAsFixed(2)}
合计 ${(15 + i * 2).toStringAsFixed(2)}
实付 ${(15 + i * 2).toStringAsFixed(2)}
''',
      type: TransactionType.expense,
      amountCents: (15 + i * 2) * 100,
      payerContains: shops[i].substring(0, 2),
    ));
  }

  for (var i = 0; i < 6; i++) {
    cases.add(AiRecognitionBenchmarkCase(
      id: 'receipt_total_$i',
      category: '纸质小票',
      ocrText: '''
超市$i号店
TOTAL ${(50 + i * 3).toStringAsFixed(2)}
2026-01-${(i + 5).toString().padLeft(2, '0')}
''',
      type: TransactionType.expense,
      amountCents: (50 + i * 3) * 100,
    ));
  }

  return cases;
}

List<AiRecognitionBenchmarkCase> _ocrEdgeCases() {
  return [
    const AiRecognitionBenchmarkCase(
      id: 'edge_status_bar_time',
      category: 'OCR边界',
      ocrText: '''
03:07
支付成功
付款给 美团外卖
- ¥ 35.00
2026年1月15日 12:30:45
零钱
''',
      type: TransactionType.expense,
      amountCents: 3500,
      payerExact: '美团外卖',
      year: 2026,
      month: 1,
      day: 15,
      hour: 12,
      minute: 30,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'edge_dot_time',
      category: 'OCR边界',
      ocrText: '''
8月 / 2025
15日
借记卡6579 08.54
+ ¥ 913.60
''',
      type: TransactionType.income,
      amountCents: 91360,
      hour: 8,
      minute: 54,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'edge_chinese_colon',
      category: 'OCR边界',
      ocrText: '''
8月 / 2025
15日
借记卡6579 08：54
+ ¥ 913.60
''',
      type: TransactionType.income,
      amountCents: 91360,
      hour: 8,
      minute: 54,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'edge_year_month_split',
      category: 'OCR边界',
      ocrText: '''
11月
2025
03日
转账-宋宁
+ ¥ 5,417.00
''',
      type: TransactionType.income,
      amountCents: 541700,
      year: 2025,
      month: 11,
      day: 3,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'edge_no_month_header',
      category: 'OCR边界',
      ocrText: '''
03日
17:25
转账-宋宁
+ ¥ 100.00
''',
      type: TransactionType.income,
      amountCents: 10000,
      payerContains: '宋宁',
    ),
    const AiRecognitionBenchmarkCase(
      id: 'edge_income_expense_tags_split',
      category: 'OCR边界',
      ocrText: '''
11月 / 2025
03日
+ ¥ 5,417.00
收入
转账-宋宁
''',
      type: TransactionType.income,
      amountCents: 541700,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'edge_alipay_not_transfer',
      category: 'OCR边界',
      ocrText: '''
账单详情
-1688.00
交易成功
转账备注 xt红订金
再转一笔
''',
      type: TransactionType.expense,
      amountCents: 168800,
      descriptionContains: 'xt红订金',
    ),
    const AiRecognitionBenchmarkCase(
      id: 'edge_balance_not_amount',
      category: 'OCR边界',
      ocrText: '''
支付成功
付款给 测试
- ¥ 50.00
余额: ¥ 9999.99
2026年1月1日 12:00:00
''',
      type: TransactionType.expense,
      amountCents: 5000,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'edge_wechat_income_transfer',
      category: 'OCR边界',
      ocrText: '''
李四
转账给你
+ ¥ 500.00
2026年3月1日 10:00:00
''',
      type: TransactionType.income,
      amountCents: 50000,
      payerExact: '李四',
    ),
    const AiRecognitionBenchmarkCase(
      id: 'edge_refund_income',
      category: 'OCR边界',
      ocrText: '''
京东自营
退款成功
实退 128.50
''',
      type: TransactionType.income,
      amountCents: 12850,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'edge_ai_bank_as_income',
      category: 'OCR边界',
      ocrText: '''
11月 / 2025
03日
转账-宋宁
+ ¥ 5,417.00
''',
      type: TransactionType.income,
      amountCents: 541700,
      payerContains: '宋宁',
    ),
    const AiRecognitionBenchmarkCase(
      id: 'edge_payment_method_not_payer',
      category: 'OCR边界',
      ocrText: '''
支付成功
测试商户
- ¥ 10.00
余额宝 > 付款方式
2026年1月1日 12:00:00
''',
      type: TransactionType.expense,
      amountCents: 1000,
      payerContains: '测试商户',
    ),
    const AiRecognitionBenchmarkCase(
      id: 'edge_card_tail_not_amount',
      category: 'OCR边界',
      ocrText: '''
支付成功
山姆会员商店
-400.30
支付方式 招商银行信用卡(1094)
支付时间 2024年10月25日12:30:16
''',
      type: TransactionType.expense,
      amountCents: 40030,
      payerContains: '山姆',
    ),
    const AiRecognitionBenchmarkCase(
      id: 'edge_comma_amount',
      category: 'OCR边界',
      ocrText: '''
支付成功
- ¥ 1,688.00
2026年6月9日 11:35:00
''',
      type: TransactionType.expense,
      amountCents: 168800,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'edge_fullwidth_sign',
      category: 'OCR边界',
      ocrText: '''
支付成功
付款给 测试
＋ ¥ 200.00
2026年1月1日 12:00:00
''',
      type: TransactionType.income,
      amountCents: 20000,
    ),
  ];
}

List<AiRecognitionBenchmarkCase> _negativeCases() {
  return [
    const AiRecognitionBenchmarkCase(
      id: 'neg_empty',
      category: '负样本',
      ocrText: '',
      shouldParse: false,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'neg_noise_only',
      category: '负样本',
      ocrText: '''
03:07
全部账单
更多
账单管理
''',
      shouldParse: false,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'neg_no_amount',
      category: '负样本',
      ocrText: '''
支付成功
付款给 测试商户
2026年1月1日
''',
      shouldParse: false,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'neg_zero_amount',
      category: '负样本',
      ocrText: '''
支付成功
- ¥ 0.00
2026年1月1日
''',
      shouldParse: false,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'neg_gibberish',
      category: '负样本',
      ocrText: 'abcdefg xyz 123',
      shouldParse: false,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'neg_ui_only',
      category: '负样本',
      ocrText: '''
买手
找我
再转一笔
账单管理
''',
      shouldParse: false,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'neg_balance_only',
      category: '负样本',
      ocrText: '''
余额: ¥ 9999.99
账户余额 12345.67
''',
      shouldParse: false,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'neg_phone_only',
      category: '负样本',
      ocrText: '''
13800138000
联系电话
''',
      shouldParse: false,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'neg_order_number_only',
      category: '负样本',
      ocrText: '''
交易单号 4200002444202410253562580380
商户单号 X2526331726738894756x000
''',
      shouldParse: false,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'neg_tiny_amount',
      category: '负样本',
      ocrText: '''
支付成功
- ¥ 0.001
''',
      shouldParse: false,
    ),
  ];
}

/// 扩展用例（100+ 条，覆盖更多商户/金额/OCR 变体）
List<AiRecognitionBenchmarkCase> _extendedCases() {
  final cases = <AiRecognitionBenchmarkCase>[];

  // —— 银行：更多卡类型与金额 ——
  const bankCards = ['借记卡6579', '储蓄卡8821', '信用卡1094', '银行卡5566'];
  for (var i = 0; i < 12; i++) {
    final amount = (500 + i * 137) * 100;
    final m = (i % 6) + 1;
    final d = (i % 25) + 1;
    cases.add(AiRecognitionBenchmarkCase(
      id: 'ext_bank_in_$i',
      category: '银行月账单-收入',
      ocrText: '''
$m月 / 2025
${d}日
转账-客户${i + 1}
${bankCards[i % bankCards.length]} ${(9 + i % 10).toString().padLeft(2, '0')}:${(i % 50).toString().padLeft(2, '0')}
+ ¥ ${(amount / 100).toStringAsFixed(2)}
''',
      type: TransactionType.income,
      amountCents: amount,
      payerContains: '客户',
      scene: ReceiptScene.bankMonthlyBill,
    ));
  }

  for (var i = 0; i < 8; i++) {
    final amount = (20 + i * 8.5) * 100;
    cases.add(AiRecognitionBenchmarkCase(
      id: 'ext_bank_out_$i',
      category: '银行月账单-支出',
      ocrText: '''
3月 / 2026
${(i + 1).toString().padLeft(2, '0')}日
商户消费$i
- ¥ ${(amount / 100).toStringAsFixed(2)}
''',
      type: TransactionType.expense,
      amountCents: amount.round(),
    ));
  }

  // —— 微信：更多商户场景 ——
  const wxMerchants = [
    '滴滴出行', '高德打车', '饿了么', '美团', '拼多多', '淘宝',
    '京东', '话费充值', '水电煤', '物业缴费', '停车费', '医院挂号',
    '药店', '加油站', '电影院', 'Netflix', 'Apple', 'Steam',
    '携程旅行', '铁路12306', '顺丰速运', '菜鸟驿站', '丰巢', '共享单车',
  ];
  for (var i = 0; i < wxMerchants.length; i++) {
    final amount = (500 + i * 317) % 50000 + 100;
    cases.add(AiRecognitionBenchmarkCase(
      id: 'ext_wx_$i',
      category: '微信支付',
      ocrText: '''
支付成功
付款给 ${wxMerchants[i]}
- ¥ ${(amount / 100).toStringAsFixed(2)}
2026年${(i % 6) + 1}月${(i % 20) + 1}日 ${(10 + i % 8).toString().padLeft(2, '0')}:00:00
零钱
''',
      type: TransactionType.expense,
      amountCents: amount,
      payerContains: wxMerchants[i].length >= 2
          ? wxMerchants[i].substring(0, 2)
          : wxMerchants[i],
    ));
  }

  // —— 微信转账收入变体 ——
  for (var i = 0; i < 10; i++) {
    final amount = (100 + i * 50) * 100;
    cases.add(AiRecognitionBenchmarkCase(
      id: 'ext_wx_in_$i',
      category: '微信转账-收入',
      ocrText: '''
朋友${i + 1}
向你转账
+ ¥ ${(amount / 100).toStringAsFixed(2)}
2026年2月${i + 1}日 12:00:00
''',
      type: TransactionType.income,
      amountCents: amount,
      payerContains: '朋友',
    ));
  }

  // —— 支付宝：花呗/余额宝/信用卡变体 ——
  const aliAccounts = ['花呗', '余额宝', '支付宝', '信用卡'];
  for (var i = 0; i < 20; i++) {
    final amount = (1000 + i * 223) % 80000 + 500;
    cases.add(AiRecognitionBenchmarkCase(
      id: 'ext_ali_$i',
      category: '支付宝账单',
      ocrText: '''
账单详情
店铺名称$i
- ¥ ${(amount / 100).toStringAsFixed(2)}
交易成功
创建时间 2026-0${(i % 5) + 1}-${(i + 5).toString().padLeft(2, '0')} 14:30:00
${aliAccounts[i % aliAccounts.length]} > 付款方式
''',
      type: TransactionType.expense,
      amountCents: amount,
      payerContains: '店铺',
      accountName: aliAccounts[i % aliAccounts.length],
    ));
  }

  // —— 支付宝退款变体 ——
  for (var i = 0; i < 8; i++) {
    final amount = (10 + i * 15) * 100;
    cases.add(AiRecognitionBenchmarkCase(
      id: 'ext_ali_refund_$i',
      category: '支付宝账单',
      ocrText: '''
账单详情
退款店$i
+ ¥ ${(amount / 100).toStringAsFixed(2)}
退款成功
创建时间 2026-03-${(i + 1).toString().padLeft(2, '0')} 10:00:00
''',
      type: TransactionType.income,
      amountCents: amount,
      payerContains: '退款店',
    ));
  }

  // —— 纸质小票扩展 ——
  const receiptShops = [
    '沃尔玛', '大润发', '永辉超市', '华润万家', '罗森',
    '便利蜂', '小杨生煎', '海底捞', '西贝莜面村', '喜茶',
  ];
  for (var i = 0; i < receiptShops.length; i++) {
    final total = (30 + i * 7.5) * 100;
    cases.add(AiRecognitionBenchmarkCase(
      id: 'ext_receipt_$i',
      category: '纸质小票',
      ocrText: '''
${receiptShops[i]}
2026-04-${(i + 1).toString().padLeft(2, '0')} 18:00
合计 ${(total / 100).toStringAsFixed(2)}
实付 ${(total / 100).toStringAsFixed(2)}
''',
      type: TransactionType.expense,
      amountCents: total.round(),
      payerContains: receiptShops[i].substring(0, 2),
    ));
  }

  // —— OCR 边界扩展 ——
  cases.addAll([
    const AiRecognitionBenchmarkCase(
      id: 'ext_edge_watermark',
      category: 'OCR边界',
      ocrText: '''
访客 48224
支付成功
付款给 测试店
- ¥ 88.00
2026年3月1日 12:00:00
''',
      type: TransactionType.expense,
      amountCents: 8800,
      payerContains: '测试店',
    ),
    const AiRecognitionBenchmarkCase(
      id: 'ext_edge_amount_space',
      category: 'OCR边界',
      ocrText: '''
支付成功
- ¥ 1 688.00
2026年6月9日 11:35:00
''',
      type: TransactionType.expense,
      amountCents: 168800,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'ext_edge_yuan_no_sign',
      category: 'OCR边界',
      ocrText: '''
交易成功
¥1688.00
2026-06-09 11:35:14
''',
      type: TransactionType.expense,
      amountCents: 168800,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'ext_edge_merchant_double_dash',
      category: 'OCR边界',
      ocrText: '''
海艳好合通讯--齐海(*海)>
-688.00
交易成功
''',
      type: TransactionType.expense,
      amountCents: 68800,
      payerContains: '海艳',
    ),
    const AiRecognitionBenchmarkCase(
      id: 'ext_edge_wechat_credit_card',
      category: 'OCR边界',
      ocrText: '''
支付成功
山姆会员商店
-400.30
支付方式 招商银行信用卡(1094)
支付时间 2024年10月25日12:30:16
''',
      type: TransactionType.expense,
      amountCents: 40030,
      payerContains: '山姆',
    ),
    const AiRecognitionBenchmarkCase(
      id: 'ext_edge_remark_trailing',
      category: 'OCR边界',
      ocrText: '''
-1688.00
交易成功
订金备注 转账备注
''',
      type: TransactionType.expense,
      amountCents: 168800,
      descriptionContains: '订金备注',
    ),
    const AiRecognitionBenchmarkCase(
      id: 'ext_edge_income_label_line',
      category: 'OCR边界',
      ocrText: '''
11月 / 2025
+ ¥ 200.00
收入
03日
''',
      type: TransactionType.income,
      amountCents: 20000,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'ext_edge_expense_label_line',
      category: 'OCR边界',
      ocrText: '''
11月 / 2025
- ¥ 50.00
支出
05日
''',
      type: TransactionType.expense,
      amountCents: 5000,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'ext_edge_qr_income',
      category: 'OCR边界',
      ocrText: '''
二维码收款-张三
+ ¥ 88.88
2026年1月5日 20:00:00
''',
      type: TransactionType.income,
      amountCents: 8888,
      payerContains: '张三',
    ),
    const AiRecognitionBenchmarkCase(
      id: 'ext_edge_from_transfer',
      category: 'OCR边界',
      ocrText: '''
来自 李四的转账
+ ¥ 1000.00
2026年2月10日 08:00:00
''',
      type: TransactionType.income,
      amountCents: 100000,
      payerContains: '李四',
    ),
  ]);

  for (var i = 0; i < 10; i++) {
    cases.add(AiRecognitionBenchmarkCase(
      id: 'ext_edge_amt_$i',
      category: 'OCR边界',
      ocrText: '''
支付成功
- ¥ ${(1.99 + i * 0.5).toStringAsFixed(2)}
2026年1月${i + 1}日
''',
      type: TransactionType.expense,
      amountCents: ((1.99 + i * 0.5) * 100).round(),
    ));
  }

  // —— 负样本扩展 ——
  cases.addAll([
    const AiRecognitionBenchmarkCase(
      id: 'ext_neg_status_only',
      category: '负样本',
      ocrText: '''
17:40
77%
WiFi
''',
      shouldParse: false,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'ext_neg_label_only',
      category: '负样本',
      ocrText: '''
支付成功
当前状态
支付时间
付款方式
商品
''',
      shouldParse: false,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'ext_neg_future_no_amount',
      category: '负样本',
      ocrText: '''
2026年12月31日 23:59:59
交易成功
''',
      shouldParse: false,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'ext_neg_percent',
      category: '负样本',
      ocrText: '''
优惠 85%
折扣 9.5折
''',
      shouldParse: false,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'ext_neg_points',
      category: '负样本',
      ocrText: '''
支付奖励 立即领取
会员积分 待领取
''',
      shouldParse: false,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'ext_neg_single_char',
      category: '负样本',
      ocrText: '式',
      shouldParse: false,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'ext_neg_club_only',
      category: '负样本',
      ocrText: '''
CLUB
全部账单
''',
      shouldParse: false,
    ),
    const AiRecognitionBenchmarkCase(
      id: 'ext_neg_transfer_ui',
      category: '负样本',
      ocrText: '''
转账备注
再转一笔
账单管理
''',
      shouldParse: false,
    ),
  ]);

  return cases;
}
