/// 二、图片预处理参数（OCR 前）

/// 是否启用预处理管线（手机截图建议先关，原图 OCR 更稳）
const kReceiptPreprocessEnabled = false;

/// 对比度增强（0~1，image.adjustColor）
const kReceiptPreprocessContrast = 0.15;

/// 亮度微调
const kReceiptPreprocessBrightness = 0.03;

/// 中值滤波半径（降噪，0 表示跳过）
const kReceiptPreprocessMedianRadius = 1;

/// 自适应二值化：块大小（奇数，11~21）
const kReceiptAdaptiveBlockSize = 15;

/// 自适应二值化常数 C（2~4）
const kReceiptAdaptiveConstant = 3;

/// 最大边长缩放（过大图缩小以加速 OCR）
const kReceiptMaxImageEdge = 2400;
