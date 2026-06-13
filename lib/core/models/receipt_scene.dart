/// 收据/账单截图场景（OCR 后的文本分类，用于选择专用解析策略）
enum ReceiptScene {
  /// 银行 App 月账单列表（如 11月/2025 + 03日 + 转账-xxx）
  bankMonthlyBill,

  /// 微信支付成功页（付款给 xxx）
  wechatPayment,

  /// 微信转账收入（+金额、向你转账）
  wechatTransferIncome,

  /// 微信转账支出（-金额、转账给 xxx）
  wechatTransferExpense,

  /// 支付宝付款成功页
  alipayPayment,

  /// 支付宝转账
  alipayTransfer,

  /// 银行卡单笔交易详情
  bankCardDetail,

  /// 购物小票 / 纸质发票
  paperReceipt,

  unknown,
}

extension ReceiptSceneLabels on ReceiptScene {
  String get label => switch (this) {
        ReceiptScene.bankMonthlyBill => '银行月账单',
        ReceiptScene.wechatPayment => '微信支付',
        ReceiptScene.wechatTransferIncome => '微信转账收入',
        ReceiptScene.wechatTransferExpense => '微信转账支出',
        ReceiptScene.alipayPayment => '支付宝付款',
        ReceiptScene.alipayTransfer => '支付宝转账',
        ReceiptScene.bankCardDetail => '银行卡交易',
        ReceiptScene.paperReceipt => '购物小票',
        ReceiptScene.unknown => '通用账单',
      };
}

class ReceiptSceneMatch {
  const ReceiptSceneMatch({
    required this.scene,
    required this.score,
  });

  final ReceiptScene scene;
  final double score;

  bool get isConfident => score >= 0.45;
}
