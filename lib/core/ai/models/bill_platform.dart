/// 账单来源平台 / 图片场景
enum BillPlatform {
  wechat,
  alipay,
  unionpay,
  bank,
  receipt,
  invoice,
  unknown,
}

extension BillPlatformLabels on BillPlatform {
  String get label => switch (this) {
        BillPlatform.wechat => '微信',
        BillPlatform.alipay => '支付宝',
        BillPlatform.unionpay => '云闪付',
        BillPlatform.bank => '银行',
        BillPlatform.receipt => '购物小票',
        BillPlatform.invoice => '电子发票',
        BillPlatform.unknown => '未知',
      };
}
