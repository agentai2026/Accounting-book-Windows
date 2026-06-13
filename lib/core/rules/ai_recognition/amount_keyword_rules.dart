import 'package:ezbookkeeping_desktop/core/rules/ai_recognition/ocr_correction_rules.dart';

/// 小票/发票金额锚定关键词（优先级越高越先匹配）
class ReceiptAmountKeywordRule {
  const ReceiptAmountKeywordRule({
    required this.keyword,
    required this.priority,
  });

  final String keyword;
  final int priority;
}

/// 4.1.2 金额关键词锚定（从高到低）
const kReceiptAmountKeywordRules = <ReceiptAmountKeywordRule>[
  ReceiptAmountKeywordRule(keyword: '实付', priority: 100),
  ReceiptAmountKeywordRule(keyword: '实收', priority: 98),
  ReceiptAmountKeywordRule(keyword: '实退', priority: 97),
  ReceiptAmountKeywordRule(keyword: '应付总额', priority: 96),
  ReceiptAmountKeywordRule(keyword: '应收总额', priority: 96),
  ReceiptAmountKeywordRule(keyword: '应付', priority: 94),
  ReceiptAmountKeywordRule(keyword: '应收', priority: 94),
  ReceiptAmountKeywordRule(keyword: '本次支付', priority: 92),
  ReceiptAmountKeywordRule(keyword: '线上支付', priority: 90),
  ReceiptAmountKeywordRule(keyword: '成交金额', priority: 88),
  ReceiptAmountKeywordRule(keyword: '支付', priority: 86),
  ReceiptAmountKeywordRule(keyword: '消费', priority: 84),
  ReceiptAmountKeywordRule(keyword: '合计', priority: 82),
  ReceiptAmountKeywordRule(keyword: '总价', priority: 80),
  ReceiptAmountKeywordRule(keyword: 'TOTAL', priority: 78),
  ReceiptAmountKeywordRule(keyword: 'total', priority: 78),
  ReceiptAmountKeywordRule(keyword: '小计', priority: 40),
  ReceiptAmountKeywordRule(keyword: '找零', priority: 10),
  ReceiptAmountKeywordRule(keyword: '找赎', priority: 10),
];

/// 4.1.4 无关键词兜底：排除极小/极大金额（单位：元）
const kReceiptAmountMinYuan = 0.01;
const kReceiptAmountMaxYuan = 1000000.0;

/// 4.1.4 兜底时忽略的非交易金额行关键词
const kReceiptAmountExcludeLineKeywords = [
  '单价',
  '数量',
  '找零',
  '找赎',
  ...kReceiptIgnoredAmountKeywords,
];
