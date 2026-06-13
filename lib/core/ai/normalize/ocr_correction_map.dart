/// OCR 错字词典（等价于 ocr-correction.json，可扩展为 assets 加载）
const kOcrCorrectionDictionary = <String, String>{
  '合汁': '合计',
  '实忖': '实付',
  '实什': '实付',
  '支忖': '支付',
  '支件宝': '支付宝',
  '收款戍功': '收款成功',
  '收歉成功': '收款成功',
  '总阶': '总价',
  '应收金客': '应收金额',
  '实付金客': '实付金额',
  '月12025': '11月 2025',
  '转帐': '转账',
};

/// 金额行字符混淆映射
const kOcrDigitCharMap = <String, String>{
  'O': '0',
  'o': '0',
  'B': '8',
  'S': '5',
  'I': '1',
  'l': '1',
};

/// 手机状态栏时间（单独一行 HH:mm）
final kStatusBarTimePattern = RegExp(r'^\d{1,2}:\d{2}$');

/// 商户噪声过滤词
const kMerchantNoiseTexts = <String>[
  '微信支付',
  '支付宝',
  '付款成功',
  '交易成功',
  '订单详情',
  '电子发票',
  '支付成功',
  '收款成功',
  '账单详情',
  '全部账单',
  '当前状态',
  '收单机构',
  '商品',
  'CLUB',
];

/// 商户标签
const kMerchantLabelKeywords = <String>[
  '商户名称',
  '商户全称',
  '收款方',
  '商家',
  '付款对象',
  '付款给',
  '店名',
  '门店',
];

/// 金额锚定关键词（第一层，按顺序）
const kAmountPrimaryKeywords = <String>[
  '实付',
  '实收',
  '实退',
  '支付金额',
  '合计',
  '总计',
  '总价',
  '应付',
  '应收',
  'TOTAL',
  'total',
];

/// 收入类型关键词
const kIncomeTypeKeywords = <String>[
  '收款成功',
  '到账',
  '收入',
  '工资',
  '退款到账',
  '红包收入',
  '退款',
  '退货',
  '实退',
  '向你转账',
  '转账给你',
];

/// 转账类型关键词
const kTransferTypeKeywords = <String>[
  '转账给',
  '向对方转账',
  '转出',
  '转入',
];

/// 转账标签（非转账动作）
const kTransferLabelOnlyKeywords = <String>[
  '转账备注',
  '再转一笔',
  '转账说明',
];
