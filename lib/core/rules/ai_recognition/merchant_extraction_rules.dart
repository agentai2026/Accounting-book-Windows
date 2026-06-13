/// 4.2 商户名提取规则配置

/// 带标签的商户字段名
const kReceiptMerchantLabelKeywords = [
  '商户名称',
  '商户名',
  '收款单位',
  '收款方',
  '店名',
  '门店',
];

/// 顶部噪声行（顺延向下查找）
const kReceiptMerchantNoisePrefixes = [
  '欢迎光临',
  '凭此小票',
  '谢谢惠顾',
  '欢迎再次',
  '服务热线',
  '客服电话',
  'NO.',
  'Tel',
  'TEL',
];

/// 分店后缀（保留品牌主体时可去除）
final kReceiptMerchantBranchSuffixPattern = RegExp(
  r'(分店|门店|旗舰店|专卖店|体验店|NO\.\d+|#\d+)$',
);

/// 商户名长度范围
const kReceiptMerchantMinLength = 2;
const kReceiptMerchantMaxLength = 32;

/// 顶部候选行数（Y 坐标最小的一批）
const kReceiptMerchantTopCandidateCount = 6;
