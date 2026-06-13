/// AI 识图 OCR 文本纠错规则（可在此扩展）
///
/// 流程：OCR 原始文本 → [本规则] → 场景分类 → 字段解析
class ReceiptOcrReplacementRule {
  const ReceiptOcrReplacementRule({
    required this.from,
    required this.to,
    this.note,
  });

  final String from;
  final String to;
  final String? note;
}

class ReceiptOcrRegexRule {
  const ReceiptOcrRegexRule({
    required this.pattern,
    required this.replace,
    this.note,
  });

  final RegExp pattern;
  final String replace;
  final String? note;
}

/// 常见 OCR 错字 → 正确词（支付截图高频）
const kReceiptOcrLiteralReplacements = [
  ReceiptOcrReplacementRule(from: '支付成攻', to: '支付成功'),
  ReceiptOcrReplacementRule(from: '支付成切', to: '支付成功'),
  ReceiptOcrReplacementRule(from: '付款成攻', to: '付款成功'),
  ReceiptOcrReplacementRule(from: '付歉成功', to: '付款成功'),
  ReceiptOcrReplacementRule(from: '收歉', to: '收款'),
  ReceiptOcrReplacementRule(from: '收歉方', to: '收款方'),
  ReceiptOcrReplacementRule(from: '收歉成功', to: '收款成功'),
  ReceiptOcrReplacementRule(from: '支件宝', to: '支付宝'),
  ReceiptOcrReplacementRule(from: '微倍', to: '微信'),
  ReceiptOcrReplacementRule(from: '微言', to: '微信'),
  ReceiptOcrReplacementRule(from: '零钱通', to: '零钱'),
  ReceiptOcrReplacementRule(from: '创健时间', to: '创建时间'),
  ReceiptOcrReplacementRule(from: '付歉时间', to: '付款时间'),
  ReceiptOcrReplacementRule(from: '支付时问', to: '支付时间'),
  ReceiptOcrReplacementRule(from: '转帐', to: '转账'),
  ReceiptOcrReplacementRule(from: '帐单', to: '账单'),
  ReceiptOcrReplacementRule(from: '余颔', to: '余额'),
  ReceiptOcrReplacementRule(from: '金颔', to: '金额'),
  ReceiptOcrReplacementRule(from: '实什', to: '实付', note: '小票错字'),
  ReceiptOcrReplacementRule(from: '实付金客', to: '实付金额'),
  ReceiptOcrReplacementRule(from: '合汁', to: '合计', note: '小票错字'),
  ReceiptOcrReplacementRule(from: '总阶', to: '总价', note: '小票错字'),
  ReceiptOcrReplacementRule(from: '应收金客', to: '应收金额'),
  ReceiptOcrReplacementRule(from: '应付金客', to: '应付金额'),
  ReceiptOcrReplacementRule(from: '实收金客', to: '实收金额'),
  ReceiptOcrReplacementRule(from: '交易金颔', to: '交易金额'),
  // OCR 把「11月2025」识成「月12025」（漏首位 1）
  ReceiptOcrReplacementRule(from: '月12025', to: '11月 2025', note: '11月年份粘连'),
  ReceiptOcrReplacementRule(from: '月22025', to: '12月 2025', note: '12月年份粘连'),
  ReceiptOcrReplacementRule(from: '月02025', to: '10月 2025', note: '10月年份粘连'),
];

/// 正则纠错（金额、符号、日期等）
final kReceiptOcrRegexReplacements = [
  ReceiptOcrRegexRule(
    pattern: RegExp(r'(?<=\d)[Oo](?=\d)'),
    replace: '0',
    note: '金额中的字母 O',
  ),
  ReceiptOcrRegexRule(
    pattern: RegExp(r'^(\d{1,6}),(\d{2})$', multiLine: true),
    replace: r'$1.$2',
    note: '两位小数逗号修正',
  ),
  ReceiptOcrRegexRule(
    pattern: RegExp(r'¥\s+(\d)'),
    replace: r'¥$1',
  ),
  ReceiptOcrRegexRule(
    pattern: RegExp(r'([+\-])\s+(\d)'),
    replace: r'$1$2',
  ),
  ReceiptOcrRegexRule(
    pattern: RegExp(r'(\d{4}-\d{1,2}-\d{1,2})(\d{1,2}:\d{2}(?::\d{2})?)'),
    replace: r'$1 $2',
    note: '日期与时间粘连',
  ),
  ReceiptOcrRegexRule(
    pattern: RegExp(
      r'(\d{4}[-/.]\d{1,2}[-/.]\d{1,2})\s+(\d{1,2})\.(\d{2})\.(\d{2})',
    ),
    replace: r'$1 $2:$3:$4',
    note: '时间中的点号改冒号',
  ),
  ReceiptOcrRegexRule(
    pattern: RegExp(r'(\d{4}年\d{1,2}月\d{1,2}日)(\d{1,2}:\d{2}(?::\d{2})?)'),
    replace: r'$1 $2',
    note: '中文日期与时间粘连',
  ),
];

/// 解析时应忽略的「非交易金额」关键词行
const kReceiptIgnoredAmountKeywords = [
  '优惠',
  '折扣',
  '红包',
  '券',
  '积分',
  '奖励',
  '手续费',
  '服务费',
  '原订单',
  '订单号',
  '交易单号',
  '商户单号',
  '支付方式',
  '付款方式',
  '信用卡',
  '借记卡',
  '储蓄卡',
  '银行卡',
  '尾号',
  '卡号',
  '积分',
  '支付奖励',
];
