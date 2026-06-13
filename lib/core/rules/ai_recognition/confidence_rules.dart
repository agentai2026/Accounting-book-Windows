/// 7.2 OCR 置信度过滤阈值

/// 单字符噪音丢弃阈值（非金额行）
const kReceiptSingleCharConfidenceMin = 0.6;

/// 金额候选行低置信度标记阈值
const kReceiptAmountLineConfidenceMin = 0.7;

/// 整体识别低置信度提示阈值
const kReceiptOverallConfidenceLow = 0.65;
