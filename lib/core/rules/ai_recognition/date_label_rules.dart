/// 交易时间字段标签及匹配优先级（分数越高越优先）
typedef ReceiptDateLabelRule = (String label, int score);

const kReceiptDateLabelRules = <ReceiptDateLabelRule>[
  ('付款时间', 99),
  ('支付时间', 98),
  ('交易时间', 98),
  ('收款时间', 98),
  ('到账时间', 98),
  ('报销时间', 97),
  ('创建时间', 96),
  ('转账时间', 96),
  ('完成时间', 95),
  ('交易日期', 94),
];
