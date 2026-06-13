/// 六、重复账单检测规则

/// 精确重复：查重时间窗口（天）
const kReceiptDedupExactWindowDays = 7;

/// OCR 原文相似度阈值（Jaccard）
const kReceiptDedupTextSimilarityThreshold = 0.85;
