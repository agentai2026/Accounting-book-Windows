/// AI 识图场景分类关键词（供 ReceiptSceneClassifier 打分）
class ReceiptSceneKeywordRules {
  ReceiptSceneKeywordRules._();

  // —— 支付宝付款 / 账单详情 ——
  static const alipayPaymentStrong = [
    '账单详情',
    '交易成功',
    '创建时间',
    '付款方式',
    '付款成功',
    '支付成功',
    '收款方',
  ];
  static const alipayPaymentMedium = ['支付宝', '花呗', '余额宝'];

  // —— 支付宝转账 ——
  static const alipayTransferStrong = ['转账给', '向对方转账', '对方账户', '交易对方'];

  // —— 微信支付 ——
  static const wechatPaymentStrong = ['支付成功', '付款给', '商品说明'];
  static const wechatPaymentMedium = ['零钱', '微信支付'];

  // —— 微信转账 ——
  static const wechatTransferIncomeStrong = ['向你转账', '转账给你'];
  static const wechatTransferExpenseStrong = ['转账给', '向对方'];

  // —— 银行月账单 ——
  static const bankMonthlyStrong = ['支出', '收入'];
  static const bankMonthlyMedium = ['借记卡', '储蓄卡'];

  /// 出现则降低「银行月账单」得分（避免支付宝截图误判）
  static const bankMonthlyPenalties = ['微信', '支付宝', '账单详情'];
}
