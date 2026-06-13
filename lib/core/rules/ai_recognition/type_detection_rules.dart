/// 仅为 UI 字段名，**不能**据此判定为「转账」类型
const kReceiptTransferLabelOnlyKeywords = [
  '转账备注',
  '转账说明',
  '转账时间',
  '转账金额',
  '再转一笔',
];

/// 明确转账动作文案（判定为 transfer）
const kReceiptExplicitTransferKeywords = [
  '转账给',
  '向对方转账',
  '转帐给',
];

/// 判定为「支出」的上下文关键词
const kReceiptExpenseContextKeywords = [
  '支付成功',
  '付款成功',
  '付款给',
  '实付',
  '交易成功',
];

/// 判定为「收入」的上下文关键词
const kReceiptIncomeContextKeywords = [
  '向你转账',
  '转账给你',
  '二维码收款',
  '收款成功',
  '退款',
  '退货',
  '存入',
  '转入',
  '收款',
  '收入',
];

/// 银行月账单：行首「转账-对方姓名」格式
const kReceiptBankTransferLinePrefix = '转账-';
